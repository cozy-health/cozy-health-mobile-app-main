import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/insight_card.dart';
import '../widgets/chart_container.dart';
import '../widgets/local_insights.dart';

class ActivityMoodScreen extends StatefulWidget {
  const ActivityMoodScreen({super.key});

  @override
  State<ActivityMoodScreen> createState() => _ActivityMoodScreenState();
}

class _ActivityMoodScreenState extends State<ActivityMoodScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Map<String, dynamic>> get _daily => LocalInsights.daily();
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
        title: Text('Activity & mood', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InsightCard(
                icon: '📓',
                title: 'Your journaling and\nmood patterns.',
              ),
              SizedBox(height: 32),

              if (LocalInsights.moods().length < 3)
                const Text('Log 3 moods to see trends'),
              if (_daily.isNotEmpty)
                ChartContainer(
                  title: 'Activity & Mood Correlation',
                  accessibleLabel:
                      'Chart showing correlation between journaling activity and mood over 7 days',
                  tableColumns: const [
                    DataColumn(label: Text('Day')),
                    DataColumn(label: Text('Activity')),
                    DataColumn(label: Text('Mood')),
                  ],
                  tableRows: _daily
                      .asMap()
                      .entries
                      .map(
                        (entry) => DataRow(
                          cells: [
                            DataCell(Text(entry.value['day'] as String)),
                            DataCell(
                              Text(
                                LocalInsights.activity(
                                  _daily,
                                )[entry.key].toInt().toString(),
                              ),
                            ),
                            DataCell(
                              Text(
                                (entry.value['avg_intensity'] as num)
                                    .toStringAsFixed(1),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                  legend: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(
                        'Activity',
                        const Color(0xFFE85D3A),
                        true,
                      ),
                      SizedBox(width: 24),
                      _buildLegendItem(
                        'Mood',
                        Theme.of(context).colorScheme.primary,
                        false,
                      ),
                    ],
                  ),
                  chart: AnimatedBuilder(
                    animation: _chartAnimation,
                    builder: (context, child) {
                      return _buildDualLineChart();
                    },
                  ),
                ),

              SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What we noticed', style: AppTextStyles.heading2),
                    SizedBox(height: 16),
                    Text(
                      LocalInsights.activityComparison(),
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'You journaled ${LocalInsights.journals().length} times in the last 7 days.',
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 2,
          color: isDashed ? Colors.transparent : color,
          child: isDashed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    3,
                    (_) => Container(width: 4, height: 2, color: color),
                  ),
                )
              : null,
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDualLineChart() {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: _DualLineChartPainter(
              moodData: _daily
                  .map((row) => (row['avg_intensity'] as num).toDouble())
                  .toList(),
              activityData: LocalInsights.activity(_daily),
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

class _DualLineChartPainter extends CustomPainter {
  final List<double> moodData;
  final List<double> activityData;
  final double animationValue;

  _DualLineChartPainter({
    required this.moodData,
    required this.activityData,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (moodData.isEmpty || activityData.isEmpty) return;

    final double maxData = 10;
    final double pointWidth =
        size.width / (moodData.length > 1 ? moodData.length - 1 : 1);

    // Grid
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 1; i < 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawActivityLine(canvas, size, maxData, pointWidth);
    _drawMoodLine(canvas, size, maxData, pointWidth);
  }

  void _drawActivityLine(
    Canvas canvas,
    Size size,
    double maxData,
    double pointWidth,
  ) {
    final path = Path();
    path.moveTo(0, size.height - (activityData[0] / maxData) * size.height);

    for (int i = 1; i < activityData.length; i++) {
      final x = i * pointWidth;
      final y = size.height - (activityData[i] / maxData) * size.height;

      final currentProgress = (i) / (activityData.length - 1);
      if (currentProgress <= animationValue) {
        path.lineTo(x, y);
      } else {
        final prevProgress = (i - 1) / (activityData.length - 1);
        final segmentProgress =
            (animationValue - prevProgress) / (currentProgress - prevProgress);
        final prevX = (i - 1) * pointWidth;
        final prevY =
            size.height - (activityData[i - 1] / maxData) * size.height;
        path.lineTo(
          prevX + (x - prevX) * segmentProgress,
          prevY + (y - prevY) * segmentProgress,
        );
        break;
      }
    }

    // Dashed path
    final dashPath = Path();
    double dashWidth = 5.0;
    double dashSpace = 5.0;
    double distance = 0.0;

    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }

    final activityPaint = Paint()
      ..color = const Color(0xFFE85D3A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(dashPath, activityPaint);
  }

  void _drawMoodLine(
    Canvas canvas,
    Size size,
    double maxData,
    double pointWidth,
  ) {
    final path = Path();
    path.moveTo(0, size.height - (moodData[0] / maxData) * size.height);

    for (int i = 1; i < moodData.length; i++) {
      final x = i * pointWidth;
      final y = size.height - (moodData[i] / maxData) * size.height;

      final currentProgress = (i) / (moodData.length - 1);
      if (currentProgress <= animationValue) {
        path.lineTo(x, y);
      } else {
        final prevProgress = (i - 1) / (moodData.length - 1);
        final segmentProgress =
            (animationValue - prevProgress) / (currentProgress - prevProgress);
        final prevX = (i - 1) * pointWidth;
        final prevY = size.height - (moodData[i - 1] / maxData) * size.height;
        path.lineTo(
          prevX + (x - prevX) * segmentProgress,
          prevY + (y - prevY) * segmentProgress,
        );
        break;
      }
    }

    final moodPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFD9C7B8),
          const Color(0xFFE8B89D),
          const Color(0xFFF5C318),
          const Color(0xFF8DB8A8),
          const Color(0xFF2D9E54),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, moodPaint);
  }

  @override
  bool shouldRepaint(covariant _DualLineChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.moodData != moodData ||
        oldDelegate.activityData != activityData;
  }
}
