import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/models/streak_progress.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/mood_artwork.dart';

class HomeDesignCard extends StatelessWidget {
  const HomeDesignCard({super.key, required this.child, this.color});
  final Widget child;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), t = context.cozyColors.wellness;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(t.gap),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(t.radius),
        border: Border.all(
          color: MediaQuery.highContrastOf(context)
              ? theme.colorScheme.onSurface
              : theme.colorScheme.outlineVariant,
          width: MediaQuery.highContrastOf(context) ? 2 : 1,
        ),
      ),
      child: child,
    );
  }
}

class HomeRhythmCard extends StatelessWidget {
  const HomeRhythmCard({
    super.key,
    required this.entries,
    required this.streak,
    required this.hasMoodToday,
    required this.onStreak,
    this.now,
    this.progress,
  });
  final List<MoodEntry> entries;
  final int streak;
  final bool hasMoodToday;
  final VoidCallback onStreak;
  final DateTime? now;
  final StreakProgress? progress;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), t = context.cozyColors.wellness;
    final current = progress == null
        ? (now ?? DateTime.now()).toLocal()
        : DateTime.parse(progress!.localDate);
    final today = progress == null
        ? DateTime(current.year, current.month, current.day)
        : DateTime.utc(current.year, current.month, current.day);
    final recordedToday =
        progress?.todayCompleted ??
        (hasMoodToday ||
            entries.any((entry) {
              final date = entry.createdAt.toLocal();
              return date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
            }));
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final action = context.cozyColors.recording.controlColor(
      theme.colorScheme.primary,
      theme.colorScheme.surface,
      theme.colorScheme.onSurface,
    );
    final days =
        progress?.week ??
        [
          for (var i = 6; i >= 0; i--)
            DateTime(today.year, today.month, today.day - i),
        ];
    return HomeDesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPressable(
            label: '$streak day streak. View streak',
            onPressed: onStreak,
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: context.cozyColors.triggerMed,
                  size: t.streakIcon,
                ),
                SizedBox(width: t.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streak day streak',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        progress?.estimated == true
                            ? 'Saved on this device. Waiting to confirm progress.'
                            : 'A little consistency. A little more you.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: t.gap),
          const Text('Your last 7 days'),
          SizedBox(height: t.small),
          LayoutBuilder(
            builder: (context, box) {
              final large =
                  MediaQuery.textScalerOf(context).scale(t.label) > 20;
              final columns = large ? 4 : 7;
              final width =
                  (box.maxWidth - (columns - 1) * t.small / 2) / columns;
              return Wrap(
                spacing: t.small / 2,
                runSpacing: t.small,
                children: [
                  for (final day in days)
                    Builder(
                      builder: (context) {
                        final matches =
                            entries.where((entry) {
                              if (progress != null &&
                                  !progress!.completedDates.contains(
                                    streakDate(day),
                                  )) {
                                return false;
                              }
                              final originalDate =
                                  progress?.creditedSources[entry.id];
                              final date =
                                  (originalDate == null
                                      ? progress?.dayAt(entry.createdAt)
                                      : DateTime.parse(originalDate)) ??
                                  entry.createdAt.toLocal();
                              return date.year == day.year &&
                                  date.month == day.month &&
                                  date.day == day.day;
                            }).toList()..sort(
                              (a, b) => b.createdAt.compareTo(a.createdAt),
                            );
                        final latest = matches.firstOrNull;
                        final saved =
                            latest != null || day == today && recordedToday;
                        final isToday = day == today;
                        final dateLabel = streakDate(day);
                        final rested =
                            progress?.protectedDates.contains(dateLabel) ??
                            false;
                        final pending =
                            progress?.pendingDates.contains(dateLabel) ?? false;
                        final completed =
                            saved ||
                            (progress?.completedDates.contains(dateLabel) ??
                                false);
                        final status = pending
                            ? 'check-in waiting to sync'
                            : rested
                            ? 'rest day used'
                            : latest?.displayFeeling ??
                                  (completed ? 'check-in saved' : 'no entry');
                        return SizedBox(
                          width: width,
                          child: Semantics(
                            excludeSemantics: true,
                            key: ValueKey(
                              'rhythm-day-${day.toIso8601String()}',
                            ),
                            label:
                                '${weekdays[day.weekday - 1]}, ${day.day}/${day.month}, $status${isToday ? ', today' : ''}',
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: t.small),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? context.cozyColors.wellness.accentPanel(
                                        theme.colorScheme,
                                      )
                                    : theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(
                                  t.tileRadius,
                                ),
                                border: Border.all(
                                  color: isToday
                                      ? action
                                      : MediaQuery.highContrastOf(context)
                                      ? theme.colorScheme.outline
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    weekdays[day.weekday - 1],
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  SizedBox(height: t.small),
                                  if (latest != null &&
                                      MoodArtwork.assetFor(latest.mood) != null)
                                    MoodArtwork(
                                      mood: latest.mood,
                                      size: t.section,
                                    )
                                  else
                                    SizedBox(
                                      height: t.section,
                                      child: Center(
                                        child: rested
                                            ? Icon(
                                                Icons.nightlight_outlined,
                                                color: action,
                                                size: t.section,
                                              )
                                            : completed
                                            ? Icon(
                                                Icons.check_circle_outline,
                                                color: action,
                                                size: t.section,
                                              )
                                            : const Text('—'),
                                      ),
                                    ),
                                  SizedBox(height: t.small),
                                  Text(
                                    '${day.day}',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
          SizedBox(height: t.small),
          Text(
            recordedToday
                ? 'Your check-in is saved for today.'
                : 'A small check-in can be a place to start.',
          ),
          SizedBox(height: t.small),
          LayoutBuilder(
            builder: (context, box) {
              Widget actionButton(String label, String route) => AppPressable(
                label: label,
                onPressed: () => context.push(route),
                child: Container(
                  constraints: BoxConstraints(minHeight: t.touch),
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(
                    horizontal: t.small,
                    vertical: t.small,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(t.tileRadius),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: action,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
              if (MediaQuery.textScalerOf(context).scale(t.label) > 20 ||
                  box.maxWidth < t.breakpoint) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    actionButton('View mood log', AppRouter.moodHistory),
                    SizedBox(height: t.small),
                    actionButton('View insights', AppRouter.insights),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: actionButton('View mood log', AppRouter.moodHistory),
                  ),
                  SizedBox(width: t.small),
                  Expanded(
                    child: actionButton('View insights', AppRouter.insights),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class HomeFeatureCards extends StatelessWidget {
  const HomeFeatureCards({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), t = context.cozyColors.wellness;
    final action = context.cozyColors.recording.controlColor(
      theme.colorScheme.primary,
      theme.colorScheme.surface,
      theme.colorScheme.onSurface,
    );
    Widget card(bool journal, {bool paired = false, double titleHeight = 0}) =>
        AppPressable(
          label: journal
              ? 'Your journal. Start journaling'
              : 'Well-being check. Take a quiz',
          onPressed: () => context.push(
            journal ? AppRouter.journal : AppRouter.quizSelection,
          ),
          child: HomeDesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: t.small),
                SizedBox(
                  height: t.tileHeight,
                  width: double.infinity,
                  child: journal
                      ? SvgPicture.asset(
                          'assets/svg/journaling.svg',
                          excludeFromSemantics: true,
                        )
                      : Image.asset(
                          'assets/png/home_quiz_brain.png',
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                ),
                SizedBox(height: t.small),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: titleHeight),
                  child: Text(
                    journal ? 'Your journal' : 'Well-being check',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: t.tight),
                Text(
                  journal
                      ? 'Write or record what’s on your mind.'
                      : 'Take a quick self-assessment at your own pace.',
                ),
                if (paired) const Spacer(),
                SizedBox(height: t.contentGap),
                Text(
                  journal ? 'Start journaling →' : 'Take a quiz →',
                  style: TextStyle(color: action, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < t.breakpoint ||
            MediaQuery.textScalerOf(context).scale(t.label) > 20) {
          return Column(
            children: [
              card(true),
              SizedBox(height: t.gap),
              card(false),
            ],
          );
        }
        final titleWidth = (box.maxWidth - t.small) / 2 - t.gap * 2 - 2;
        double measure(String text) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: titleWidth);
          final height = painter.height;
          painter.dispose();
          return height;
        }

        final titleHeight = [
          measure('Your journal'),
          measure('Well-being check'),
        ].reduce((a, b) => a > b ? a : b);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: card(true, paired: true, titleHeight: titleHeight),
              ),
              SizedBox(width: t.small),
              Expanded(
                child: card(false, paired: true, titleHeight: titleHeight),
              ),
            ],
          ),
        );
      },
    );
  }
}
