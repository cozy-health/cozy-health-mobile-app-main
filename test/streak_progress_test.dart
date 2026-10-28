import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/streak_progress.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> days(int count) => List.generate(
  count,
  (i) => streakDate(DateTime.utc(2026, 10, 1).add(Duration(days: i))),
);
StreakProgress baseline({
  int count = 7,
  String timezone = 'UTC',
  String? starts,
}) {
  final completed = days(count);
  final eligible = completed
      .where((date) => date.compareTo(starts ?? '2026-10-01') >= 0)
      .length;
  return StreakProgress.fromJson({
    'account_id': '1',
    'accounting_version': 1,
    'earning_starts': starts ?? '2026-10-01',
    'as_of': '${completed.last}T00:00:00Z',
    'timezone': timezone,
    'local_date': completed.last,
    'current_days': count,
    'best_days': count,
    'rest_days': (eligible ~/ 7).clamp(0, 2),
    'earning_progress': eligible % 7,
    'completed_dates': completed,
    'protected_dates': <String>[],
    'credited_sources': {
      for (var i = 0; i < count; i++) 'source-$i': days(count)[i],
    },
  });
}

MoodEntry mood(String id, String date) => MoodEntry(
  id: id,
  mood: 'good',
  intensity: 6,
  createdAt: DateTime.parse(date),
  updatedAt: DateTime.parse(date),
);

void main() {
  test('protects seven without counting a missed day and resumes at eight', () {
    final confirmed = baseline();
    final protected = confirmed.project(DateTime.utc(2026, 10, 9, 12), []);
    expect(protected.currentDays, 7);
    expect(protected.restDays, 0);
    expect(protected.protectedDates, {'2026-10-08'});
    final resumed = confirmed.project(DateTime.utc(2026, 10, 9, 12), [
      mood('new', '2026-10-09T10:00:00Z'),
    ]);
    expect(resumed.currentDays, 8);
    expect(resumed.earningProgress, 1);
    expect(resumed.pendingDates, {'2026-10-09'});
    expect(resumed.estimated, isTrue);
    expect(
      confirmed.restDays,
      1,
    ); // Projecting cannot mutate the confirmed bank.
  });

  test(
    'late offline day refunds protection and duplicate dates do not earn twice',
    () {
      final result = baseline().project(DateTime.utc(2026, 10, 9, 12), [
        mood('late', '2026-10-08T10:00:00Z'),
        mood('today', '2026-10-09T10:00:00Z'),
        mood('duplicate-day', '2026-10-09T11:00:00Z'),
      ]);
      expect(result.currentDays, 9);
      expect(result.restDays, 1);
      expect(result.protectedDates, isEmpty);
      expect(result.earningProgress, 2);
    },
  );

  test('source identity prevents an old edited mood minting a second day', () {
    final result = baseline().project(DateTime.utc(2026, 10, 8, 12), [
      mood('source-0', '2026-10-08T10:00:00Z'),
    ]);
    expect(result.currentDays, 7);
    expect(result.completedDates, isNot(contains('2026-10-08')));
    expect(result.pendingDates, isEmpty);
  });

  test('no retroactive credits and no spending the unfinished current day', () {
    final result = baseline(
      starts: '2026-10-07',
    ).project(DateTime.utc(2026, 10, 9, 12), []);
    expect(result.currentDays, 0);
    expect(result.restDays, 0);
    final today = baseline().project(DateTime.utc(2026, 10, 8, 12), []);
    expect(today.currentDays, 7);
    expect(today.restDays, 1);
    expect(today.protectedDates, isEmpty);
  });

  test(
    'bank caps at two; sparse years reset without iterating every missed day',
    () {
      final saved = baseline(count: 21);
      final capped = saved.project(DateTime.utc(2026, 10, 22, 12), []);
      expect(capped.restDays, 2);
      expect(capped.currentDays, 21);
      final later = saved.project(DateTime.utc(2036, 10, 22, 12), []);
      expect(later.currentDays, 0);
      expect(later.restDays, 0);
      expect(later.protectedDates, hasLength(2));
    },
  );

  test(
    'account timezone determines dates and future mood saves do not count',
    () {
      final result = baseline(timezone: 'Pacific/Auckland')
          .project(DateTime.utc(2026, 10, 8, 12), [
            mood('next-local-day', '2026-10-08T11:30:00Z'),
            mood('future', '2026-10-10T10:00:00Z'),
          ]);
      expect(result.localDate, '2026-10-09');
      expect(result.pendingDates, {'2026-10-09'});
      expect(result.currentDays, 8);
    },
  );

  test('local-midnight scheduling handles both DST transitions', () {
    final data = baseline().toJson()..['timezone'] = 'America/New_York';
    final progress = StreakProgress.fromJson(data);
    expect(
      progress.untilNextDay(DateTime.utc(2026, 3, 8, 5)),
      const Duration(hours: 23),
    );
    expect(
      progress.untilNextDay(DateTime.utc(2026, 11, 1, 4)),
      const Duration(hours: 25),
    );
  });

  test(
    'clock rollback and unknown accounting versions preserve confirmed data',
    () {
      final confirmed = baseline();
      final rollback = confirmed.project(DateTime.utc(2026, 10, 1), [
        mood('new', '2026-10-01T00:00:00Z'),
      ]);
      expect(rollback.clockChanged, isTrue);
      expect(rollback.restDays, confirmed.restDays);
      final data = confirmed.toJson()..['accounting_version'] = 2;
      final unknown = StreakProgress.fromJson(data);
      expect(
        identical(unknown.project(DateTime.utc(2026, 10, 9), []), unknown),
        isTrue,
      );
    },
  );

  test(
    'invalid bank or dates are rejected rather than displayed as confirmed',
    () {
      final data = baseline().toJson()..['rest_days'] = 3;
      expect(() => StreakProgress.fromJson(data), throwsFormatException);
      data['rest_days'] = 1;
      data['local_date'] = '2026-02-31';
      expect(() => StreakProgress.fromJson(data), throwsFormatException);
    },
  );
}
