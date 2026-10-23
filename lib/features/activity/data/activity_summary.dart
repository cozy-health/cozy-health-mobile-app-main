import '../../../core/data/mood_recording_catalog.dart';
import '../../../core/models/journal_entry.dart';
import '../../../core/models/mood_entry.dart';

DateTime activityDay(DateTime value) {
  final d = value.toLocal();
  return DateTime(d.year, d.month, d.day);
}

DateTime activityDateOffset(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

class ActivityBucket {
  const ActivityBucket(this.start, this.end, this.current, this.previous);
  final DateTime start, end;
  final double? current, previous;
}

class ActivityCause {
  const ActivityCause(this.label, this.count);
  final String label;
  final int count;
}

/// Calendar-day boundaries are shared by chart, rhythm and current streak.
/// Missing observations remain null; stronger emotion is not a positive score.
class ActivitySummary {
  ActivitySummary({
    required List<MoodEntry> moods,
    required List<JournalEntry> journals,
    required this.days,
    required DateTime now,
  }) {
    today = activityDay(now);
    end = activityDateOffset(today, 1);
    start = activityDateOffset(today, 1 - days);
    final previousStart = activityDateOffset(start, -days);
    bool within(DateTime d, DateTime a, DateTime b) {
      final local = d.toLocal();
      return !local.isBefore(a) &&
          local.isBefore(b) &&
          !local.isAfter(now.toLocal());
    }

    entries = moods.where((e) => within(e.createdAt, start, end)).toList();
    final previous = moods
        .where((e) => within(e.createdAt, previousStart, start))
        .toList();
    average = mean(entries);
    previousAverage = mean(previous);
    buckets = List.generate(7, (i) {
      final a = activityDateOffset(start, days * i ~/ 7),
          b = activityDateOffset(start, days * (i + 1) ~/ 7);
      final pa = activityDateOffset(previousStart, days * i ~/ 7),
          pb = activityDateOffset(previousStart, days * (i + 1) ~/ 7);
      return ActivityBucket(
        a,
        b,
        mean(entries.where((e) => within(e.createdAt, a, b))),
        mean(previous.where((e) => within(e.createdAt, pa, pb))),
      );
    });
    final counts = <String, int>{};
    for (final entry in entries) {
      final unique = {
        ...?entry.triggers,
        if (entry.customTrigger?.trim().isNotEmpty == true)
          entry.customTrigger!,
      }.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
      for (final label in unique) {
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }
    causes = counts.entries.map((e) => ActivityCause(e.key, e.value)).toList()
      ..sort((a, b) {
        final n = b.count.compareTo(a.count);
        return n == 0 ? a.label.compareTo(b.label) : n;
      });
    rhythmDates = List.generate(7, (i) => activityDateOffset(today, i - 6));
    final recorded = moods
        .where((e) => !e.createdAt.toLocal().isAfter(now.toLocal()))
        .map((e) => activityDay(e.createdAt))
        .toSet();
    checkedDays = rhythmDates.where(recorded.contains).toSet();
    final written = journals
        .where(
          (e) => !e.isDraft && !e.createdAt.toLocal().isAfter(now.toLocal()),
        )
        .map((e) => activityDay(e.createdAt))
        .toSet();
    var cursor = written.contains(today)
        ? today
        : activityDateOffset(today, -1);
    var streak = 0;
    while (written.contains(cursor)) {
      streak++;
      cursor = activityDateOffset(cursor, -1);
    }
    writingStreak = streak;
  }
  final int days;
  late final DateTime today, start, end;
  late final List<MoodEntry> entries;
  late final List<ActivityBucket> buckets;
  late final List<ActivityCause> causes;
  late final List<DateTime> rhythmDates;
  late final Set<DateTime> checkedDays;
  late final double? average, previousAverage;
  late final int writingStreak;
  static double? mean(Iterable<MoodEntry> values) {
    if (values.isEmpty) return null;
    return values.fold<double>(
          0,
          (sum, e) => sum + moodIntensityToDisplay(e.intensity),
        ) /
        values.length;
  }
}
