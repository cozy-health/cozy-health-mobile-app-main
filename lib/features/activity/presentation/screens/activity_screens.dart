import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_scaffold_padding.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final List<String> _periods = const ['Week', 'Month', '3 Months', 'Year'];
  int _selectedPeriod = 0;

  @override
  Widget build(BuildContext context) {
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
              tooltip: 'Open calendar',
              onPressed: () {},
              icon: Icon(
                Icons.calendar_today_rounded,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
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
            periods: _periods,
            selectedIndex: _selectedPeriod,
            onSelected: (index) => setState(() => _selectedPeriod = index),
          ),
          const SizedBox(height: 20),
          _MoodSummaryCard(period: _periods[_selectedPeriod]),
          const SizedBox(height: 16),
          const _StatsRow(),
          const SizedBox(height: 24),
          Text(
            'General insights',
            style: AppTextStyles.heading2.copyWith(color: textColor),
          ),
          const SizedBox(height: 12),
          _InsightCard(
            icon: Icons.favorite_rounded,
            title: 'Mood check-ins',
            subtitle: '5 check-ins this week',
            body: const _CheckInDots(filledCount: 5),
            actionLabel: 'View log',
            onAction: () {},
          ),
          const SizedBox(height: 12),
          _InsightCard(
            icon: Icons.edit_note_rounded,
            title: 'Writing',
            subtitle: '4 journaling days',
            body: const _WritingDays(),
            actionLabel: 'Open journal',
            onAction: () {},
          ),
          const SizedBox(height: 12),
          const _TriggerCard(),
          const SizedBox(height: 24),
          Text(
            'Recommended for you',
            style: AppTextStyles.heading2.copyWith(color: textColor),
          ),
          const SizedBox(height: 12),
          const _RecommendationGrid(),
        ],
      ),
    );
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
  const _MoodSummaryCard({required this.period});

  final String period;

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
                      'Mood for the $period',
                      style: AppTextStyles.heading2.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mostly steady, with one low-energy dip.',
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
          const SizedBox(
            height: 144,
            child: CustomPaint(
              painter: _MoodChartPainter(),
              size: Size(double.infinity, 144),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.show_chart_rounded,
            value: '+18%',
            label: 'Mood trend',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            value: '4 days',
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
  const _WritingDays();

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final colorScheme = Theme.of(context).colorScheme;
    final mutedColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (index) {
        final isFilled = index < 4;

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
  const _TriggerCard();

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
              TextButton(onPressed: () {}, child: const Text('Details')),
            ],
          ),
          const SizedBox(height: 12),
          const _TriggerItem(
            label: 'Work stress',
            value: .64,
            impact: 'Medium impact',
          ),
          const SizedBox(height: 14),
          const _TriggerItem(
            label: 'Exam stress',
            value: .80,
            impact: 'High impact',
          ),
          const SizedBox(height: 14),
          const _TriggerItem(
            label: 'Poor sleep',
            value: .75,
            impact: 'Medium impact',
          ),
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
  const _RecommendationGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: .92,
      children: const [
        _RecommendationCard(
          icon: Icons.self_improvement_rounded,
          title: 'Grounding practice for anxious days',
        ),
        _RecommendationCard(
          icon: Icons.bedtime_rounded,
          title: 'Sleep reset and wind-down routine',
        ),
        _RecommendationCard(
          icon: Icons.directions_walk_rounded,
          title: 'Movement ideas for low energy',
        ),
        _RecommendationCard(
          icon: Icons.spa_rounded,
          title: 'Reflecting with gratitude prompts',
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _ActivityCard(
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
  const _MoodChartPainter();

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

    final points = [
      Offset(0, size.height * .58),
      Offset(size.width * .16, size.height * .44),
      Offset(size.width * .33, size.height * .62),
      Offset(size.width * .50, size.height * .36),
      Offset(size.width * .68, size.height * .28),
      Offset(size.width * .84, size.height * .46),
      Offset(size.width, size.height * .32),
    ];

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
