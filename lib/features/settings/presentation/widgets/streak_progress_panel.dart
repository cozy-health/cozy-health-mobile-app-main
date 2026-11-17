import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/models/streak_progress.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../data/wellness_progress.dart';

class StreakProgressPanel extends StatelessWidget {
  const StreakProgressPanel({super.key, required this.progress, this.streak});
  final WellnessProgress progress;
  final StreakProgress? streak;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context),
        c = t.colorScheme,
        w = context.cozyColors.wellness;
    final current = streak?.currentDays ?? progress.current;
    final best = streak?.bestDays ?? progress.longest;
    final week = streak?.week ?? progress.week;
    bool checked(DateTime day) =>
        streak?.completedDates.contains(streakDate(day)) ??
        progress.checkedDays.contains(day);
    bool rested(DateTime day) =>
        streak?.protectedDates.contains(streakDate(day)) ?? false;
    return WellnessPanel(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.local_fire_department_outlined,
            color: wellnessAccentInk(context, background: w.accentPanel(c)),
            size: 32,
          ),
          SizedBox(height: w.contentGap),
          Text(
            '$current ${current == 1 ? 'day' : 'days'}',
            style: t.textTheme.headlineLarge,
          ),
          Text('Current check-in streak', style: t.textTheme.titleMedium),
          SizedBox(height: w.contentGap),
          Text(
            (streak?.todayCompleted ?? progress.checkedToday)
                ? 'You made space for a check-in today.'
                : 'Your next check-in is here whenever you’re ready.',
          ),
          if (streak != null) ...[
            SizedBox(height: w.small),
            Text('${streak!.restDays} of 2 rest days saved'),
            if (streak!.estimated)
              const Text(
                'Estimated from this device. Progress will be confirmed after sync.',
              ),
          ],
          SizedBox(height: w.gap),
          Text('Last seven days', style: t.textTheme.titleSmall),
          SizedBox(height: w.contentGap),
          LayoutBuilder(
            builder: (context, box) {
              final columns =
                  MediaQuery.textScalerOf(context).scale(12) > 18 ||
                      box.maxWidth < 280
                  ? 4
                  : 7;
              final dayWidth =
                  (box.maxWidth - (columns - 1) * w.small) / columns;
              return Wrap(
                spacing: w.small,
                runSpacing: w.contentGap,
                children: [
                  for (final day in week)
                    Semantics(
                      label:
                          '${DateFormat.yMMMMd().format(day)}, ${rested(day)
                              ? 'rest day used'
                              : checked(day)
                              ? 'checked in'
                              : 'no check-in'}',
                      child: ExcludeSemantics(
                        child: SizedBox(
                          width: dayWidth,
                          child: Column(
                            children: [
                              Text(
                                DateFormat.E().format(day),
                                style: t.textTheme.labelSmall,
                              ),
                              SizedBox(height: w.tight),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: checked(day) ? c.primary : c.surface,
                                  border: Border.all(color: c.outlineVariant),
                                ),
                                alignment: Alignment.center,
                                child: rested(day)
                                    ? Icon(
                                        Icons.nightlight_outlined,
                                        color: c.onSurface,
                                        size: 20,
                                      )
                                    : checked(day)
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: c.onPrimary,
                                        size: 20,
                                      )
                                    : Text(
                                        '${day.day}',
                                        style: t.textTheme.labelMedium,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: w.gap),
          Text(
            'Best streak: $best ${best == 1 ? 'day' : 'days'}',
            style: t.textTheme.titleSmall,
          ),
          SizedBox(height: w.tight),
          const Text(
            'One check-in per calendar day counts. Taking a break never removes an earned milestone.',
          ),
        ],
      ),
    );
  }
}
