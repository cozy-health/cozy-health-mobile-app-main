import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

class QuizRetakeConfirmDialog extends StatelessWidget {
  const QuizRetakeConfirmDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => const QuizRetakeConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Retake quiz?', style: AppTextStyles.heading2),
      content: Text(
        'You took this 2 weeks ago.',
        style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop('cancel'),
          child: Text('Cancel', style: AppTextStyles.body1.copyWith(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () => context.pop('view'),
          child: Text('View previous', style: AppTextStyles.body1.copyWith(color: AppColors.primary)),
        ),
        TextButton(
          onPressed: () => context.pop('retake'),
          child: Text('Retake', style: AppTextStyles.body1.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
