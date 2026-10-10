import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/chart_container.dart';
import '../widgets/local_insights.dart';

class MoodTrendScreen extends StatefulWidget {
  const MoodTrendScreen({super.key});

  @override
  State<MoodTrendScreen> createState() => _MoodTrendScreenState();
}

class _MoodTrendScreenState extends State<MoodTrendScreen>
    with SingleTickerProviderStateMixin {
  String _selectedRange = '7 days';
  int get _days => int.parse(_selectedRange.split(' ').first);
  List<Map<String, dynamic>> get _daily => LocalInsights.daily(days: _days);
  String _extreme(bool highest) {
    if (_daily.isEmpty) return '\u2014';
    final rows = [..._daily]
      ..sort(
        (a, b) =>
            (a['avg_intensity'] as num).compareTo(b['avg_intensity'] as num),
      );
    final row = highest ? rows.last : rows.first;
    return "${(row['avg_intensity'] as num).toStringAsFixed(1)} on ${(row['day'] as String).substring(5)}";
  }

  late AnimationController _controller;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _chartAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changeRange(String range) {
    if (_selectedRange == range) return;
    setState(() {
      _selectedRange = range;
    });
    _controller.reset();
    _controller.forward();
  }

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
          'Mood trend',
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
              // Range Selector
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: ['7 days', '30 days', '90 days'].map((range) {
                    final isSelected = _selectedRange == range;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _changeRange(range),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            range,
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 32),

              // Chart
              if (LocalInsights.moods(days: _days).length < 3)
                const Text('Log 3 moods to see trends'),
              if (_daily.isNotEmpty)
                ChartContainer(
                  title: 'Mood trend ($_selectedRange)',
                  accessibleLabel: 'Mood trend chart for $_selectedRange',
                  tableColumns: const [
                    DataColumn(label: Text('Day')),
                    DataColumn(label: Text('Mood')),
                  ],
                  tableRows: _daily
                      .map(
                        (row) => DataRow(
                          cells: [
                            DataCell(Text(row['day'] as String)),
                            DataCell(
                              Text(
                                (row['avg_intensity'] as num).toStringAsFixed(
                                  1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                  chart: AnimatedBuilder(
                    animation: _chartAnimation,
                    builder: (context, child) {
                      return _buildAreaChart();
                    },
                  ),
                ),
              SizedBox(height: 32),

              // Summary Card
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
                    Text(
                      _selectedRange == '7 days' ? 'This week' : 'This period',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 16),
                    _buildSummaryRow(
                      'Average:',
                      '${LocalInsights.averageText(days: _days)} / 10',
                    ),
                    SizedBox(height: 8),
                    _buildSummaryRow('Highest daily avg:', _extreme(true)),
                    SizedBox(height: 8),
                    _buildSummaryRow('Lowest daily avg:', _extreme(false)),
                    SizedBox(height: 24),
                    Text(
                      'Your saved mood entries show patterns over time.',
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.body1.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8),
        Text(
          value,
          style: AppTextStyles.body1.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaChart() {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: _MoodAreaChartPainter(
              data: _daily
                  .map((row) => (row['avg_intensity'] as num).toDouble())
                  .toList(),
              animationValue: _chartAnimation.value,
            ),
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _daily
              .map((row) => (row['day'] as String).substring(5))
              .map((day) {
                return Text(
                  day,
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSubtleDark
                        : AppColors.textSubtleLight,
                    fontSize: 12,
                  ),
                );
              })
              .toList(),
        ),
      ],
    );
  }
}

class _MoodAreaChartPainter extends CustomPainter {
  final List<double> data;
  final double animationValue;

  _MoodAreaChartPainter({required this.data, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
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

      // Draw up to animation progress
      final currentProgress = (i) / (data.length - 1);
      if (currentProgress <= animationValue) {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      } else {
        // Interpolate last point
        final prevProgress = (i - 1) / (data.length - 1);
        final segmentProgress =
            (animationValue - prevProgress) / (currentProgress - prevProgress);

        final prevX = (i - 1) * pointWidth;
        final prevY = size.height - (data[i - 1] / maxData) * size.height;

        final interpX = prevX + (x - prevX) * segmentProgress;
        final interpY = prevY + (y - prevY) * segmentProgress;

        path.lineTo(interpX, interpY);
        areaPath.lineTo(interpX, interpY);
        break;
      }
    }

    // Close area path
    if (animationValue > 0) {
      final lastX = size.width * animationValue;
      areaPath.lineTo(lastX, size.height);
      areaPath.close();

      // Draw horizontal grid lines
      final gridPaint = Paint()
        ..color = AppColors.border.withValues(alpha: 0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      for (int i = 1; i < 5; i++) {
        final y = size.height * (i / 5);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }

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

      // Gradient line based on mood intensity
      final linePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFD9C7B8), // Very low
            const Color(0xFFE8B89D), // Low
            const Color(0xFFF5C318), // Medium
            const Color(0xFF8DB8A8), // Good
            const Color(0xFF2D9E54), // Very good
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);

      // Draw points
      if (animationValue == 1.0) {
        final pointPaint = Paint()
          ..color = AppColors.surface
          ..style = PaintingStyle.fill;
        final pointStroke = Paint()
          ..color = AppColors.primary
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < data.length; i++) {
          final x = i * pointWidth;
          final y = size.height - (data[i] / maxData) * size.height;
          canvas.drawCircle(Offset(x, y), 5, pointPaint);
          canvas.drawCircle(Offset(x, y), 5, pointStroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MoodAreaChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.data != data ||
        oldDelegate.data != data;
  }
}
