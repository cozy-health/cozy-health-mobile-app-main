import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/insight_card.dart';
import '../widgets/stat_card.dart';

class InsightsHomeScreen extends StatefulWidget {
  const InsightsHomeScreen({super.key});

  @override
  State<InsightsHomeScreen> createState() => _InsightsHomeScreenState();
}

class _InsightsHomeScreenState extends State<InsightsHomeScreen>
    with SingleTickerProviderStateMixin {
  // We'll use a staggered animation for the elements
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _createAnimation(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 0ms - 400ms: Header
    final headerAnim = _createAnimation(0.0, 0.26);
    // 100ms - 500ms: Subtext
    final subtextAnim = _createAnimation(0.06, 0.33);
    // 200ms - 800ms: Hero Card
    final heroCardAnim = _createAnimation(0.13, 0.53);
    // 400ms - 900ms: Stats
    final statsAnim = _createAnimation(0.26, 0.6);
    // 800ms - 1200ms: Section 1
    final section1Anim = _createAnimation(0.53, 0.8);
    // 1000ms - 1400ms: Mini chart (approximated)
    final chartAnim = _createAnimation(0.66, 0.93);
    // 1400ms - 1500ms: Section 2
    final section2Anim = _createAnimation(0.93, 1.0);

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
        title: Text('Insights', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: headerAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(headerAnim),
                  child: Text(
                    'This week',
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              FadeTransition(
                opacity: subtextAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(subtextAnim),
                  child: Text(
                    'You felt calmer than last week.',
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              FadeTransition(
                opacity: heroCardAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(heroCardAnim),
                  child: const InsightCard(
                    icon: '🌿',
                    title: 'Your best day was\nThursday.',
                    subtitle: 'You logged 7 entries this week.',
                  ),
                ),
              ),
              SizedBox(height: 16),
              FadeTransition(
                opacity: statsAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(statsAnim),
                  child: Row(
                    children: [
                      const Expanded(
                        child: StatCard(value: '7', label: 'Entries'),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          value: '6.2',
                          label: 'Avg mood',
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(
                            alpha: 0.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              FadeTransition(
                opacity: statsAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(statsAnim),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(value: 'Work', label: 'Top trigger'),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: StatCard(value: '7.5', label: 'Avg sleep'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              FadeTransition(
                opacity: section1Anim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mood trend', style: AppTextStyles.heading2),
                    TextButton(
                      onPressed: () => context.push(
                        AppRouter.insightsMoodTrend,
                      ), // To be added
                      child: Text(
                        'See all',
                        style: AppTextStyles.body2.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              FadeTransition(
                opacity: chartAnim,
                child: GestureDetector(
                  onTap: () =>
                      context.push(AppRouter.insightsMoodTrend), // To be added
                  child: _buildMiniChart(),
                ),
              ),
              SizedBox(height: 32),
              FadeTransition(
                opacity: section2Anim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'What\'s affecting your mood',
                      style: AppTextStyles.heading2,
                    ),
                    TextButton(
                      onPressed: () => context.push(
                        AppRouter.insightsTriggers,
                      ), // To be added
                      child: Text(
                        'See all',
                        style: AppTextStyles.body2.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              FadeTransition(
                opacity: section2Anim,
                child: Column(
                  children: [
                    _buildMiniTrigger('Work', '4 times', 0.8),
                    SizedBox(height: 8),
                    _buildMiniTrigger('Sleep', '3 times', 0.6),
                  ],
                ),
              ),
              SizedBox(height: 32),
              // Monthly Report button (Bonus)
              FadeTransition(
                opacity: section2Anim,
                child: Center(
                  child: TextButton(
                    onPressed: () =>
                        context.push(AppRouter.insightsMonthlyReport),
                    child: Text(
                      'View Monthly Report',
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChart() {
    return Container(
      height: 120,
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _MiniAreaChartPainter(
                data: [4, 5, 4, 8, 7, 6, 7],
                color: Theme.of(context).colorScheme.primary,
                animationValue: 1.0, // Simplified for mini chart
              ),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Text(
                day,
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSubtleDark
                      : AppColors.textSubtleLight,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTrigger(String title, String frequency, double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: constraints.maxWidth * progress,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 16),
          Text(
            frequency,
            style: AppTextStyles.body2.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAreaChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double animationValue;

  _MiniAreaChartPainter({
    required this.data,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxData = 10;
    final double pointWidth = size.width / (data.length - 1);

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

      // Draw area
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, paint);

      // Draw line
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniAreaChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
