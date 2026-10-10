import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/local_insights.dart';
import 'package:intl/intl.dart';

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Monthly report',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () {},
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime.now()),
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              SizedBox(height: 24),

              Text(
                'Your month,\nat your pace.',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 32),

              // Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      context,
                      LocalInsights.moods(month: true).length.toString(),
                      'entries',
                    ),
                    SizedBox(height: 12),
                    _buildStatRow(
                      context,
                      LocalInsights.averageText(month: true),
                      'avg intensity',
                    ),
                    SizedBox(height: 12),
                    _buildStatRow(
                      context,
                      LocalInsights.averageSleep(
                            month: true,
                          )?.toStringAsFixed(1) ??
                          '\u2014',
                      'avg sleep (1-5)',
                    ),
                    SizedBox(height: 12),
                    _buildStatRow(
                      context,
                      '${LocalInsights.longestStreak()}-day',
                      'longest streak',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Full width chart
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood trend over the month',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (LocalInsights.moods(month: true).length < 3)
                      const Text('Log 3 moods to see trends'),
                    SizedBox(
                      height: 120,
                      child: CustomPaint(
                        size: const Size(double.infinity, double.infinity),
                        painter: _MonthlyAreaChartPainter(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Top Triggers
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top triggers',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      LocalInsights.topTriggers(),
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // What helped
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What helped',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      LocalInsights.moods(month: true)
                              .expand(
                                (entry) => entry.copingStrategies ?? <String>[],
                              )
                              .toSet()
                              .join(', ')
                              .isEmpty
                          ? 'No coping strategies logged yet.'
                          : LocalInsights.moods(month: true)
                                .expand(
                                  (entry) =>
                                      entry.copingStrategies ?? <String>[],
                                )
                                .toSet()
                                .join(', '),
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              AppButton(
                text: 'Export for provider',
                trailingIcon: Icons.description_outlined,
                onPressed: () {
                  // Trigger export
                },
              ),
              SizedBox(height: 16),
              AppButton(
                text: 'Download PDF',
                trailingIcon: Icons.download_outlined,
                isOutlined: true,
                onPressed: () {
                  // Trigger download
                },
              ),
              SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.body1.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MonthlyAreaChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final data = LocalInsights.daily(
      month: true,
    ).map((row) => (row['avg_intensity'] as num).toDouble()).toList();
    if (data.isEmpty) return;

    final double maxData = 10;
    final double pointWidth =
        size.width / (data.length > 1 ? data.length - 1 : 1);

    final path = Path();
    final areaPath = Path();

    areaPath.moveTo(0, size.height);
    path.moveTo(0, size.height - (data[0] / maxData) * size.height);
    areaPath.lineTo(0, size.height - (data[0] / maxData) * size.height);

    for (int i = 1; i < data.length; i++) {
      final x = i * pointWidth;
      final y = size.height - (data[i] / maxData) * size.height;

      path.lineTo(x, y);
      areaPath.lineTo(x, y);
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    // Fill gradient
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.2),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, paint);

    // Line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MonthlyAreaChartPainter oldDelegate) => true;
}
