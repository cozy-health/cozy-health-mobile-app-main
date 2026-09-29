import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

class QuizBackConfirmDialog extends StatelessWidget {
  const QuizBackConfirmDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const QuizBackConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Leave the quiz?', style: AppTextStyles.heading2),
      content: Text(
        'Your progress will be lost.',
        style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text('Continue', style: AppTextStyles.body1.copyWith(color: AppColors.text)),
        ),
        TextButton(
          onPressed: () => context.pop(true),
          child: Text('Leave', style: AppTextStyles.body1.copyWith(color: AppColors.danger)),
        ),
      ],
    );
  }
}
