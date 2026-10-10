import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/sync_item.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/repository_fixture.dart';
import '../support/mobile_sync_contract.dart';

class ProbeAdapter implements HttpClientAdapter {
  final requests = <Map<String, dynamic>>[];
  Completer<void>? hold;
  String? reject;
  int status = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    final body = Map<String, dynamic>.from(options.data as Map);
    requests.add(body);
    final gate = hold;
    if (gate != null) await gate.future;
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'results': [
            for (final op in body['operations'] as List)
              {
                'client_operation_id': op['client_operation_id'],
                'success': op['data']?['note'] != reject || reject == null,
              },
          ],
        },
      }),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  final fixture = RepositoryFixture<MoodEntry>(
    LocalDbService.moodBoxName,
    MoodEntryAdapter(),
  );
  late ProbeAdapter adapter;
  setUpAll(() async {
    await fixture.open();
    await EncryptedHive.openBox<String>(LocalDbService.syncQueueBoxName);
  });
  setUp(() async {
    await local.syncQueueBox.clear();
    local.syncPaused = false;
    adapter = ProbeAdapter();
    ApiClient().transportForTesting = adapter;
  });
  tearDownAll(fixture.close);
  Future<void> queue(String id, String note) => local.enqueueSync(
    type: 'mood_entry',
    action: 'upsert',
    recordId: id,
    payload: {'id': id, 'mood': 'good', 'intensity': 5, 'note': note},
  );

  test(
    'saving during an upload drains the second save without another trigger',
    () async {
      adapter.hold = Completer<void>();
      await queue('first', 'first');
      final first = local.processSyncQueue();
      while (adapter.requests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      await queue('second', 'second');
      final second = local.processSyncQueue();
      adapter.hold!.complete();
      await Future.wait([first, second]);
      expect(adapter.requests.length, 2);
      expect(local.pendingItems, isEmpty);
    },
  );

  test(
    'all 11 mobile serializers reach the batch route and drain acknowledged work',
    () async {
      final operations = mobileSyncOperations();
      for (final operation in operations) {
        final data = operation['data'] as Map<String, dynamic>;
        await local.enqueueSync(
          type: operation['type'] as String,
          action: 'upsert',
          recordId: data['id'] as String,
          payload: data,
        );
      }
      final summary = await local.processSyncQueue();
      expect(summary.synced, 11);
      expect(summary.failed, 0);
      expect(local.pendingItems, isEmpty);
      final export = Platform.environment['SYNC_FIXTURE_OUTPUT'];
      if (export != null) {
        await File(
          export,
        ).writeAsString(const JsonEncoder.withIndent('  ').convert(operations));
      }
    },
  );

  test(
    '401 completes without waiting for its own upload and preserves the draft',
    () async {
      // The production interceptor has no custom session-expired callback here.
      adapter.status = 401;
      await queue('expired-session', 'draft');
      final summary = await local.processSyncQueue().timeout(
        const Duration(seconds: 3),
      );
      expect(summary.failed, 1);
      expect(summary.errorCode, 'session_expired');
      expect(local.pendingItems.single.lastErrorCode, 'session_expired');
      // Supply a new session before deferred account switching can run; fixtures
      // are deliberately unscoped, while account isolation is covered separately.
      await local.waitForSyncIdle();
    },
  );

  test('diagnosis: unpausing does not start a queued upload', () async {
    local.syncPaused = true;
    await queue('paused', 'paused');
    await local.processSyncQueue();
    local.syncPaused = false;
    await Future<void>.delayed(Duration.zero);
    expect(adapter.requests, isEmpty);
    expect(local.pendingItems.single.recordId, 'paused');
  });

  test('a newer successful edit removes an older backed-off edit', () async {
    adapter.reject = 'old';
    await queue('same-record', 'old');
    await local.processSyncQueue();
    await local.processSyncQueue();
    await queue('same-record', 'new');
    await local.processSyncQueue();
    expect(adapter.requests.last['operations'].single['data']['note'], 'new');
    expect(local.pendingItems, isEmpty);
    adapter.reject = null;
    await local.processSyncQueue(force: true);
    expect(adapter.requests.last['operations'].single['data']['note'], 'new');
  });

  test(
    'legacy id-only queue entries upload their complete cached record',
    () async {
      final data = mobileSyncOperations().first['data'] as Map<String, dynamic>;
      await local.saveMoodEntry(MoodEntry.fromJson(data));
      await local.syncQueueBox.put('mood_entry:${data['id']}', 'legacy');
      final result = await local.processSyncQueue();
      expect(result.synced, 1);
      expect(
        adapter.requests.single['operations'].single['data']['mood'],
        'calm',
      );
      expect(local.pendingItems, isEmpty);
    },
  );

  test(
    'old persisted duplicate edits are compacted by time rather than Hive key order',
    () async {
      for (final entry in [('z-old', 'old', 1), ('a-new', 'new', 2)]) {
        final item = SyncItem(
          id: entry.$1,
          type: 'mood_entry',
          action: 'upsert',
          recordId: 'same',
          retryCount: 0,
          createdAt: DateTime.utc(2026, 10, entry.$3),
          payload: {'id': 'same', 'note': entry.$2},
        );
        await local.syncQueueBox.put(item.id, item.toJson());
      }
      await local.processSyncQueue();
      expect(adapter.requests.single['operations'].length, 1);
      expect(
        adapter.requests.single['operations'].single['data']['note'],
        'new',
      );
    },
  );

  test(
    'failed in-flight predecessor cannot reappear after a new edit replaces it',
    () async {
      adapter.hold = Completer<void>();
      adapter.reject = 'old';
      await queue('same', 'old');
      final upload = local.processSyncQueue();
      while (adapter.requests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      await queue('same', 'new');
      adapter.hold!.complete();
      final result = await upload;
      expect(result.failed, 0);
      expect(local.pendingItems, isEmpty);
      expect(adapter.requests.last['operations'].single['data']['note'], 'new');
    },
  );

  test('server decimal strings restore a usable profile', () {
    final profile = UserProfile.fromJson({
      'id': 'profile',
      'text_size': '1.25',
    });
    expect(profile.textSize, 1.25);
  });
}
