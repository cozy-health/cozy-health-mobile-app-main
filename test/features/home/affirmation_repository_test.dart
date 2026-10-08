import 'package:cozy_health/core/repositories/affirmation_repository.dart';
import 'package:cozy_health/core/repositories/endpoint_cache.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/endpoint_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = EndpointFixture();
  late DateTime now;
  late EndpointCache cache;
  late AffirmationRepository repository;
  setUpAll(fixture.open);
  setUp(() async {
    await fixture.reset();
    now = DateTime.utc(2026, 10, 8, 12);
    cache = EndpointCache(now: () => now);
    await cache.write('home_dashboard', {
      'timezone': 'UTC',
    }, await cache.owner());
    repository = AffirmationRepository(cache: cache, now: () => now);
    fixture.body = {
      'success': true,
      'data': {
        'body': 'Rest is not something you have to earn.',
        'date': '2026-10-08',
      },
    };
  });
  tearDownAll(fixture.close);

  test('today parses API body and stores cache by server date', () async {
    expect(await repository.getCachedToday(), isNull);
    expect(
      await repository.fetchToday(),
      'Rest is not something you have to earn.',
    );
    expect(fixture.requests.single.path, '/api/v1/affirmations/today');
    expect(fixture.box.keys, contains('1:affirmation_2026-10-08'));
    expect(
      await repository.getCachedToday(),
      'Rest is not something you have to earn.',
    );
  });

  test('same-day cache survives cold starts and five-minute TTL', () async {
    final body = await repository.fetchToday();
    now = now.add(const Duration(hours: 6));
    final coldStart = AffirmationRepository(cache: cache, now: () => now);
    expect(await coldStart.fetchToday(), body);
    expect(fixture.requests, hasLength(1));
  });

  test(
    'next day invalidates previous copy and fetches a new affirmation',
    () async {
      await repository.fetchToday();
      now = DateTime.utc(2026, 10, 9);
      expect(await repository.getCachedToday(), isNull);
      fixture.body = {
        'data': {'body': 'One small step still counts.', 'date': '2026-10-09'},
      };
      expect(await repository.fetchToday(), 'One small step still counts.');
      expect(fixture.requests, hasLength(2));
      expect(fixture.box.keys, contains('1:affirmation_2026-10-08'));
    },
  );

  test(
    'cache follows account timezone midnight rather than UTC midnight',
    () async {
      await cache.write('home_dashboard', {
        'timezone': 'Pacific/Auckland',
      }, await cache.owner());
      now = DateTime.utc(2026, 10, 8, 10, 59, 59);
      await repository.fetchToday();
      expect(await repository.untilNextDay(), const Duration(seconds: 1));
      now = DateTime.utc(2026, 10, 8, 11);
      expect(await repository.getCachedToday(), isNull);
      fixture.body = {
        'data': {'body': 'You can pause.', 'date': '2026-10-09'},
      };
      expect(await repository.fetchToday(), 'You can pause.');
    },
  );

  test('DST fall-back day schedules the real 25-hour midnight', () async {
    await cache.write('home_dashboard', {
      'timezone': 'America/New_York',
    }, await cache.owner());
    now = DateTime.utc(2026, 11, 1, 4);
    expect(await repository.untilNextDay(), const Duration(hours: 25));
    fixture.body = {
      'data': {'body': 'Be patient with yourself.', 'date': '2026-11-01'},
    };
    await repository.fetchToday();
    now = DateTime.utc(2026, 11, 1, 5, 30);
    expect(await repository.getCachedToday(), 'Be patient with yourself.');
    now = DateTime.utc(2026, 11, 1, 6, 30);
    expect(await repository.fetchToday(), 'Be patient with yourself.');
    expect(fixture.requests, hasLength(1));
  });

  test(
    'no affirmations is a valid result cached for the rest of the day',
    () async {
      fixture.body = {'success': true, 'data': null};
      expect(await repository.fetchToday(), isNull);
      expect(await repository.fetchToday(), isNull);
      expect(fixture.requests, hasLength(1));
    },
  );

  test('daily cache cannot leak between signed-in sessions', () async {
    await repository.fetchToday();
    await TokenStorage().saveToken('2|other');
    expect(await repository.getCachedToday(), isNull);
  });

  test('failed request does not cache a fallback or malformed copy', () async {
    fixture.body = {
      'data': {'body': 123, 'date': '2026-10-08'},
    };
    await expectLater(repository.fetchToday(), throwsA(isA<TypeError>()));
    expect(await repository.getCachedToday(), isNull);
    expect(fixture.box.keys, isNot(contains('1:affirmation_2026-10-08')));
  });
}
