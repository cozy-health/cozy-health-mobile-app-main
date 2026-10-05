import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/journal_entry.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/repositories/journal_repository.dart';
import '../../../../core/repositories/mood_repository.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_scaffold_padding.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _moodRepo = MoodRepository();
  final _journalRepo = JournalRepository();
  final List<_ActivityPeriod> _periods = const [
    _ActivityPeriod(label: 'Week', days: 7),
    _ActivityPeriod(label: 'Month', days: 30),
    _ActivityPeriod(label: '3 Months', days: 90),
    _ActivityPeriod(label: 'Year', days: 365),
  ];

  int _selectedPeriod = 0;

  @override
  Widget build(BuildContext context) {
    final period = _periods[_selectedPeriod];
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;
    final mutedColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        title: Text(
          'Activity',
          style: AppTextStyles.heading2.copyWith(color: textColor),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'Open mood history',
              onPressed: () => context.push(AppRouter.moodHistory),
              icon: Icon(
                Icons.calendar_today_rounded,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<MoodEntry>>(
        stream: _moodRepo.watchMoodEntries(),
        builder: (context, moodSnapshot) {
          return StreamBuilder<List<JournalEntry>>(
            stream: _journalRepo.watchJournalEntries(),
            builder: (context, journalSnapshot) {
              final stats = _ActivityStats.fromEntries(
                moods: moodSnapshot.data ?? const [],
                journals: journalSnapshot.data ?? const [],
                period: period,
                now: DateTime.now(),
              );

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  AppScaffoldPadding.tabScrollBottom(context).bottom + 24,
                ),
                children: [
                  Text(
                    'Track how your check-ins, writing, and patterns are moving.',
                    style: AppTextStyles.body1.copyWith(
                      color: mutedColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PeriodSelector(
                    periods: _periods.map((period) => period.label).toList(),
                    selectedIndex: _selectedPeriod,
                    onSelected: (index) =>
                        setState(() => _selectedPeriod = index),
                  ),
                  const SizedBox(height: 20),
                  _MoodSummaryCard(stats: stats),
                  const SizedBox(height: 16),
                  _StatsRow(stats: stats),
                  const SizedBox(height: 24),
                  Text(
                    'General insights',
                    style: AppTextStyles.heading2.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 12),
                  _InsightCard(
                    icon: Icons.favorite_rounded,
                    title: 'Mood check-ins',
                    subtitle: stats.checkInSubtitle,
                    body: _CheckInDots(filledCount: stats.checkInDotCount),
                    actionLabel: 'View log',
                    onAction: () => context.push(AppRouter.moodHistory),
                  ),
                  const SizedBox(height: 12),
                  _InsightCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Writing',
                    subtitle: stats.writingSubtitle,
                    body: _WritingDays(activeWeekdays: stats.writingWeekdays),
                    actionLabel: 'Open journal',
                    onAction: () => context.push(AppRouter.journal),
                  ),
                  const SizedBox(height: 12),
                  _TriggerCard(
                    triggers: stats.topTriggers,
                    onDetails: () => context.push(AppRouter.insightsTriggers),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recommended for you',
                    style: AppTextStyles.heading2.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 12),
                  _RecommendationGrid(
                    onMoodTrend: () =>
                        context.push(AppRouter.insightsMoodTrend),
                    onSleep: () => context.push(AppRouter.insightsSleepMood),
                    onActivity: () =>
                        context.push(AppRouter.insightsActivityMood),
                    onJournal: () => context.push(AppRouter.journal),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ActivityPeriod {
  const _ActivityPeriod({required this.label, required this.days});

  final String label;
  final int days;
}

class _ActivityStats {
  const _ActivityStats({
    required this.period,
    required this.moods,
    required this.journals,
    required this.previousMoods,
    required this.chartValues,
    required this.topTriggers,
    required this.writingWeekdays,
  });

  final _ActivityPeriod period;
  final List<MoodEntry> moods;
  final List<JournalEntry> journals;
  final List<MoodEntry> previousMoods;
  final List<double> chartValues;
  final List<_TriggerStat> topTriggers;
  final Set<int> writingWeekdays;

  factory _ActivityStats.fromEntries({
    required List<MoodEntry> moods,
    required List<JournalEntry> journals,
    required _ActivityPeriod period,
    required DateTime now,
  }) {
    final end = now.toLocal();
    final endExclusive = DateTime(end.year, end.month, end.day + 1);
    final start = DateTime(
      end.year,
      end.month,
      end.day,
    ).subtract(Duration(days: period.days - 1));
    final previousStart = start.subtract(Duration(days: period.days));

    bool inRange(DateTime value, DateTime from, DateTime to) {
      final local = value.toLocal();
      return !local.isBefore(from) && local.isBefore(to);
    }

    final sortedMoods =
        moods
            .where((entry) => inRange(entry.createdAt, start, endExclusive))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final previousMoods = moods
        .where((entry) => inRange(entry.createdAt, previousStart, start))
        .toList();
    final filteredJournals =
        journals
            .where(
              (entry) =>
                  !entry.isDraft &&
                  inRange(entry.createdAt, start, endExclusive),
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return _ActivityStats(
      period: period,
      moods: sortedMoods,
      journals: filteredJournals,
      previousMoods: previousMoods,
      chartValues: _buildChartValues(sortedMoods, period.days, start),
      topTriggers: _buildTopTriggers(sortedMoods),
      writingWeekdays: filteredJournals
          .map((entry) => entry.createdAt.toLocal().weekday)
          .toSet(),
    );
  }

  static List<double> _buildChartValues(
    List<MoodEntry> moods,
    int days,
    DateTime start,
  ) {
    const bucketCount = 7;
    if (moods.isEmpty) return const [];

    return List.generate(bucketCount, (bucket) {
      final bucketStart = start.add(
        Duration(days: (days * bucket) ~/ bucketCount),
      );
      final bucketEnd = start.add(
        Duration(days: (days * (bucket + 1)) ~/ bucketCount),
      );
      final bucketMoods = moods.where((entry) {
        final local = entry.createdAt.toLocal();
        return !local.isBefore(bucketStart) && local.isBefore(bucketEnd);
      }).toList();
      if (bucketMoods.isEmpty) return 0.0;
      final total = bucketMoods.fold<int>(
        0,
        (sum, entry) => sum + entry.intensity.clamp(1, 10),
      );
      return total / bucketMoods.length;
    });
  }

  static List<_TriggerStat> _buildTopTriggers(List<MoodEntry> moods) {
    final counts = <String, int>{};
    for (final mood in moods) {
      for (final trigger in mood.triggers ?? const <String>[]) {
        final label = trigger.trim();
        if (label.isEmpty) continue;
        counts[label] = (counts[label] ?? 0) + 1;
      }
      final custom = mood.customTrigger?.trim();
      if (custom != null && custom.isNotEmpty) {
        counts[custom] = (counts[custom] ?? 0) + 1;
      }
    }

    final total = moods.isEmpty ? 1 : moods.length;
    final stats =
        counts.entries
            .map(
              (entry) => _TriggerStat(
                label: entry.key,
                count: entry.value,
                share: (entry.value / total).clamp(0.0, 1.0),
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));
    return stats.take(3).toList();
  }

  double get averageMood {
    if (moods.isEmpty) return 0;
    final total = moods.fold<int>(
      0,
      (sum, entry) => sum + entry.intensity.clamp(1, 10),
    );
    return total / moods.length;
  }

  double get previousAverageMood {
    if (previousMoods.isEmpty) return 0;
    final total = previousMoods.fold<int>(
      0,
      (sum, entry) => sum + entry.intensity.clamp(1, 10),
    );
    return total / previousMoods.length;
  }

  String get moodTrendValue {
    if (moods.isEmpty) return 'No data';
    if (previousMoods.isEmpty) return averageMood.toStringAsFixed(1);
    final change =
        ((averageMood - previousAverageMood) / previousAverageMood) * 100;
    final rounded = change.round();
    if (rounded == 0) return '0%';
    return '${rounded > 0 ? '+' : ''}$rounded%';
  }

  String get moodSummaryTitle => 'Mood for the ${period.label}';

  String get moodSummary {
    if (moods.isEmpty) {
      return 'No mood check-ins for this period yet.';
    }
    final moodCounts = <String, int>{};
    for (final mood in moods) {
      final key = MoodEntry.normalizeMoodKey(mood.mood);
      moodCounts[key] = (moodCounts[key] ?? 0) + 1;
    }
    final topMood = moodCounts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final label = _titleCase(topMood.key);
    return '$label was your most common mood across ${moods.length} check-ins.';
  }

  String get checkInSubtitle {
    final noun = moods.length == 1 ? 'check-in' : 'check-ins';
    return '${moods.length} $noun in this period';
  }

  int get checkInDotCount => moods.length.clamp(0, 7);

  String get writingSubtitle {
    final days = journals
        .map((entry) {
          final local = entry.createdAt.toLocal();
          return DateTime(local.year, local.month, local.day);
        })
        .toSet()
        .length;
    final noun = days == 1 ? 'journaling day' : 'journaling days';
    return '$days $noun';
  }

  String get writingStreakValue {
    if (journals.isEmpty) return '0 days';
    final days = journals.map((entry) {
      final local = entry.createdAt.toLocal();
      return DateTime(local.year, local.month, local.day);
    }).toSet();
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return '$streak ${streak == 1 ? 'day' : 'days'}';
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _TriggerStat {
  const _TriggerStat({
    required this.label,
    required this.count,
    required this.share,
  });

  final String label;
  final int count;
  final double share;

  String get impact {
    if (share >= .6) return 'High impact';
    if (share >= .3) return 'Medium impact';
    return 'Low impact';
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.periods,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> periods;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceElevatedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          for (var i = 0; i < periods.length; i++)
            Expanded(
              child: _PeriodChip(
                label: periods[i],
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body2.copyWith(
            color: selected ? AppColors.white : colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MoodSummaryCard extends StatelessWidget {
  const _MoodSummaryCard({required this.stats});

  final _ActivityStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _ActivityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.moodSummaryTitle,
                      style: AppTextStyles.heading2.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stats.moodSummary,
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite_rounded, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 144,
            child: CustomPaint(
              painter: _MoodChartPainter(values: stats.chartValues),
              size: const Size(double.infinity, 144),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final _ActivityStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.show_chart_rounded,
            value: stats.moodTrendValue,
            label: 'Mood trend',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            value: stats.writingStreakValue,
            label: 'Writing streak',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _ActivityCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: colorScheme.onSurface,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _ActivityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading3.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          body,
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

class _CheckInDots extends StatelessWidget {
  const _CheckInDots({required this.filledCount});

  final int filledCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isFilled = index < filledCount;

        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isFilled
                ? colorScheme.primary.withValues(alpha: .16)
                : Theme.of(context).dividerTheme.color,
            shape: BoxShape.circle,
          ),
          child: isFilled
              ? Icon(Icons.check_rounded, size: 18, color: colorScheme.primary)
              : null,
        );
      }),
    );
  }
}

class _WritingDays extends StatelessWidget {
  const _WritingDays({required this.activeWeekdays});

  final Set<int> activeWeekdays;

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final colorScheme = Theme.of(context).colorScheme;
    final mutedColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (index) {
        final isFilled = activeWeekdays.contains(index + 1);

        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isFilled
                    ? colorScheme.primary.withValues(alpha: .16)
                    : Theme.of(context).dividerTheme.color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFilled
                    ? Icons.edit_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: isFilled ? colorScheme.primary : mutedColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              days[index],
              style: AppTextStyles.body2.copyWith(
                color: mutedColor,
                fontSize: 12,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TriggerCard extends StatelessWidget {
  const _TriggerCard({required this.triggers, required this.onDetails});

  final List<_TriggerStat> triggers;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _ActivityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Common triggers',
                  style: AppTextStyles.heading3.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(onPressed: onDetails, child: const Text('Details')),
            ],
          ),
          const SizedBox(height: 12),
          if (triggers.isEmpty)
            Text(
              'No triggers logged in this period.',
              style: AppTextStyles.body2.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            )
          else
            for (var i = 0; i < triggers.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _TriggerItem(
                label: triggers[i].label,
                value: triggers[i].share,
                impact: triggers[i].impact,
              ),
            ],
        ],
      ),
    );
  }
}

class _TriggerItem extends StatelessWidget {
  const _TriggerItem({
    required this.label,
    required this.value,
    required this.impact,
  });

  final String label;
  final double value;
  final String impact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = '${(value * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body1.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              percent,
              style: AppTextStyles.body1.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: colorScheme.primary.withValues(alpha: .10),
          valueColor: AlwaysStoppedAnimation(colorScheme.primary),
        ),
        const SizedBox(height: 4),
        Text(
          impact,
          style: AppTextStyles.body2.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RecommendationGrid extends StatelessWidget {
  const _RecommendationGrid({
    required this.onMoodTrend,
    required this.onSleep,
    required this.onActivity,
    required this.onJournal,
  });

  final VoidCallback onMoodTrend;
  final VoidCallback onSleep;
  final VoidCallback onActivity;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: .92,
      children: [
        _RecommendationCard(
          icon: Icons.show_chart_rounded,
          title: 'Review your mood trend',
          onTap: onMoodTrend,
        ),
        _RecommendationCard(
          icon: Icons.bedtime_rounded,
          title: 'Check sleep and mood patterns',
          onTap: onSleep,
        ),
        _RecommendationCard(
          icon: Icons.directions_walk_rounded,
          title: 'Compare activity and mood',
          onTap: onActivity,
        ),
        _RecommendationCard(
          icon: Icons.spa_rounded,
          title: 'Reflect in your journal',
          onTap: onJournal,
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _ActivityCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body1.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevatedDark
            : AppColors.surfaceElevatedLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _MoodChartPainter extends CustomPainter {
  const _MoodChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: .18),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty || values.every((value) => value == 0)) {
      final emptyPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: .18)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0, size.height * .62),
        Offset(size.width, size.height * .62),
        emptyPaint,
      );
      return;
    }

    final usableValues = values.map((value) {
      if (value == 0) return 5.0;
      return value.clamp(1.0, 10.0);
    }).toList();
    final points = List.generate(usableValues.length, (index) {
      final dx = usableValues.length == 1
          ? size.width / 2
          : size.width * index / (usableValues.length - 1);
      final yRatio = (usableValues[index] - 1) / 9;
      final dy = size.height - (yRatio * size.height);
      return Offset(dx, dy.clamp(8.0, size.height - 8));
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final point = points[i];
      final midpoint = Offset(
        (previous.dx + point.dx) / 2,
        (previous.dy + point.dy) / 2,
      );
      path.quadraticBezierTo(
        previous.dx,
        previous.dy,
        midpoint.dx,
        midpoint.dy,
      );
    }
    path.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    final dotBorderPaint = Paint()..color = AppColors.white;
    for (final point in points) {
      canvas.drawCircle(point, 6, dotBorderPaint);
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodChartPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}
