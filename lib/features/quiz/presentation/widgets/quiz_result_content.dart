import 'package:cozy_health/core/theme/app_surface.dart';
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
    final assessment = attempt.definition.isNotEmpty
        ? ClinicalAssessment.fromDefinition(attempt.definition)
        : ClinicalAssessment.find(attempt.assessmentId);
    final complete =
        assessment != null &&
        attempt.answers.length == assessment.questions.length &&
        List.generate(
          attempt.answers.length,
          (i) => assessment
              .options(i)
              .any((option) => option['id'] == attempt.answers[i]),
        ).every((valid) => valid);
    final severity = attempt.severityLabel.isNotEmpty
        ? attempt.severityLabel
        : attempt.interpretation;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!attempt.isValidated)
          Text(
            attempt.validationState == 'pending'
                ? 'Provisional result · waiting for server validation'
                : attempt.validationState == 'rejected'
                ? 'Result not validated · ${attempt.metadata['validation_error'] ?? 'Please retake'}'
                : 'Legacy result · not verified',
            textAlign: TextAlign.center,
          ),
        Text(
          attempt.quizTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: AppSurface.border(context),
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
        if ((attempt.metadata['result_snapshot'] as Map?)?['recommendation']
            is String)
          Text(
            (attempt.metadata['result_snapshot'] as Map)['recommendation']
                as String,
          ),
        const Text(
          'Not a substitute for professional care. This is not a diagnosis.',
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
                border: AppSurface.border(context),
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
                    assessment
                            .options(index)
                            .firstWhere(
                              (o) => o['id'] == attempt.answers[index],
                            )['label']
                        as String,
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
