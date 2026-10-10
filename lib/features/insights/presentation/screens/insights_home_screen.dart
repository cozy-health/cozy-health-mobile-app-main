import '../../../../core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/repositories/mood_repository.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/insight_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/insights_feed.dart';
import '../widgets/local_insights.dart';

class InsightsHomeScreen extends StatefulWidget {
  const InsightsHomeScreen({super.key});

  @override
  State<InsightsHomeScreen> createState() => _InsightsHomeScreenState();
}

class _InsightsHomeScreenState extends State<InsightsHomeScreen>
    with SingleTickerProviderStateMixin {
  // We'll use a staggered animation for the elements
  late AnimationController _controller;
  final _feed = InsightsFeed();
  StreamSubscription<List<MoodEntry>>? _moodSubscription;
  void _refresh() {
    if (mounted) setState(() {});
  }

  bool _monthly = false;
  List<Map<String, dynamic>> get _daily => LocalInsights.daily(month: _monthly);
  Map<String, dynamic>? get _week {
    if (_monthly) {
      final entries = LocalInsights.moods(month: true);
      if (entries.isEmpty) return null;
      final counts = <String, int>{};
      for (final entry in entries) {
        counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
      }
      final names = counts.keys.toList()
        ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
      return {
        'entry_count': entries.length,
        'avg_intensity': LocalInsights.average(entries),
        'top_mood': names.first,
      };
    }
    final rows = _feed.weeks ?? [];
    if (rows.isEmpty) return null;
    return rows.last;
  }

  double? get _sleepAverage {
    final rows = _feed.sleep ?? [];
    final count = rows.fold<int>(
      0,
      (sum, row) => sum + (row['count'] as num).toInt(),
    );
    return count == 0
        ? null
        : rows.fold<double>(
                0,
                (sum, row) =>
                    sum + (row['sleep_quality'] as num) * (row['count'] as num),
              ) /
              count;
  }

  @override
  void initState() {
    super.initState();
    _feed.addListener(_refresh);
    _moodSubscription = MoodRepository().watchMoodEntries().listen(
      (_) => _refresh(),
    );
    _feed.load(weekly: true, trigger: true, sleepMood: true);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _feed.dispose();
    _moodSubscription?.cancel();
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
        title: Text(
          'Insights',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
      ),
      body:
          !_feed.loading &&
              !_feed.failed &&
              ((_week?['entry_count'] as num?)?.toInt() ??
                      LocalInsights.moods().length) <
                  3
          ? EmptyState(
              icon: Icons.insights_outlined,
              title: 'Log a few moods to see patterns.',
              primaryCtaLabel: 'Log a mood',
              onPrimaryCta: () => context.push(AppRouter.moodFeeling),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final month in [false, true])
                          ChoiceChip(
                            label: Text(month ? 'Monthly' : 'Weekly'),
                            selected: _monthly == month,
                            onSelected: (_) => setState(() => _monthly = month),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InsightsStatus(
                      onRetry: () => _feed.load(
                        weekly: true,
                        trigger: true,
                        sleepMood: true,
                      ),
                      failureCount: _feed.failures,
                      loading: _feed.loading && _feed.weeks == null,
                      failed: _feed.failed,
                      empty:
                          (_feed.weeks ?? []).isEmpty &&
                          LocalInsights.moods().length < 3,
                    ),
                    FadeTransition(
                      opacity: headerAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(headerAnim),
                        child: Text(
                          _monthly ? 'This month' : 'This week',
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: subtextAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(subtextAnim),
                        child: Text(
                          'Your logged mood patterns, at your pace.',
                          style: AppTextStyles.body1.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
                        child: InsightCard(
                          icon: '🌿',
                          title: _week == null
                              ? 'Your patterns will appear here.'
                              : 'Most logged mood: ${_week!['top_mood']}',
                          subtitle:
                              'You logged ${_week?['entry_count'] ?? 0} entries this ${_monthly ? 'month' : 'week'}.',
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    FadeTransition(
                      opacity: statsAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(statsAnim),
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                value: '${_week?['entry_count'] ?? 0}',
                                label: 'Entries',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                value: _week == null
                                    ? '\u2014'
                                    : (_week!['avg_intensity'] as num)
                                          .toStringAsFixed(1),
                                label: 'Avg mood',
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.05),
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
                          begin: Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(statsAnim),
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                value: (_feed.triggers ?? []).isEmpty
                                    ? '\u2014'
                                    : _feed.triggers!.first['name'] as String,
                                label: 'Top trigger (30d)',
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                value:
                                    _sleepAverage?.toStringAsFixed(1) ??
                                    '\u2014',
                                label: 'Avg sleep (1-5)',
                              ),
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
                          Expanded(
                            child: Text(
                              'Mood trend',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
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
                        onTap: () => context.push(
                          AppRouter.insightsMoodTrend,
                        ), // To be added
                        child: _buildMiniChart(),
                      ),
                    ),
                    SizedBox(height: 32),
                    FadeTransition(
                      opacity: section2Anim,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Common triggers',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
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
                          for (final row in (_feed.triggers ?? []).take(2)) ...[
                            _buildMiniTrigger(
                              row['name'] as String,
                              "${row['count']} times",
                              (row['count'] as num) /
                                  (_feed.triggers!.first['count'] as num),
                            ),
                            SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    Text(
                      'Recommended actions',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit_note),
                      title: const Text('Make space for your thoughts'),
                      onTap: () => context.push(AppRouter.journal),
                    ),
                    ListTile(
                      leading: const Icon(Icons.self_improvement),
                      title: const Text('Try a breathing exercise'),
                      onTap: () => context.push(AppRouter.breathing),
                    ),
                    // Full report
                    FadeTransition(
                      opacity: section2Anim,
                      child: Center(
                        child: TextButton(
                          onPressed: () =>
                              context.push(AppRouter.insightsMonthlyReport),
                          child: Text(
                            'View full report',
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
    if (_daily.isEmpty) return const Text('Log 3 moods to see trends');
    return Container(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 8),
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
        children: [
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _MiniAreaChartPainter(
                data: _daily
                    .map((row) => (row['avg_intensity'] as num).toDouble())
                    .toList(),
                color: Theme.of(context).colorScheme.primary,
                animationValue: 1.0, // Simplified for mini chart
              ),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _daily
                .map((row) => (row['day'] as String).substring(5))
                .map((day) {
                  return Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSubtleDark
                            : AppColors.textSubtleLight,
                        fontSize: 12,
                      ),
                    ),
                  );
                })
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTrigger(String title, String frequency, double progress) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(frequency, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
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
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.data != data;
  }
}
