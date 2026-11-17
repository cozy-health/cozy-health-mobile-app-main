import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/network_status.dart';
import 'package:cozy_health/features/settings/data/achievements_repository.dart';

class AwardApi extends Fake implements ApiClient {
  bool fail = false;
  int reads = 0;
  Completer<void>? gate;
  final started = Completer<void>();
  List<Map<String, dynamic>> rows = [];
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? query,
    bool withAuth = true,
    Options? options,
  }) async {
    expect(path, '/wellness/achievements');
    reads++;
    if (!started.isCompleted) started.complete();
    await gate?.future;
    if (fail) throw StateError('Offline');
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {'data': rows},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  late Directory cache;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    cache = await Directory.systemTemp.createTemp('cozy_achievement_test_');
    Hive.init(cache.path);
    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
  });
  setUp(() async {
    DemoMode.instance.enabled = false;
    networkOffline.value = false;
    await local.activateAccount('award-owner');
    await local.moodBox.clear();
    await local.journalBox.clear();
    await (await local.settingsBox()).clear();
  });
  tearDownAll(() async {
    networkOffline.value = null;
    DemoMode.instance.enabled = false;
    await Hive.close();
    Hive.resetAdapters();
    await cache.delete(recursive: true);
  });
  test(
    'Earned local awards survive deleting source records and reconnecting',
    () async {
      final d = DateTime.now().toUtc().subtract(const Duration(days: 1));
      await local.moodBox.put(
        'one',
        MoodEntry(
          id: 'one',
          mood: 'sad',
          intensity: 2,
          createdAt: d,
          updatedAt: d,
        ),
      );
      final api = AwardApi()..fail = true,
          repo = AchievementsRepository(api: AwardApi()..fail = true);
      final first = await repo.load();
      expect(first.awards.containsKey('first_mood'), true);
      expect(first.remoteUnavailable, true);
      await local.moodBox.clear();
      final next = await AchievementsRepository(api: api).load();
      expect(next.progress.entryCount, 0);
      expect(next.awards['first_mood'], first.awards['first_mood']);
      api.fail = false;
      expect(
        (await AchievementsRepository(api: api).load()).awards['first_mood'],
        first.awards['first_mood'],
      );
    },
  );
  test(
    'Server earned dates take precedence and legacy instants use the account calendar',
    () async {
      final box = await local.settingsBox();
      await box.put('account_timezone', 'Africa/Lagos');
      await box.put('earned_milestones_v1', {
        'first_journal': '2026-10-20T23:30:00Z',
        'streak_3': '2026-10-19',
      });
      final api = AwardApi()
        ..rows = [
          {'milestone': 'streak_3', 'earned_date': '2026-10-18'},
        ];
      final result = await AchievementsRepository(api: api).load();
      expect(result.awards['first_journal'], DateTime.utc(2026, 10, 21));
      expect(result.awards['streak_3'], DateTime.utc(2026, 10, 18));
    },
  );
  test(
    'Pending response from an old account cannot expose or persist awards to the new account',
    () async {
      final api = AwardApi()
        ..gate = Completer<void>()
        ..rows = [
          {'milestone': 'streak_30', 'earned_date': '2026-10-20'},
        ];
      final pending = AchievementsRepository(api: api).load();
      final rejected = expectLater(pending, throwsStateError);
      await api.started.future;
      await local.activateAccount('award-other-owner');
      api.gate!.complete();
      await rejected;
      expect((await local.settingsBox()).get('earned_milestones_v1'), isNull);
    },
  );
  test('Guest progress never calls the account achievement endpoint', () async {
    await local.activateAccount('guest_award-test');
    final api = AwardApi();
    final result = await AchievementsRepository(api: api).load();
    expect(result.localOnly, true);
    expect(api.reads, 0);
  });
}
