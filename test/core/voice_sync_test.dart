import 'package:flutter/material.dart';
import 'package:cozy_health/core/audio/voice_player.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/audio/voice_audio.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/user_data_merge.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/mobile_sync_contract.dart';
import '../support/repository_fixture.dart';

class VoiceSyncAdapter implements HttpClientAdapter {
  int uploads = 0;
  bool failMetadata = true;
  final batches = <Map<String, dynamic>>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/audio-attachments') {
      uploads++;
      final form = options.data as FormData;
      expect(form.fields.toMap()['purpose'], 'journal');
      expect(form.files.single.value.filename, 'voice.m4a');
      return ResponseBody.fromString(
        jsonEncode({'id': '11111111-2222-4333-8444-555555555555'}),
        201,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    final body = Map<String, dynamic>.from(options.data as Map);
    batches.add(body);
    final success = !failMetadata;
    failMetadata = false;
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'results': [
            for (final op in body['operations'] as List)
              {
                'client_operation_id': op['client_operation_id'],
                'success': success,
              },
          ],
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

extension on List<MapEntry<String, String>> {
  Map<String, String> toMap() => Map.fromEntries(this);
}

class _PlaybackAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromBytes([1, 2, 3], 200);
  @override
  void close({bool force = false}) {}
}

class _DeniedPlaybackAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{}',
    404,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  final fixture = RepositoryFixture<JournalEntry>(
    LocalDbService.journalBoxName,
    JournalEntryAdapter(),
  );
  late Directory folder;
  late VoiceSyncAdapter adapter;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await fixture.open();
    registerSyncAdapters();
    folder = await Directory.systemTemp.createTemp('voice-sync-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => folder.path,
        );
  });
  setUp(() async {
    await local.activateAccount('voice-owner');
    await local.clearAllUserData();
    local.syncPaused = false;
    await TokenStorage().saveToken('synthetic-voice-token');
    adapter = VoiceSyncAdapter();
    ApiClient().transportForTesting = adapter;
  });
  tearDownAll(() async {
    await local.waitForSyncIdle();
    await fixture.close();
    await folder.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });

  testWidgets('logout removes voice playback controls from an open player', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: VoicePlayer(source: 'unused.m4a', duration: 3)),
      ),
    );
    expect(find.byTooltip('Play voice recording'), findsOneWidget);
    await tester.runAsync(() => TokenStorage().clearToken());
    await tester.pump();
    expect(find.byTooltip('Play voice recording'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test('recordings cannot be played or uploaded by another account', () async {
    final source = await File(
      '${folder.path}/private-source.m4a',
    ).writeAsBytes([4, 5, 6]);
    final saved = await VoiceAudio.save(
      RecordedAudio(source.path, 3),
      'private',
    );
    await local.activateAccount('other-voice-owner');
    await expectLater(
      VoiceAudio.playable(saved, journal: true),
      throwsStateError,
    );
    await expectLater(
      VoiceAudio.upload(audio: RecordedAudio(saved, 3), clientId: 'private'),
      throwsStateError,
    );
    expect(adapter.uploads, 0);
    await local.activateAccount('voice-owner');
    expect(await VoiceAudio.playable(saved, journal: true), saved);
  });

  test(
    'recorder preview is scoped to its file and ends when invalidated',
    () async {
      final file = await File(
        '${folder.path}/preview.m4a',
      ).writeAsBytes([1, 2]);
      final preview = VoicePreview.create(file.path);
      expect(await VoiceAudio.playable(file.path, preview: preview), file.path);
      final other = await File(
        '${folder.path}/different-preview.m4a',
      ).writeAsBytes([3]);
      await expectLater(
        VoiceAudio.playable(other.path, preview: preview),
        throwsStateError,
      );
      await expectLater(VoiceAudio.playable(file.path), throwsStateError);
      preview.invalidate();
      await expectLater(
        VoiceAudio.playable(file.path, preview: preview),
        throwsStateError,
      );
    },
  );

  test('preview authorization ends on session replacement', () async {
    final file = await File(
      '${folder.path}/session-preview.m4a',
    ).writeAsBytes([1]);
    final preview = VoicePreview.create(file.path);
    await TokenStorage().saveToken('replacement-session');
    await expectLater(
      VoiceAudio.playable(file.path, preview: preview),
      throwsStateError,
    );
  });

  test(
    'shared audio rechecks authorization and avoids durable journal cache',
    () async {
      final dio = ApiClient();
      dio.transportForTesting = _PlaybackAdapter();
      const source =
          '/provider-conversations/7/journal-shares/11111111-2222-4333-8444-555555555555/audio';
      final first = await VoiceAudio.playable(
        source,
        onlineOnly: true,
        api: dio,
      );
      expect(await File(first).readAsBytes(), [1, 2, 3]);
      expect(first.contains('/voice/'), isFalse);
      dio.transportForTesting = _DeniedPlaybackAdapter();
      await expectLater(
        VoiceAudio.playable(source, onlineOnly: true, api: dio),
        throwsA(isA<Exception>()),
      );
      await File(first).delete();
    },
  );

  test(
    'missing local journal audio falls back to authenticated remote audio',
    () async {
      final saved = await VoiceAudio.save(
        RecordedAudio(
          await File(
            '${folder.path}/fallback.m4a',
          ).writeAsBytes([1]).then((f) => f.path),
          3,
        ),
        'fallback',
      );
      await File(saved).delete();
      final dio = ApiClient();
      dio.transportForTesting = _PlaybackAdapter();
      final result = await VoiceAudio.playable(
        '/audio-attachments/11111111-2222-4333-8444-555555555555',
        localPath: saved,
        journal: true,
        api: dio,
      );
      expect(await File(result).readAsBytes(), [1, 2, 3]);
    },
  );

  test(
    'durable journal audio uploads before metadata and retries reuse attachment without device paths',
    () async {
      const id = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
      final source = await File(
        '${folder.path}/temporary.m4a',
      ).writeAsBytes([1, 2, 3]);
      final path = await VoiceAudio.save(RecordedAudio(source.path, 3), id);
      await source.delete();
      expect(await File(path).exists(), isTrue);
      final now = DateTime.now().toUtc();
      final entry = JournalEntry(
        id: id,
        type: 'voice',
        body: '',
        wordCount: 0,
        voiceUrl: path,
        localVoicePath: path,
        voiceDuration: 3,
        createdAt: now,
        updatedAt: now,
      );
      await local.saveJournalEntry(entry);
      await local.enqueueSync(
        type: 'journal_entry',
        action: 'upsert',
        recordId: id,
        payload: entry.toJson(),
      );
      await local.processSyncQueue();
      expect(adapter.uploads, 1);
      expect(local.pendingItems, hasLength(1));
      await local.processSyncQueue(force: true);
      expect(adapter.uploads, 1);
      expect(local.pendingItems, isEmpty);
      for (final batch in adapter.batches) {
        final data =
            ((batch['operations'] as List).single as Map)['data'] as Map;
        expect(
          data['voice_url'],
          '/audio-attachments/11111111-2222-4333-8444-555555555555',
        );
        expect(data.containsKey('local_voice_path'), isFalse);
        expect(jsonEncode(data).contains(folder.path), isFalse);
      }
      await UserDataMerge().apply('journal_entry', {
        ...(entry.toJson()..remove('local_voice_path')),
        'voice_url': '/audio-attachments/11111111-2222-4333-8444-555555555555',
      });
      expect(local.journalBox.get(id)?.localVoicePath, path);
      await local.deleteJournalEntry(id);
      expect(await File(path).exists(), isFalse);
    },
  );
}
