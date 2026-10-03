import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

class ProviderShareConfirmDialog extends StatelessWidget {
  const ProviderShareConfirmDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const ProviderShareConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Share result?', style: AppTextStyles.heading2),
      content: Text(
        'Send this result to Dr. Smith?',
        style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text('Cancel', style: AppTextStyles.body1.copyWith(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () => context.pop(true),
          child: Text('Send', style: AppTextStyles.body1.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
