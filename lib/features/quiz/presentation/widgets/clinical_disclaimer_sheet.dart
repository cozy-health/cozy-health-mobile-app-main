import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_button.dart';

class ClinicalDisclaimerSheet extends StatelessWidget {
  const ClinicalDisclaimerSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ClinicalDisclaimerSheet(),
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
            Icon(Icons.info_outline, size: 48, color: AppColors.textSubtle),
            const SizedBox(height: 24),
            Text(
              'Before we start',
              style: AppTextStyles.heading2.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This is not a diagnosis. It\'s a screening tool to help you understand what you\'re experiencing. A professional can help interpret results.',
              style: AppTextStyles.body1.copyWith(color: AppColors.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'I understand',
              onPressed: () => context.pop(true),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Cancel',
              isOutlined: true,
              onPressed: () => context.pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
