import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../widgets/provider_share_confirm_dialog.dart';
import 'package:intl/intl.dart';

class QuizResultDetailScreen extends StatelessWidget {
  final Map<String, dynamic> extra;

  const QuizResultDetailScreen({super.key, required this.extra});

  @override
  Widget build(BuildContext context) {
    final attempt = extra['attempt'] as QuizAttempt?;
    
    if (attempt == null) {
      return const Scaffold(body: Center(child: Text('Error: No attempt data')));
    }

    final title = attempt.quizTitle;
    final date = DateFormat('MMM d, yyyy').format(attempt.completedAt);
    final score = attempt.score;
    final interpretation = attempt.interpretation;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text(date, style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              Text(
                '$score',
                style: AppTextStyles.heading1.copyWith(fontSize: 72, color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              Text(
                'out of 9',
                style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  interpretation,
                  style: AppTextStyles.body1.copyWith(color: AppColors.text, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              
              Text('Breakdown', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              _buildBreakdownRow('Little interest or pleasure...', score > 2 ? 'Nearly every day' : 'Not at all'),
              const SizedBox(height: 12),
              _buildBreakdownRow('Feeling down...', score > 2 ? 'More than half the days' : 'Several days'),
              
              const SizedBox(height: 48),
              
              AppButton(
                text: 'Export for provider',
                onPressed: () async {
                  final result = await ProviderShareConfirmDialog.show(context);
                  if (result == true) {
                    // Logic to share
                  }
                },
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: AppTextStyles.body2.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(answer, style: AppTextStyles.body1.copyWith(color: AppColors.text, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
