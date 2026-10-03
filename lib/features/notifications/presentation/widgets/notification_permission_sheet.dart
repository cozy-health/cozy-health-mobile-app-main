import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class NotificationPermissionSheet extends StatelessWidget {
  const NotificationPermissionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const NotificationPermissionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.notifications_active_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Stay on track\nwith gentle\nreminders?',
              style: AppTextStyles.heading2.copyWith(fontSize: 28, color: AppColors.text, height: 1.2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We\'ll send you a daily check-in and celebrate your milestones.',
              style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Never spam. Never guilt. You control everything in Settings.',
              style: AppTextStyles.body2.copyWith(fontSize: 12, color: AppColors.textSubtle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Turn on',
              onPressed: () {
                // Trigger system permission prompt here
                // After success/failure, pop
                context.pop(true);
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Not now',
              isOutlined: true,
              onPressed: () => context.pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
