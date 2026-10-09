import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../gen/assets.gen.dart';
import '../../domain/clinical_assessment.dart';
import '../widgets/clinical_disclaimer_sheet.dart';

class QuizDetailScreen extends StatelessWidget {
  const QuizDetailScreen({super.key, required this.extra});
  final Map<String, dynamic> extra;
  @override
  Widget build(BuildContext context) {
    final assessment = ClinicalAssessment.find(extra['id'] as String?);
    final title = assessment?.title ?? extra['title'] as String? ?? 'Quiz';
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              assessment != null
                  ? 'A check-in on the last two weeks'
                  : 'Take a moment to reflect',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 18),
                    const SizedBox(width: 6),
                    Text('${assessment?.minutes ?? 3} minutes'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text('${assessment?.questions.length ?? 3} questions'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 239,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.accentSkyDark
                    : AppColors.accentSky,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(24),
              child: Image.asset(
                assessment?.id == 'gad-7'
                    ? Assets.png.stressandanxiety.path
                    : Assets.png.emotionalWellbeing.path,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              assessment != null
                  ? ClinicalAssessment.timeframe
                  : 'Take a few minutes to reflect on how you are feeling.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'This is not a diagnosis. Talk to a professional for clinical evaluation.',
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                try {
                  if (assessment != null &&
                      await ClinicalDisclaimerSheet.show(context) != true) {
                    return;
                  }
                  if (context.mounted) {
                    context.push(AppRouter.quizTaking, extra: extra);
                  }
                } catch (_) {
                  if (context.mounted) {
                    AppSnackbar.show(
                      context,
                      AppSnackbar.fromLegacy(
                        content: const Text(
                          'Could not start the assessment. Please try again.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Start Quiz'),
            ),
            TextButton(
              onPressed: () => context.push(AppRouter.quizHistory),
              child: const Text('See results'),
            ),
          ],
        ),
      ),
    );
  }
}
