import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/insights_feed.dart';

class TriggersAnalysisScreen extends StatefulWidget {
  const TriggersAnalysisScreen({super.key});
  @override
  State<TriggersAnalysisScreen> createState() => _TriggersAnalysisScreenState();
}

class _TriggersAnalysisScreenState extends State<TriggersAnalysisScreen> {
  final _feed = InsightsFeed();
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _feed.addListener(_refresh);
    _feed.load(trigger: true);
  }

  @override
  void dispose() {
    _feed.dispose();
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
        title: Text('Triggers', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What\'s been\naffecting your mood?',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 32),

              InsightsStatus(
                onRetry: () => _feed.load(trigger: true),
                failureCount: _feed.failures,
                loading: _feed.loading && _feed.triggers == null,
                failed: _feed.failed,
                empty: (_feed.triggers ?? []).isEmpty,
              ),
              for (final row in (_feed.triggers ?? [])) ...[
                _buildTriggerRow(
                  context,
                  title: row['name'] as String,
                  frequency: (row['count'] as num).toInt(),
                  maxFrequency: (_feed.triggers!.first['count'] as num).toInt(),
                  avgMood: (row['avg_intensity'] as num).toDouble(),
                  comparison: 'Based on your entries in the last 30 days.',
                  barColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(height: 48),

              Text(
                'These aren\'t causes. Just patterns worth noticing.',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTriggerRow(
    BuildContext context, {
    required String title,
    required int frequency,
    required int maxFrequency,
    required double avgMood,
    required String comparison,
    required Color barColor,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: frequency / maxFrequency),
      builder: (context, progress, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${frequency}x',
                    style: AppTextStyles.body2.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              LayoutBuilder(
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
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              Text(
                'Average mood: $avgMood',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                comparison,
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
