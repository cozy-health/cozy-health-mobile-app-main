import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TriggersAnalysisScreen extends StatelessWidget {
  const TriggersAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
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
                style: AppTextStyles.heading1.copyWith(fontSize: 24, color: AppColors.text, height: 1.2),
              ),
              const SizedBox(height: 32),
              
              _buildTriggerRow(
                context,
                title: 'Work',
                frequency: 4,
                maxFrequency: 4,
                avgMood: 4.8,
                comparison: 'Lower than your usual.',
                barColor: const Color(0xFFE85D3A), // warmOrange
              ),
              const SizedBox(height: 12),
              _buildTriggerRow(
                context,
                title: 'Sleep',
                frequency: 3,
                maxFrequency: 4,
                avgMood: 4.2,
                comparison: 'Lower than your usual.',
                barColor: const Color(0xFFE85D3A), // warmOrange
              ),
              const SizedBox(height: 12),
              _buildTriggerRow(
                context,
                title: 'Family',
                frequency: 2,
                maxFrequency: 4,
                avgMood: 5.5,
                comparison: 'About your usual.',
                barColor: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              _buildTriggerRow(
                context,
                title: 'Friends',
                frequency: 1,
                maxFrequency: 4,
                avgMood: 7.5,
                comparison: 'Higher than your usual.',
                barColor: const Color(0xFF2D9E54), // warmGreen
              ),
              
              const SizedBox(height: 48),
              
              Text(
                'These aren\'t causes. Just patterns worth noticing.',
                style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTextStyles.body1.copyWith(color: AppColors.text, fontWeight: FontWeight.w600)),
                  Text('${frequency}x', style: AppTextStyles.body2.copyWith(color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              Text(
                'Average mood: $avgMood',
                style: AppTextStyles.body2.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: 4),
              Text(
                comparison,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textMuted,
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
