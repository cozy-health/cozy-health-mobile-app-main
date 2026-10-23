import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/features/activity/data/activity_summary.dart';

void main() {
  final now = DateTime(2026, 10, 22, 12);
  MoodEntry mood(
    int day,
    int intensity, {
    List<String>? causes,
    String? custom,
  }) => MoodEntry(
    id: '$day-$intensity',
    mood: 'happy',
    intensity: intensity,
    createdAt: DateTime(2026, 10, day, 10),
    updatedAt: now,
    triggers: causes,
    customTrigger: custom,
  );
  JournalEntry journal(int day, {bool draft = false}) => JournalEntry(
    id: 'j$day',
    type: 'free',
    body: 'test',
    wordCount: 1,
    createdAt: DateTime(2026, 10, day, 10),
    updatedAt: now,
    isDraft: draft,
  );
  test(
    'empty buckets stay absent; stored intensity is displayed on 1 to 5 scale',
    () {
      final s = ActivitySummary(
        moods: [
          mood(16, 6),
          mood(17, 8),
          mood(19, 6),
          mood(20, 4),
          mood(22, 8),
        ],
        journals: [],
        days: 7,
        now: now,
      );
      expect(s.average, 3.2);
      expect(s.buckets.map((b) => b.current), [
        3.0,
        4.0,
        null,
        3.0,
        2.0,
        null,
        4.0,
      ]);
      expect(s.previousAverage, isNull);
      expect(s.checkedDays.length, 5);
    },
  );
  test(
    'duplicate causes and multiple moods on one date do not invent activity',
    () {
      final s = ActivitySummary(
        moods: [
          mood(22, 4, causes: ['Work', 'Work'], custom: 'Work'),
          mood(22, 6, causes: ['Sleep']),
        ],
        journals: [],
        days: 7,
        now: now,
      );
      expect(s.checkedDays.length, 1);
      expect(s.causes.map((c) => c.count), [1, 1]);
    },
  );
  test(
    'comparison boundaries are separate and future records do not extend rhythm',
    () {
      final s = ActivitySummary(
        moods: [mood(9, 10), mood(15, 6), mood(16, 4), mood(23, 10)],
        journals: [],
        days: 7,
        now: now,
      );
      expect(s.entries.length, 1);
      expect(s.previousAverage, 4);
      expect(s.start, DateTime(2026, 10, 16));
      expect(s.checkedDays, {DateTime(2026, 10, 16)});
    },
  );
  test(
    'current writing streak uses all completed journals, independent of reporting range',
    () {
      final journals = [
        for (var day = 10; day <= 21; day++) journal(day),
        journal(22, draft: true),
        journal(23),
      ];
      final week = ActivitySummary(
            moods: [],
            journals: journals,
            days: 7,
            now: now,
          ),
          year = ActivitySummary(
            moods: [],
            journals: journals,
            days: 365,
            now: now,
          );
      expect(week.writingStreak, 12);
      expect(year.writingStreak, 12);
    },
  );
  test(
    'future times today do not produce an average without a rhythm check-in',
    () {
      final future = now.add(const Duration(minutes: 1));
      final s = ActivitySummary(
        moods: [
          MoodEntry(
            id: 'future',
            mood: 'good',
            intensity: 10,
            createdAt: future,
            updatedAt: future,
          ),
        ],
        journals: [],
        days: 7,
        now: now,
      );
      expect(s.average, isNull);
      expect(s.checkedDays, isEmpty);
    },
  );
}
