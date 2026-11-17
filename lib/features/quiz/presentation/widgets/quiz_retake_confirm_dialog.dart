import 'package:flutter/material.dart';
import '../../../../../core/theme/cozy_colors.dart';
import '../../../../../core/widgets/wellness_sheet.dart';
import '../../../../../core/widgets/wellness_panel.dart';

class QuizRetakeConfirmDialog extends StatelessWidget {
  const QuizRetakeConfirmDialog({super.key});

  static Future<String?> show(BuildContext context) =>
      showWellnessDialog<String>(
        context: context,
        builder: (_) => const QuizRetakeConfirmDialog(),
      );

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return WellnessSheet(
      title: 'Retake assessment?',
      children: [
        const Text('You can start again or view your previous assessment.'),
        SizedBox(height: w.section),
        WellnessAction(
          key: const ValueKey('assessment-retake'),
          label: 'Retake',
          filled: true,
          onPressed: () => Navigator.pop(context, 'retake'),
        ),
        SizedBox(height: w.small),
        WellnessAction(
          key: const ValueKey('assessment-view-previous'),
          label: 'View previous',
          onPressed: () => Navigator.pop(context, 'view'),
        ),
        SizedBox(height: w.small),
        WellnessAction(
          key: const ValueKey('assessment-retake-cancel'),
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, 'cancel'),
        ),
      ],
    );
  }
}
