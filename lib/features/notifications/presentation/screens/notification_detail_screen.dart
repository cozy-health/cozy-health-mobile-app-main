import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key});

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              
              // Centered Illustration/Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🏆', style: TextStyle(fontSize: 64)),
                ),
              ),
              const SizedBox(height: 48),
              
              // Title
              Text(
                '7-day streak!',
                style: AppTextStyles.heading1.copyWith(fontSize: 28, color: AppColors.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Body
              Text(
                'You\'ve logged your mood 7 days in a row.\nThat\'s real dedication to yourself.',
                style: AppTextStyles.body1.copyWith(color: AppColors.textMuted, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              
              // Actions
              AppButton(
                text: 'View in Achievements',
                onPressed: () {
                  // Navigate to achievements feature
                  context.pop();
                },
                trailingIcon: Icons.arrow_forward,
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Dismiss',
                onPressed: () => context.pop(),
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
