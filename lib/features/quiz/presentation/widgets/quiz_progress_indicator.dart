import 'package:flutter/material.dart';
import '../../../../../core/theme/app_text_styles.dart';

class QuizProgressIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;

  const QuizProgressIndicator({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentIndex / totalQuestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question $currentIndex of $totalQuestions',
              style: AppTextStyles.body2.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          tween: Tween<double>(begin: 0, end: progress),
          builder: (context, value, _) => LayoutBuilder(
            builder: (context, constraints) => Container(
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.centerLeft,
              child: Container(
                width: constraints.maxWidth * value,
                height: 6,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
