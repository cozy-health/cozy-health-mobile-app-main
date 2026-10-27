import 'dart:convert';
import 'dart:typed_data';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/repositories/journal_repository.dart';
import 'package:cozy_health/core/services/feature_flags_service.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/plan_access_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/repository_fixture.dart';
import '../support/mobile_sync_contract.dart';

class PlanAdapter implements HttpClientAdapter {
  bool enabled = true, offline = false, denied = false;
  List<String> features = ['written_journal', 'mood_checkin', 'community_read'];
  String? expiry = DateTime.now()
      .add(const Duration(days: 1))
      .toUtc()
      .toIso8601String();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (options.path == '/config') {
      return ResponseBody.fromString(
        jsonEncode({
          'flags': {'plan_access': enabled},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(
        denied
            ? {
                'code': 'plan_required',
                'message': 'Student or Premium is needed.',
              }
            : {
                'data': {
                  'enforcement_enabled': true,
                  'plan': 'standard',
                  'features': features,
                  'expires_at': expiry,
                },
              },
      ),
      denied ? 403 : 200,
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
  final fixture = RepositoryFixture<JournalEntry>(
    LocalDbService.journalBoxName,
    JournalEntryAdapter(),
  );
  late PlanAdapter adapter;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await fixture.open();
    registerSyncAdapters();
  });
  setUp(() async {
    await local.waitForSyncIdle();
    await local.activateAccount('plan-owner');
    await local.clearAllUserData();
    local.syncPaused = true;
    await TokenStorage().saveToken('fixture-only');
    adapter = PlanAdapter();
    ApiClient().transportForTesting = adapter;
    await FeatureFlagsService.instance.refresh();
  });
  tearDownAll(() async {
    adapter.enabled = false;
    adapter.offline = false;
    adapter.denied = false;
    await FeatureFlagsService.instance.refresh();
    await local.waitForSyncIdle();
    await fixture.close();
  });
  test(
    'Standard allows written journals and denies voice before local persistence',
    () async {
      await PlanAccessService.instance.require('written_journal');
      await expectLater(
        PlanAccessService.instance.require('voice'),
        throwsA(isA<PlanAccessException>()),
      );
      final voice = JournalEntry(
        id: 'voice-fixture',
        type: 'voice',
        body: '',
        tags: [],
        wordCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await expectLater(
        JournalRepository(usePlaceholderData: false).save(voice),
        throwsA(isA<PlanAccessException>()),
      );
      expect(local.getAllJournalEntries(), isEmpty);
      expect(local.pendingItems, isEmpty);
    },
  );
  test(
    'Student/Premium permissions allow voice but expiry still denies it',
    () async {
      adapter.features = ['voice', 'assessments', 'provider_chat'];
      await PlanAccessService.instance.require('voice');
      adapter.expiry = '2000-01-01T00:00:00Z';
      await expectLater(
        PlanAccessService.instance.require('voice'),
        throwsA(isA<PlanAccessException>()),
      );
    },
  );
  test(
    'offline permission cache expires and never follows another account',
    () async {
      await PlanAccessService.instance.require('mood_checkin');
      adapter.offline = true;
      await PlanAccessService.instance.require('mood_checkin');
      final settings = await local.settingsBox();
      final saved = Map<String, dynamic>.from(
        settings.get('plan_access_v1') as Map,
      );
      saved['checked_at'] = DateTime.now()
          .subtract(const Duration(minutes: 6))
          .toUtc()
          .toIso8601String();
      await settings.put('plan_access_v1', saved);
      await PlanAccessService.instance.require('mood_checkin');
      saved['data'] = {
        ...Map<String, dynamic>.from(saved['data'] as Map),
        'expires_at': '2000-01-01T00:00:00Z',
      };
      await settings.put('plan_access_v1', saved);
      await expectLater(
        PlanAccessService.instance.require('mood_checkin'),
        throwsA(isA<PlanAccessException>()),
      );
      await local.activateAccount('another-plan-owner');
      await expectLater(
        PlanAccessService.instance.require('mood_checkin'),
        throwsA(isA<PlanAccessException>()),
      );
      expect((await local.settingsBox()).get('plan_access_v1'), isNull);
    },
  );
  test('plan denial is not treated as an expired sign-in session', () async {
    adapter.denied = true;
    await expectLater(
      ApiClient().get('/plan-fixture'),
      throwsA(
        isA<ApiValidationException>().having(
          (error) => error.message,
          'explanation',
          contains('Premium'),
        ),
      ),
    );
    expect(await TokenStorage().getToken(), 'fixture-only');
  });
}
