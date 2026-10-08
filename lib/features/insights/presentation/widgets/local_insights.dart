import 'package:hive/hive.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/models/journal_entry.dart';
import '../../../../core/services/local_db_service.dart';

/// Metrics without a matching Insights endpoint use the existing offline records.
class LocalInsights {
  static List<MoodEntry> moods({int days = 7, bool month = false}) {
    if (!Hive.isBoxOpen(LocalDbService.moodBoxName)) return [];
    final now = DateTime.now();
    final start = month
        ? DateTime(now.year, now.month)
        : DateTime(now.year, now.month, now.day - days + 1);
    final end = DateTime(now.year, now.month, now.day + 1);
    return LocalDbService.instance
        .getAllMoodEntries()
        .where(
          (entry) =>
              !entry.createdAt.toLocal().isBefore(start) &&
              entry.createdAt.toLocal().isBefore(end),
        )
        .toList();
  }

  static List<Map<String, dynamic>> daily({int days = 7, bool month = false}) {
    final groups = <String, List<MoodEntry>>{};
    for (final entry in moods(days: days, month: month)) {
      final date = entry.createdAt.toLocal().toIso8601String().substring(0, 10);
      (groups[date] ??= []).add(entry);
    }
    final dates = groups.keys.toList()..sort();
    return dates
        .map(
          (date) => <String, dynamic>{
            'day': date,
            'count': groups[date]!.length,
            'avg_intensity': average(groups[date]!),
          },
        )
        .toList();
  }

  static double average(List<MoodEntry> entries) => entries.isEmpty
      ? 0
      : entries.fold<int>(0, (sum, entry) => sum + entry.intensity) /
            entries.length;

  static String averageText({int days = 7, bool month = false}) {
    final entries = moods(days: days, month: month);
    return entries.isEmpty ? '—' : average(entries).toStringAsFixed(1);
  }

  static double? averageSleep({bool month = false}) {
    final entries = moods(
      days: 30,
      month: month,
    ).where((entry) => entry.sleepQuality != null).toList();
    return entries.isEmpty
        ? null
        : entries.fold<int>(0, (sum, entry) => sum + entry.sleepQuality!) /
              entries.length;
  }

  static List<JournalEntry> journals({int days = 7, bool month = false}) {
    if (!Hive.isBoxOpen(LocalDbService.journalBoxName)) return [];
    final now = DateTime.now();
    final start = month
        ? DateTime(now.year, now.month)
        : DateTime(now.year, now.month, now.day - days + 1);
    final end = DateTime(now.year, now.month, now.day + 1);
    return LocalDbService.instance
        .getAllJournalEntries()
        .where(
          (entry) =>
              !entry.createdAt.toLocal().isBefore(start) &&
              entry.createdAt.toLocal().isBefore(end),
        )
        .toList();
  }

  static List<double> activity(List<Map<String, dynamic>> dates) {
    final entries = journals();
    return dates
        .map(
          (row) => entries
              .where(
                (entry) =>
                    entry.createdAt.toLocal().toIso8601String().substring(
                      0,
                      10,
                    ) ==
                    row['day'],
              )
              .length
              .toDouble(),
        )
        .toList();
  }

  static String activityComparison() {
    final dates = daily();
    final activities = activity(dates);
    final withJournal = <double>[];
    final withoutJournal = <double>[];
    for (var i = 0; i < dates.length; i++) {
      (activities[i] > 0 ? withJournal : withoutJournal).add(
        (dates[i]['avg_intensity'] as num).toDouble(),
      );
    }
    if (withJournal.isEmpty || withoutJournal.isEmpty) {
      return 'Keep logging moods and journals to notice patterns.';
    }
    final withAvg = withJournal.reduce((a, b) => a + b) / withJournal.length;
    final withoutAvg =
        withoutJournal.reduce((a, b) => a + b) / withoutJournal.length;
    return 'Average mood intensity was ${withAvg.toStringAsFixed(1)} on days you journaled and ${withoutAvg.toStringAsFixed(1)} on other logged days.';
  }

  static String topTriggers() {
    final counts = <String, int>{};
    for (final entry in moods(month: true)) {
      for (final name in (entry.triggers ?? []).toSet()) {
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    final names = counts.keys.toList()
      ..sort(
        (a, b) => counts[b]!.compareTo(counts[a]!) == 0
            ? a.compareTo(b)
            : counts[b]!.compareTo(counts[a]!),
      );
    return names.isEmpty ? 'No triggers logged yet.' : names.take(3).join(', ');
  }

  static int longestStreak() {
    final dates = daily(
      month: true,
    ).map((row) => DateTime.parse(row['day'] as String)).toList();
    var longest = 0;
    var streak = 0;
    DateTime? previous;
    for (final date in dates) {
      streak =
          previous != null &&
              date == DateTime(previous.year, previous.month, previous.day + 1)
          ? streak + 1
          : 1;
      if (streak > longest) longest = streak;
      previous = date;
    }
    return longest;
  }
}
