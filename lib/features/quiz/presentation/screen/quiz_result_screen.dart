import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../gen/assets.gen.dart';

class QuizResultsScreen extends StatelessWidget {
  final String quizTitle;
  final int score;
  final int totalQuestions;

  const QuizResultsScreen({
    super.key,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final maxScore = totalQuestions * 3;
    final percent = maxScore > 0 ? ((score / maxScore) * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            children: [
              8.sh,
              Assets.png.confetti.image(
                height: 180,
                fit: BoxFit.contain,
              ),
              6.sh,
              const Text(
                'Great Job!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C853),
                ),
              ),
              3.sh,
              Text(
                'You completed the $quizTitle',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              2.sh,
              Text(
                'Based on your responses, here’s a quick summary:',
                style: AppTextStyles.body1.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              6.sh,
              Container(
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Quiz Score',
                      style: AppTextStyles.heading2.copyWith(fontSize: 18),
                    ),
                    2.sh,
                    Text(
                      '$percent/100',
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    1.sh,
                    Text(
                      'Raw Score: $score',
                      style: AppTextStyles.body1.copyWith(
                        color: const Color(0xFFFF9800),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              4.sh,
              Text(
                _summaryText(percent),
                style: AppTextStyles.body1,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                text: 'Finish',
                onPressed: () => context.go(AppRouter.home),
              ),
              2.sh,
              TextButton(
                onPressed: () => context.go(AppRouter.quizSelection),
                child: Text(
                  'Take Another Quiz',
                  style: AppTextStyles.linkText,
                ),
              ),
              4.sh,
            ],
          ),
        ),
      ),
    );
  }

  String _summaryText(int percent) {
    if (percent >= 75) {
      return 'Your responses suggest strong emotional awareness and healthy coping patterns.';
    }

    if (percent >= 50) {
      return 'You may be experiencing occasional emotional stress. Consider journaling and using your coping tools regularly.';
    }

    return 'Your responses suggest you may need extra emotional support. Consider reaching out to someone you trust or your therapist.';
  }
}