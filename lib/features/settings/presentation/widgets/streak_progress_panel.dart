import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../data/wellness_progress.dart';

class StreakProgressPanel extends StatelessWidget {
  const StreakProgressPanel({super.key, required this.progress});
  final WellnessProgress progress;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context),
        c = t.colorScheme,
        w = context.cozyColors.wellness;
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
            '${progress.current} ${progress.current == 1 ? 'day' : 'days'}',
            style: t.textTheme.headlineLarge,
          ),
          Text('Current check-in streak', style: t.textTheme.titleMedium),
          SizedBox(height: w.contentGap),
          Text(
            progress.checkedToday
                ? 'You made space for a check-in today.'
                : 'Your next check-in is here whenever you’re ready.',
          ),
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
                  for (final day in progress.week)
                    Semantics(
                      label:
                          '${DateFormat.yMMMMd().format(day)}, ${progress.checkedDays.contains(day) ? 'checked in' : 'no check-in'}',
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
                                  color: progress.checkedDays.contains(day)
                                      ? c.primary
                                      : c.surface,
                                  border: Border.all(color: c.outlineVariant),
                                ),
                                alignment: Alignment.center,
                                child: progress.checkedDays.contains(day)
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
            'Best streak: ${progress.longest} ${progress.longest == 1 ? 'day' : 'days'}',
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
