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

  const QuizResultsScreen({
    super.key,
    required this.quizTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            children: [
              8.sh,

              // Success Illustration
              Assets.png.confetti.image(
                height: 180,
                fit: BoxFit.contain,
              ),

              6.sh,

              Text(
                'Great Job!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00C853),
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

              // Score / Insight Card
              Container(
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Emotional Well-Being Score',
                      style: AppTextStyles.heading2.copyWith(fontSize: 18),
                    ),
                    2.sh,
                    Text(
                      '78/100',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    1.sh,
                    Text(
                      'Mild Emotional Distress Detected',
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
                'You seem to be experiencing occasional mood fluctuations. Consider practicing daily mindfulness and reaching out to your support network.',
                style: AppTextStyles.body1,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Buttons
              AppButton(
                text: 'Finish',
                onPressed: () => context.go(AppRouter.home),
              ),

              2.sh,

              TextButton(
                onPressed: () {
                  // Restart same quiz
                  context.pop();
                },
                child: Text(
                  'Retake Quiz',
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
}