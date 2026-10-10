import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/mood_entry.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/weekday_row.dart';

/// Content determines the height, including at larger accessibility text sizes.
class CozyCalendar extends StatelessWidget {
  const CozyCalendar({
    super.key,
    required this.entries,
    required this.recentEntries,
    required this.streak,
    required this.weeklyCount,
    required this.weeklyIntensityTotal,
    required this.hasMoodToday,
    required this.onStreak,
    this.now,
  });

  final List<MoodEntry> entries;
  final List<MoodEntry> recentEntries;
  final int streak;
  final int weeklyCount;
  final double weeklyIntensityTotal;
  final bool hasMoodToday;
  final VoidCallback onStreak;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final monday = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cozy Calendar', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'A little check-in, every day.',
              style: theme.textTheme.bodyMedium,
            ),
            if (hasMoodToday)
              Text(
                'Your check-in is saved for today.',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            WeekdayRow(
              days: List.generate(7, (index) {
                final date = DateTime(
                  monday.year,
                  monday.month,
                  monday.day + index,
                );
                final dayEntries = entries.where((entry) {
                  final day = entry.createdAt.toLocal();
                  return day.year == date.year &&
                      day.month == date.month &&
                      day.day == date.day;
                }).toList();
                return WeekdayItem(
                  label: labels[index],
                  filled: dayEntries.isNotEmpty,
                  semanticLabel: '${labels[index]}, ${date.month}/${date.day}',
                  onTap: () => context.push(AppRouter.moodHistory, extra: date),
                );
              }),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onStreak,
                  icon: const Icon(Icons.local_fire_department_outlined),
                  label: Text('$streak day streak'),
                ),
                TextButton(
                  onPressed: () => context.push(
                    weeklyCount == 0
                        ? AppRouter.moodFeeling
                        : AppRouter.insights,
                  ),
                  child: Text(
                    weeklyCount == 0
                        ? 'No moods this week'
                        : 'Avg intensity ${(weeklyIntensityTotal / weeklyCount).toStringAsFixed(1)}',
                  ),
                ),
              ],
            ),
            if (entries.isEmpty)
              TextButton(
                onPressed: () => context.push(AppRouter.moodFeeling),
                child: const Text('Start your streak'),
              ),
            if (weeklyCount < 3)
              Text(
                'Log 3 moods to see trends',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            Text('Recent entries', style: theme.textTheme.titleSmall),
            if (recentEntries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Your first entry will show here'),
              )
            else
              for (final entry in recentEntries.take(3))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    entry.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(entry.mood),
                  subtitle: Text(
                    '${entry.createdAt.toLocal().month}/${entry.createdAt.toLocal().day}, ${TimeOfDay.fromDateTime(entry.createdAt.toLocal()).format(context)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRouter.moodDetail, extra: entry),
                ),
            TextButton(
              onPressed: () => context.push(AppRouter.moodHistory),
              child: const Text('View Log ›'),
            ),
          ],
        ),
      ),
    );
  }
}
