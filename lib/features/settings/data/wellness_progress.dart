import '../../../core/models/journal_entry.dart';
import '../../../core/models/mood_entry.dart';

class WellnessMilestone {
  const WellnessMilestone(
    this.id,
    this.title,
    this.description, {
    this.streakTarget,
  });
  final String id, title, description;
  final int? streakTarget;
  static const catalog = [
    WellnessMilestone(
      'first_mood',
      'Your first check-in',
      'Save one mood check-in.',
    ),
    WellnessMilestone(
      'first_journal',
      'Your first journal entry',
      'Save a completed journal entry.',
    ),
    WellnessMilestone(
      'streak_3',
      'Three steady days',
      'Save mood check-ins on 3 days in your streak.',
      streakTarget: 3,
    ),
    WellnessMilestone(
      'streak_7',
      'A week of checking in',
      'Save mood check-ins on 7 days in your streak.',
      streakTarget: 7,
    ),
    WellnessMilestone(
      'streak_30',
      'Thirty days of checking in',
      'Save mood check-ins on 30 days in your streak. Earned rest days protect progress without adding check-ins.',
      streakTarget: 30,
    ),
  ];
}

/// UTC values here represent calendar dates, not midnight instants to re-zone.
DateTime wellnessDay(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);
DateTime wellnessDayOffset(DateTime value, int offset) =>
    DateTime.utc(value.year, value.month, value.day + offset);

class WellnessProgress {
  WellnessProgress({
    required List<MoodEntry> moods,
    required List<JournalEntry> journals,
    required DateTime now,
    DateTime Function(DateTime)? calendarTime,
  }) {
    final convert = calendarTime ?? (DateTime d) => d.toLocal();
    today = wellnessDay(convert(now));
    final valid = moods.where((e) => !e.createdAt.isAfter(now)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final writing =
        journals.where((e) => !e.isDraft && !e.createdAt.isAfter(now)).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    entryCount = valid.length;
    checkedDays = valid.map((e) => wellnessDay(convert(e.createdAt))).toSet();
    final days = checkedDays.toList()..sort();
    week = List.generate(7, (i) => wellnessDayOffset(today, i - 6));
    final awards = <String, DateTime>{};
    if (valid.isNotEmpty) {
      awards['first_mood'] = wellnessDay(convert(valid.first.createdAt));
    }
    if (writing.isNotEmpty) {
      awards['first_journal'] = wellnessDay(convert(writing.first.createdAt));
    }
    var run = 0, best = 0;
    DateTime? previous;
    for (final day in days) {
      run = previous != null && wellnessDayOffset(previous, 1) == day
          ? run + 1
          : 1;
      if (run > best) best = run;
      for (final target in [3, 7, 30]) {
        if (run >= target) awards.putIfAbsent('streak_$target', () => day);
      }
      previous = day;
    }
    longest = best;
    var cursor = checkedDays.contains(today)
            ? today
            : wellnessDayOffset(today, -1),
        streak = 0;
    while (checkedDays.contains(cursor)) {
      streak++;
      cursor = wellnessDayOffset(cursor, -1);
    }
    current = streak;
    derivedAwards = awards;
  }
  late final DateTime today;
  late final List<DateTime> week;
  late final Set<DateTime> checkedDays;
  late final int entryCount, current, longest;
  late final Map<String, DateTime> derivedAwards;
  bool get checkedToday => checkedDays.contains(today);
}
