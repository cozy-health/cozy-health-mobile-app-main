import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class NotificationDeniedSheet extends StatelessWidget {
  const NotificationDeniedSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const NotificationDeniedSheet(),
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
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.textSubtle,
            ),
            const SizedBox(height: 24),
            Text(
              'Notifications are turned off.',
              style: AppTextStyles.heading2.copyWith(fontSize: 24, color: AppColors.text, height: 1.2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To receive reminders, turn them on in your device settings.',
              style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Open Settings',
              onPressed: () {
                // Open device settings
                context.pop(true);
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Maybe later',
              isOutlined: true,
              onPressed: () => context.pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
