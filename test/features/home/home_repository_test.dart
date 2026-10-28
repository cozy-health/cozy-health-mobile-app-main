import 'package:cozy_health/core/repositories/home_repository.dart';
import 'package:cozy_health/core/repositories/endpoint_cache.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
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

  test('streak reads authoritative rest-day accounting', () async {
    fixture.body = {
      'data': {
        'current_days': 7,
        'rest_days': 0,
        'protected_dates': ['2026-10-08'],
      },
    };
    final streak = await repository.fetchStreak();
    expect(streak['current_days'], 7);
    expect(streak['rest_days'], 0);
    expect(fixture.requests.single.path, '/api/v1/wellness/streak');
  });

  test('streak cannot be requested after logout', () async {
    await TokenStorage().clearToken();
    await expectLater(repository.fetchStreak(), throwsStateError);
    expect(fixture.requests, isEmpty);
  });

  test('confirmed streak is retained for offline reopening', () async {
    fixture.body = {
      'data': {'current_days': 7, 'rest_days': 1},
    };
    await repository.fetchStreak();
    final cached = await EndpointCache(
      now: () => now,
    ).read('streak_progress', allowStale: true);
    expect(cached?['current_days'], 7);
    expect(cached?['rest_days'], 1);
  });

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

  for (final endpoint in ['dashboard', 'streak']) {
    test(
      'delayed $endpoint response cannot reach a newly signed-in account',
      () async {
        final original = ApiClient().transportForTesting;
        final held = _HeldTransport();
        ApiClient().transportForTesting = held;
        try {
          final pending = endpoint == 'dashboard'
              ? repository.fetchDashboard()
              : repository.fetchStreak();
          await held.started.future;
          await TokenStorage().saveToken('2|new-session');
          held.response.complete(
            ResponseBody.fromString(
              jsonEncode(fixture.body),
              200,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            ),
          );
          await expectLater(pending, throwsStateError);
          expect(await repository.getCachedDashboard(allowStale: true), isNull);
          expect(await repository.getCachedStreak(), isNull);
        } finally {
          ApiClient().transportForTesting = original;
        }
      },
    );
  }

  test(
    'recent moods include new offline saves despite an older dashboard cache',
    () {
      final dashboard = DashboardData.fromJson({
        'recent_entries': [
          {
            'id': 'old',
            'mood': 'good',
            'intensity': 6,
            'client_created_at': '2026-10-07T12:00:00Z',
          },
        ],
      });
      final saved = MoodEntry(
        id: 'new',
        mood: 'calm',
        intensity: 5,
        createdAt: now,
        updatedAt: now,
      );
      expect(dashboard.recentMoods([saved]).map((entry) => entry.id), [
        'new',
        'old',
      ]);
      expect(dashboard.recentMoods([saved]).first, same(saved));
    },
  );

  test(
    'cache read discards data when its owner changes during the read',
    () async {
      await repository.fetchDashboard();
      expect(
        await _ChangingOwnerCache().read('home_dashboard', allowStale: true),
        isNull,
      );
    },
  );
}

class _ChangingOwnerCache extends EndpointCache {
  int _reads = 0;
  @override
  Future<String?> owner() async => ++_reads == 1 ? '1' : '2';
}

class _HeldTransport implements HttpClientAdapter {
  final started = Completer<void>();
  final response = Completer<ResponseBody>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) {
    started.complete();
    return response.future;
  }

  @override
  void close({bool force = false}) {}
}
