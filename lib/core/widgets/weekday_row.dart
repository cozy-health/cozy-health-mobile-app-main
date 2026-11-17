import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

@immutable
class WeekdayItem {
  final String label;
  final bool filled;
  final Color? color;
  final Widget? indicator;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const WeekdayItem({
    required this.label,
    this.filled = false,
    this.color,
    this.indicator,
    this.onTap,
    this.semanticLabel,
  });
}

/// Seven caller-supplied day statuses; this widget does not calculate dates.
class WeekdayRow extends StatelessWidget {
  final List<WeekdayItem> days;
  final Color? indicatorColor;

  const WeekdayRow({
    super.key,
    this.days = const [
      WeekdayItem(label: 'Mon'),
      WeekdayItem(label: 'Tue'),
      WeekdayItem(label: 'Wed'),
      WeekdayItem(label: 'Thur'),
      WeekdayItem(label: 'Fri'),
      WeekdayItem(label: 'Sat'),
      WeekdayItem(label: 'Sun'),
    ],
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    assert(days.length == 7, 'WeekdayRow requires exactly seven day items.');
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Material(
      type: MaterialType.transparency,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final day in days)
            Expanded(
              child: Semantics(
                label: day.semanticLabel ?? day.label,
                value: day.filled ? 'Recorded' : 'Not recorded',
                button: day.onTap != null,
                onTap: day.onTap,
                child: InkWell(
                  onTap: day.onTap,
                  excludeFromSemantics: true,
                  borderRadius: BorderRadius.circular(8),
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: day.filled
                                  ? day.color ?? theme.colorScheme.primary
                                  : null,
                              border: day.filled
                                  ? null
                                  : Border.all(
                                      color:
                                          day.color ??
                                          (dark
                                              ? AppColors.borderDefaultDark
                                              : AppColors.borderDefault),
                                    ),
                            ),
                            child: day.indicator == null
                                ? null
                                : Center(
                                    child: IconTheme.merge(
                                      data: IconThemeData(
                                        size: 11,
                                        color:
                                            indicatorColor ??
                                            (day.filled
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.primary),
                                      ),
                                      child: day.indicator!,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            day.label,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
