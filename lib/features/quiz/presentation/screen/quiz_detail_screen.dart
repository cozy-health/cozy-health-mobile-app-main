import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../core/widgets/app_button.dart';

class QuizDetailScreen extends StatelessWidget {
  final int quizId;
  final String quizTitle;
  final String quizType;

  const QuizDetailScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.quizType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(quizTitle, style: AppTextStyles.heading2),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            4.sh,
            Text(
              'Assess your current emotional health and mood patterns.',
              style: AppTextStyles.body1,
            ),
            3.sh,
            Row(
              children: [
                _buildBadge(Icons.timer, '5 Minutes'),
                4.sw,
                _buildBadge(Icons.calendar_today, 'Monthly'),
              ],
            ),
            5.sh,
            Center(
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Assets.png.emotionalWellbeing.image(
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            6.sh,
            Text(
              'Your emotions shape your daily experiences. This quiz helps you understand your mood patterns and emotional resilience.',
              style: AppTextStyles.body1.copyWith(height: 1.6),
            ),
            const Spacer(),
            AppButton(
              text: 'Start',
              onPressed: () {
                context.push(
                  AppRouter.quizTaking,
                  extra: {
                    'id': quizId,
                    'title': quizTitle,
                    'type': quizType,
                  },
                );
              },
            ),
            3.sh,
            Center(
              child: TextButton(
                onPressed: () {
                  context.push(AppRouter.quizResults, extra: {
                    'title': quizTitle,
                    'score': 0,
                    'total_questions': 0,
                  });
                },
                child: Text(
                  'See results',
                  style: AppTextStyles.linkText.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            6.sh,
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.grey),
          2.sw,
          Text(
            text,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}