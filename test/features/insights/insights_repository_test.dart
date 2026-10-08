import 'package:cozy_health/core/repositories/insights_repository.dart';
import 'package:cozy_health/core/repositories/endpoint_cache.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/endpoint_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = EndpointFixture();
  late DateTime now;
  late InsightsRepository repository;
  setUpAll(fixture.open);
  setUp(() async {
    await fixture.reset();
    now = DateTime.utc(2026, 10, 8, 12);
    repository = InsightsRepository(cache: EndpointCache(now: () => now));
  });
  tearDownAll(fixture.close);

  test('weekly parses summaries and sends the requested weeks', () async {
    fixture.body = {
      'data': {
        'weeks': [
          {
            'week_start': '2026-10-05',
            'avg_intensity': 6.4,
            'entry_count': 15,
            'top_mood': 'good',
            'mood_breakdown': {'good': 15},
          },
        ],
      },
    };
    final rows = await repository.fetchWeekly(weeks: 4);
    expect(rows.single['entry_count'], 15);
    expect(rows.single['mood_breakdown'], {'good': 15});
    expect(fixture.requests.single.path, '/api/v1/insights/weekly');
    expect(fixture.requests.single.queryParameters, {'weeks': '4'});
    expect(await repository.getCachedWeekly(weeks: 4), rows);
    expect(await repository.getCachedWeekly(), isNull);
  });

  test('triggers parses names counts and averages', () async {
    fixture.body = {
      'data': {
        'range_days': 30,
        'triggers': [
          {'name': 'Work', 'count': 12, 'avg_intensity': 6.8},
        ],
      },
    };
    final rows = await repository.fetchTriggers();
    expect(rows.single, {'name': 'Work', 'count': 12, 'avg_intensity': 6.8});
    expect(fixture.requests.single.path, '/api/v1/insights/triggers');
    expect(fixture.requests.single.queryParameters, {'days': '30'});
    expect(await repository.getCachedTriggers(), rows);
  });

  test('sleep mood parses quality buckets', () async {
    fixture.body = {
      'data': {
        'range_days': 7,
        'points': [
          {'sleep_quality': 5, 'count': 4, 'avg_intensity': 4.1},
        ],
      },
    };
    final rows = await repository.fetchSleepMood(days: 7);
    expect(rows.single['sleep_quality'], 5);
    expect(rows.single['avg_intensity'], 4.1);
    expect(fixture.requests.single.path, '/api/v1/insights/sleep-mood');
    expect(fixture.requests.single.queryParameters, {'days': '7'});
    expect(await repository.getCachedSleepMood(days: 7), rows);
  });

  test('each endpoint caches valid empty results', () async {
    fixture.body = {
      'data': {'weeks': [], 'triggers': [], 'points': []},
    };
    expect(await repository.fetchWeekly(), isEmpty);
    expect(await repository.fetchTriggers(), isEmpty);
    expect(await repository.fetchSleepMood(), isEmpty);
    expect(await repository.getCachedWeekly(), isEmpty);
    expect(await repository.getCachedTriggers(), isEmpty);
    expect(await repository.getCachedSleepMood(), isEmpty);
  });

  test('range caches are separate and expire at five minutes', () async {
    fixture.body = {
      'data': {
        'triggers': [
          {'name': 'Sleep', 'count': 1, 'avg_intensity': 2},
        ],
      },
    };
    await repository.fetchTriggers(days: 7);
    expect(await repository.getCachedTriggers(days: 30), isNull);
    now = now.add(const Duration(minutes: 5));
    expect(await repository.getCachedTriggers(days: 7), isNull);
    expect(
      await repository.getCachedTriggers(days: 7, allowStale: true),
      isNotNull,
    );
  });

  test('failed refresh preserves the previous cache', () async {
    fixture.body = {
      'data': {
        'triggers': [
          {'name': 'Work', 'count': 2, 'avg_intensity': 5},
        ],
      },
    };
    final original = await repository.fetchTriggers();
    fixture.body = {'data': null};
    await expectLater(repository.fetchTriggers(), throwsA(isA<TypeError>()));
    expect(await repository.getCachedTriggers(), original);
  });

  test('insights do not reuse another session cache', () async {
    fixture.body = {
      'data': {'weeks': [], 'triggers': [], 'points': []},
    };
    await repository.fetchWeekly();
    await repository.fetchTriggers();
    await repository.fetchSleepMood();
    await TokenStorage().saveToken('2|other');
    expect(await repository.getCachedWeekly(allowStale: true), isNull);
    expect(await repository.getCachedTriggers(allowStale: true), isNull);
    expect(await repository.getCachedSleepMood(allowStale: true), isNull);
  });
}
