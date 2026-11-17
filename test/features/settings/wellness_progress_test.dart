import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/features/settings/data/wellness_progress.dart';

void main() {
  final now = DateTime.utc(2026, 10, 23, 12);
  MoodEntry mood(int day, {int hour = 8}) {
    final date = DateTime.utc(2026, 10, day, hour);
    return MoodEntry(
      id: '$day-$hour',
      mood: 'good',
      intensity: 6,
      createdAt: date,
      updatedAt: date,
    );
  }

  WellnessProgress progress(
    List<MoodEntry> moods, {
    List<JournalEntry> journals = const [],
    DateTime Function(DateTime)? convert,
  }) => WellnessProgress(
    moods: moods,
    journals: journals,
    now: now,
    calendarTime: convert ?? (d) => d.toUtc(),
  );
  test(
    'Repeated check-ins count once per day, future records do not count',
    () {
      final p = progress([
        mood(21),
        mood(21, hour: 9),
        mood(22),
        mood(23),
        mood(24),
      ]);
      expect(p.entryCount, 4);
      expect(p.current, 3);
      expect(p.longest, 3);
      expect(p.checkedDays.length, 3);
      expect(p.derivedAwards['streak_3'], DateTime.utc(2026, 10, 23));
      expect(p.derivedAwards.containsKey('streak_7'), false);
    },
  );
  test(
    'Yesterday retains a streak until today ends; longer gaps reset current only',
    () {
      expect(progress([mood(20), mood(21), mood(22)]).current, 3);
      final p = progress([mood(19), mood(20), mood(21)]);
      expect(p.current, 0);
      expect(p.longest, 3);
      expect(p.derivedAwards.containsKey('streak_3'), true);
    },
  );
  test(
    'First earned date is retained when a later run reaches the same target',
    () {
      final p = progress([
        for (final day in [1, 2, 3, 20, 21, 22, 23]) mood(day),
      ]);
      expect(p.current, 4);
      expect(p.derivedAwards['streak_3'], DateTime.utc(2026, 10, 3));
    },
  );
  test('Draft and future journals cannot earn the first journal milestone', () {
    JournalEntry journal(int day, bool draft) {
      final d = DateTime.utc(2026, 10, day);
      return JournalEntry(
        id: '$day',
        type: 'free',
        body: 'Private',
        wordCount: 1,
        isDraft: draft,
        createdAt: d,
        updatedAt: d,
      );
    }

    expect(
      progress(
        [],
        journals: [journal(20, true), journal(24, false)],
      ).derivedAwards,
      isEmpty,
    );
    expect(
      progress(
        [],
        journals: [journal(20, true), journal(22, false)],
      ).derivedAwards['first_journal'],
      DateTime.utc(2026, 10, 22),
    );
  });
  test(
    'Account calendar conversion applies before unique day and today comparisons',
    () {
      final p = progress([
        mood(21, hour: 23),
        mood(22, hour: 23),
      ], convert: (d) => d.toUtc().add(const Duration(hours: 2)));
      expect(p.checkedToday, true);
      expect(p.current, 2);
      expect(p.week.last, DateTime.utc(2026, 10, 23));
      expect(p.week.first, DateTime.utc(2026, 10, 17));
    },
  );
  test('Thirty-day run derives all supported streak milestones', () {
    final end = DateTime.utc(2026, 10, 23);
    final p = progress([
      for (var i = 29; i >= 0; i--)
        MoodEntry(
          id: '$i',
          mood: 'sad',
          intensity: 2,
          createdAt: end.subtract(Duration(days: i)),
          updatedAt: end.subtract(Duration(days: i)),
        ),
    ]);
    expect(p.current, 30);
    expect(
      p.derivedAwards.keys,
      containsAll(['first_mood', 'streak_3', 'streak_7', 'streak_30']),
    );
  });
}
