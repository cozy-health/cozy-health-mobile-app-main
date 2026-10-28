import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;
import 'mood_entry.dart';

/// Calendar labels are UTC dates, never device-local midnight instants.
String streakDate(DateTime date) => date.toIso8601String().substring(0, 10);
DateTime _day(String value) {
  final date = DateTime.tryParse(value);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
      date == null ||
      streakDate(date) != value) {
    throw const FormatException('Invalid streak calendar date.');
  }
  return DateTime.utc(date.year, date.month, date.day);
}

class StreakProgress {
  StreakProgress({
    required this.currentDays,
    required this.bestDays,
    required this.restDays,
    required this.earningProgress,
    required this.localDate,
    required this.timezone,
    required this.confirmedAt,
    required Set<String> completedDates,
    required Set<String> protectedDates,
    this.earningStarts,
    this.accountId,
    this.accountingVersion = 0,
    Map<String, String> creditedSources = const {},
    Set<String> pendingDates = const {},
    this.estimated = false,
    this.clockChanged = false,
  }) : completedDates = Set.unmodifiable(completedDates),
       protectedDates = Set.unmodifiable(protectedDates),
       creditedSources = Map.unmodifiable(creditedSources),
       pendingDates = Set.unmodifiable(pendingDates);

  final int currentDays, bestDays, restDays, earningProgress, accountingVersion;
  final String localDate, timezone;
  final String? earningStarts, accountId;
  final DateTime confirmedAt;
  final Set<String> completedDates, protectedDates, pendingDates;
  final Map<String, String> creditedSources;
  final bool estimated, clockChanged;
  static bool _timezonesReady = false;

  factory StreakProgress.fromJson(
    Map<String, dynamic> json, {
    DateTime? receivedAt,
  }) {
    int integer(String key, {int? fallback, int? maximum}) {
      final raw = json[key] ?? fallback;
      if (raw is! num ||
          raw != raw.toInt() ||
          raw < 0 ||
          (maximum != null && raw > maximum)) {
        throw FormatException('Invalid streak $key.');
      }
      return raw.toInt();
    }

    Set<String> dates(String key) {
      final raw = json[key];
      if (raw is! List) throw FormatException('Invalid streak $key.');
      return raw.map((value) {
        if (value is! String) {
          throw const FormatException('Invalid streak date.');
        }
        _day(value);
        return value;
      }).toSet();
    }

    final today = json['local_date'];
    if (today is! String) throw const FormatException('Missing streak date.');
    _day(today);
    final timezone = json['timezone'] as String? ?? 'UTC';
    final starts = json['earning_starts'] as String?;
    if (starts != null) _day(starts);
    final rawSources = json['credited_sources'];
    final sources = <String, String>{};
    if (rawSources is Map) {
      for (final entry in rawSources.entries) {
        if (entry.key is! String || entry.value is! String) {
          throw const FormatException('Invalid streak source.');
        }
        _day(entry.value as String);
        sources[entry.key as String] = entry.value as String;
      }
    } else if (rawSources != null &&
        !(rawSources is List && rawSources.isEmpty)) {
      throw const FormatException('Invalid streak sources.');
    }
    final count = integer('current_days');
    final progress = StreakProgress(
      currentDays: count,
      bestDays: integer('best_days', fallback: count),
      restDays: integer('rest_days', maximum: 2),
      earningProgress: integer('earning_progress', maximum: 6),
      localDate: today,
      timezone: timezone,
      confirmedAt: json['as_of'] is String
          ? DateTime.parse(json['as_of'] as String).toUtc()
          : (receivedAt ?? DateTime.now()).toUtc(),
      completedDates: dates('completed_dates'),
      protectedDates: dates('protected_dates'),
      earningStarts: starts,
      accountId: json['account_id']?.toString(),
      accountingVersion: integer('accounting_version', fallback: 0),
      creditedSources: sources,
    );
    progress.dayAt(progress.confirmedAt); // Fail safely on an unknown timezone.
    return progress;
  }

  DateTime dayAt(DateTime timestamp) {
    if (!_timezonesReady) {
      timezone_data.initializeTimeZones();
      _timezonesReady = true;
    }
    final local = tz.TZDateTime.from(
      timestamp,
      timezone == 'UTC' ? tz.UTC : tz.getLocation(timezone),
    );
    return DateTime.utc(local.year, local.month, local.day);
  }

  List<DateTime> get week =>
      List.generate(7, (i) => _day(localDate).add(Duration(days: i - 6)));
  Duration untilNextDay(DateTime now) {
    dayAt(now);
    final local = tz.TZDateTime.from(
      now,
      timezone == 'UTC' ? tz.UTC : tz.getLocation(timezone),
    );
    return tz.TZDateTime(
      local.location,
      local.year,
      local.month,
      local.day + 1,
    ).difference(now);
  }

  bool get todayCompleted => completedDates.contains(localDate);
  bool get replaySupported => accountingVersion == 1 && earningStarts != null;

  Map<String, dynamic> toJson() => {
    'current_days': currentDays,
    'best_days': bestDays,
    'rest_days': restDays,
    'earning_progress': earningProgress,
    'local_date': localDate,
    'timezone': timezone,
    'as_of': confirmedAt.toUtc().toIso8601String(),
    'account_id': accountId,
    'completed_dates': completedDates.toList(),
    'protected_dates': protectedDates.toList(),
    'earning_starts': earningStarts,
    'accounting_version': accountingVersion,
    'credited_sources': Map<String, String>.of(creditedSources),
  };

  /// A provisional projection never overwrites the confirmed cache or grants access.
  StreakProgress project(DateTime now, Iterable<MoodEntry> localMoods) {
    if (!replaySupported) return this;
    final clockChanged = now.toUtc().isBefore(
      confirmedAt.subtract(const Duration(minutes: 1)),
    );
    final today = clockChanged ? localDate : streakDate(dayAt(now));
    final dates = {...completedDates};
    final pending = <String>{};
    if (!clockChanged) {
      for (final mood in localMoods) {
        if (creditedSources.containsKey(mood.id) ||
            mood.createdAt.isAfter(now)) {
          continue;
        }
        final date = streakDate(dayAt(mood.createdAt));
        if (date.compareTo(today) <= 0) {
          dates.add(date);
          pending.add(date);
        }
      }
    }
    if (clockChanged) {
      return StreakProgress(
        currentDays: currentDays,
        bestDays: bestDays,
        restDays: restDays,
        earningProgress: earningProgress,
        localDate: localDate,
        timezone: timezone,
        confirmedAt: confirmedAt,
        completedDates: completedDates,
        protectedDates: protectedDates,
        earningStarts: earningStarts,
        accountId: accountId,
        accountingVersion: accountingVersion,
        creditedSources: creditedSources,
        clockChanged: true,
      );
    }
    if (today == localDate && pending.isEmpty) return this;
    final ordered = dates.where((date) => date.compareTo(today) <= 0).toList()
      ..sort();
    var count = 0, best = 0, bank = 0, run = 0;
    DateTime? previous;
    final protected = <String>{};
    void gapUntil(DateTime next) {
      final last = previous;
      if (last == null) return;
      final gap = next.difference(last).inDays - 1;
      if (gap <= 0) return;
      run = 0;
      final spent = bank < gap ? bank : gap;
      for (var i = 1; i <= spent; i++) {
        protected.add(streakDate(last.add(Duration(days: i))));
      }
      bank -= spent;
      if (gap > spent) count = 0;
    }

    for (final date in ordered) {
      final day = _day(date);
      gapUntil(day);
      count++;
      if (count > best) best = count;
      if (date.compareTo(earningStarts!) >= 0) {
        run++;
        if (run == 7) {
          if (bank < 2) bank++;
          run = 0;
        }
      } else {
        run = 0;
      }
      previous = day;
    }
    gapUntil(_day(today)); // The unfinished current day is never spent.
    return StreakProgress(
      currentDays: count,
      bestDays: best > bestDays ? best : bestDays,
      restDays: bank,
      earningProgress: run,
      localDate: today,
      timezone: timezone,
      confirmedAt: confirmedAt,
      completedDates: ordered.toSet(),
      protectedDates: protected,
      earningStarts: earningStarts,
      accountId: accountId,
      accountingVersion: accountingVersion,
      creditedSources: creditedSources,
      pendingDates: pending,
      estimated: true,
    );
  }
}
