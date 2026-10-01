import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/clinical_disclaimer_sheet.dart';

class QuizDetailScreen extends StatelessWidget {
  final Map<String, dynamic> extra;

  const QuizDetailScreen({super.key, required this.extra});

  @override
  Widget build(BuildContext context) {
    final title = extra['title'] as String? ?? 'Quiz';
    final type = extra['type'] as String? ?? 'wellness';
    final isClinical = type == 'clinical';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isClinical)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Clinical assessment',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              
              Text(
                title,
                style: AppTextStyles.heading1.copyWith(fontSize: 32, color: AppColors.text),
              ),
              const SizedBox(height: 16),
              
              Text(
                isClinical
                    ? 'This is a standard screening tool used by healthcare professionals to understand your symptoms over the last 2 weeks.'
                    : 'Take a few minutes to reflect on how you are feeling. This helps us personalize your experience.',
                style: AppTextStyles.body1.copyWith(color: AppColors.text, height: 1.5),
              ),
              const SizedBox(height: 32),
              
              _buildDetailRow(Icons.help_outline, isClinical ? '9 questions' : '5 questions'),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.timer_outlined, isClinical ? 'Estimated 5 min' : 'Estimated 3 min'),
              
              const Spacer(),
              
              AppButton(
                text: 'Start Quiz',
                onPressed: () async {
                  if (isClinical) {
                    final proceed = await ClinicalDisclaimerSheet.show(context);
                    if (proceed == true) {
                      if (context.mounted) {
                        context.push(AppRouter.quizTaking, extra: extra);
                      }
                    }
                  } else {
                    context.push(AppRouter.quizTaking, extra: extra);
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}