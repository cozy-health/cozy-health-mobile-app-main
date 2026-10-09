import 'package:flutter/material.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/clinical_assessment.dart';

/// Answers are visible only in the patient's result UI, never in provider payloads.
class QuizResultContent extends StatelessWidget {
  const QuizResultContent({super.key, required this.attempt});
  final QuizAttempt attempt;
  @override
  Widget build(BuildContext context) {
    final assessment = ClinicalAssessment.find(attempt.assessmentId);
    final complete =
        assessment != null &&
        attempt.answers.length == assessment.questions.length &&
        attempt.answers.every((answer) => answer >= 0 && answer <= 3);
    final severity = attempt.severityLabel.isNotEmpty
        ? attempt.severityLabel
        : attempt.interpretation;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          attempt.quizTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: dark ? AppColors.accentSkyDark : AppColors.accentSky,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                '${attempt.totalScore}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (complete)
                Text(
                  'out of ${assessment.maximumScore}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 12),
              Text(
                severity,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'This is not a diagnosis. Talk to a professional for clinical evaluation.',
          textAlign: TextAlign.center,
        ),
        if (complete) ...[
          const SizedBox(height: 24),
          Text('Your responses', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (var index = 0; index < assessment.questions.length; index++) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark
                    ? AppColors.surfaceSubtleDark
                    : AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assessment.questions[index],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ClinicalAssessment.answerLabels[attempt.answers[index]],
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}
