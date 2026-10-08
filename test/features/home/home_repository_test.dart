import 'package:cozy_health/core/repositories/home_repository.dart';
import 'package:cozy_health/core/repositories/endpoint_cache.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/endpoint_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = EndpointFixture();
  late DateTime now;
  late HomeRepository repository;
  setUpAll(fixture.open);
  setUp(() async {
    await fixture.reset();
    now = DateTime.utc(2026, 10, 8, 12);
    repository = HomeRepository(cache: EndpointCache(now: () => now));
    fixture.body = {
      'success': true,
      'data': {
        'today_mood': {'id': 'today', 'mood': 'calm', 'intensity': 4},
        'streak_days': 100,
        'weekly_moods': [
          {'day': '2026-10-08', 'count': 3, 'avg_intensity': 4.5},
        ],
        'recent_entries': [
          {'id': 'today', 'mood': 'calm'},
        ],
        'timezone': 'Africa/Lagos',
      },
    };
  });
  tearDownAll(fixture.close);

  test(
    'dashboard parses all API metrics and caches without another request',
    () async {
      final data = await repository.fetchDashboard();
      expect(data.streakDays, 100);
      expect(data.todayMood?['mood'], 'calm');
      expect(data.weeklyMoods.single['avg_intensity'], 4.5);
      expect(data.recentEntries.single['id'], 'today');
      expect(data.timezone, 'Africa/Lagos');
      expect((await repository.getCachedDashboard())?.streakDays, 100);
      expect(fixture.requests.single.path, '/api/v1/dashboard');
    },
  );

  test('dashboard expires at five minutes but retains offline data', () async {
    await repository.fetchDashboard();
    now = now.add(const Duration(minutes: 4, seconds: 59));
    expect(await repository.getCachedDashboard(), isNotNull);
    now = now.add(const Duration(seconds: 1));
    expect(await repository.getCachedDashboard(), isNull);
    expect(await repository.getCachedDashboard(allowStale: true), isNotNull);
  });

  test('dashboard cache is isolated across sign-ins and logout', () async {
    await repository.fetchDashboard();
    await TokenStorage().saveToken('2|another-user');
    expect(await repository.getCachedDashboard(allowStale: true), isNull);
    await TokenStorage().clearToken();
    expect(await repository.getCachedDashboard(), isNull);
  });

  test('empty dashboard preserves null mood and empty arrays', () async {
    fixture.body = {
      'data': {
        'today_mood': null,
        'streak_days': 0,
        'weekly_moods': [],
        'recent_entries': [],
        'timezone': 'UTC',
      },
    };
    final data = await repository.fetchDashboard();
    expect(data.todayMood, isNull);
    expect(data.weeklyMoods, isEmpty);
    expect(data.recentEntries, isEmpty);
  });
}
