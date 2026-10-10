import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/safety_plan.dart';
import 'package:cozy_health/core/services/user_data_merge.dart';
import 'package:cozy_health/features/crisis/data/safety_plan_repository.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/auth/data/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/mobile_sync_contract.dart';
import '../support/repository_fixture.dart';

class LifecycleAdapter implements HttpClientAdapter {
  bool expire = false;
  final uploads = <Map>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    dynamic body;
    var status = 200;
    if (options.path == '/sync/batch') {
      uploads.add(options.data as Map);
      status = expire ? 401 : 200;
      body = {
        'data': {
          'results': [
            for (final op in options.data['operations'] as List)
              {
                'client_operation_id': op['client_operation_id'],
                'success': true,
              },
          ],
        },
      };
    } else if (options.path == '/auth/login') {
      body = {
        'data': {
          'token': 'synthetic-token',
          'user': {
            'id': 42,
            'name': 'Synthetic user',
            'email': 'synthetic@example.test',
          },
        },
      };
    } else if (options.path == '/auth/me' || options.path == '/user/profile') {
      body = {
        'data': {
          'id': 'server-profile',
          'user_id': 42,
          'name': 'Synthetic user',
          'email': 'synthetic@example.test',
          'text_size': '1.00',
        },
      };
    } else {
      body = {
        'data': {'data': [], 'last_page': 1},
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
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
  late LifecycleAdapter adapter;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await fixture.open();
    registerSyncAdapters();
  });
  setUp(() async {
    await local.waitForSyncIdle();
    await local.activateAccount('42', email: 'synthetic@example.test');
    await local.clearAllUserData();
    local.syncPaused = false;
    await TokenStorage().saveToken('synthetic-token');
    await TokenStorage().saveRefreshToken(null);
    adapter = LifecycleAdapter();
    ApiClient().transportForTesting = adapter;
  });
  tearDownAll(() async {
    await local.waitForSyncIdle();
    await fixture.close();
  });
  Future<void> waitUntil(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Lifecycle transition did not complete');
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<void> queue() async {
    final data = mobileSyncOperations().first['data'] as Map<String, dynamic>;
    await local.saveMoodEntry(MoodEntry.fromJson(data));
    await local.enqueueSync(
      type: 'mood_entry',
      action: 'upsert',
      recordId: data['id'] as String,
      payload: data,
    );
  }

  test(
    'expired upload exits without deadlock and relogin uploads the preserved account draft',
    () async {
      await queue();
      final accountQueue = local.syncQueueBox;
      final accountScope = local.boxName(LocalDbService.syncQueueBoxName);
      adapter.expire = true;
      final summary = await local.processSyncQueue().timeout(
        const Duration(seconds: 3),
      );
      expect(summary.errorCode, 'session_expired');
      await waitUntil(
        () => local.boxName(LocalDbService.syncQueueBoxName) != accountScope,
      );
      expect(accountQueue.length, 1);
      expect(local.pendingItems, isEmpty);
      adapter.expire = false;
      await AuthService().login(
        email: 'synthetic@example.test',
        password: 'synthetic-password',
      );
      await waitUntil(() => accountQueue.isEmpty);
      expect(local.boxName(LocalDbService.syncQueueBoxName), accountScope);
      expect(local.getAllMoodEntries().length, 1);
      final moodUploads = adapter.uploads
          .expand((body) => body['operations'] as List)
          .where((op) => op['type'] == 'mood_entry')
          .toList();
      expect(
        moodUploads.length,
        2,
      ); // Expired attempt, then authenticated retry.
    },
  );

  test(
    'resuming a stored account immediately retries a backed-off draft',
    () async {
      await queue();
      final item = local.pendingItems.single;
      await local.syncQueueBox.put(
        item.id,
        item
            .copyWith(
              retryCount: 4,
              nextRetryAt: DateTime.now().add(const Duration(hours: 1)),
            )
            .toJson(),
      );
      await AuthService().resumeStoredSession();
      await waitUntil(() => local.pendingItems.isEmpty);
      expect(adapter.uploads.length, 1);
      expect(local.getAllMoodEntries().length, 1);
    },
  );

  test(
    'a canonical safety plan replaces its local alias in the cache',
    () async {
      await local.saveSafetyPlan(
        SafetyPlan(
          id: 'local-plan',
          isComplete: false,
          lastUpdatedAt: DateTime.utc(2026, 10, 9),
        ),
      );
      await UserDataMerge().apply('safety_plan', {
        'id': 'server-plan',
        'user_id': 42,
        'is_complete': true,
        'last_updated_at': '2026-10-10T12:00:00Z',
      });
      expect(local.safetyPlanBox.length, 1);
      expect(local.getSafetyPlan()!.id, 'server-plan');
      expect(local.getSafetyPlan()!.isComplete, isTrue);
    },
  );

  test(
    'resetting a safety plan queues its removal instead of clearing only the device',
    () async {
      await local.saveSafetyPlan(
        SafetyPlan(
          id: 'local-plan',
          isComplete: false,
          lastUpdatedAt: DateTime.utc(2026, 10, 9),
        ),
      );
      local.syncPaused = true;
      await SafetyPlanRepository().clearSafetyPlan();
      expect(local.getSafetyPlan(), isNull);
      expect(local.pendingItems.single.type, 'safety_plan');
      expect(local.pendingItems.single.action, 'delete');
      local.syncPaused = false;
      await local.processSyncQueue();
      expect(local.pendingItems, isEmpty);
    },
  );
}
