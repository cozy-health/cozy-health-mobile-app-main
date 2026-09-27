import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../gen/assets.gen.dart';

class QuizSelectionScreen extends StatelessWidget {
  const QuizSelectionScreen({super.key});

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
        title: Text(
          'Mental Health Quiz',
          style: AppTextStyles.heading2,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            2.sh,

            // Description
            Text(
              'Understand your emotions, identify patterns, and receive personalized recommendations to support your journey.',
              style: AppTextStyles.body1,
            ),

            5.sh,

            // Quiz Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 4.h,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              children: [
                _buildQuizCard(
                  title: 'Emotional Well-Being Check',
                  duration: '5 Min',
                  color: const Color(0xFFF0F4FF),
                  image: Assets.png.emotionalWellbeing, // Using existing asset
                  onTap: () => _startQuiz(context, 'emotional'),
                ),
                _buildQuizCard(
                  title: 'Stress & Anxiety Assessment',
                  duration: '7 Min',
                  color: const Color(0xFFFFF0F0),
                  // You can replace with a brain SVG if you have one, for now using placeholder
                  image: Assets.png.stressandanxiety,
                  onTap: () => _startQuiz(context, 'stress'),
                ),
                _buildQuizCard(
                  title: 'Depression & Low Mood Screening',
                  duration: '5 Min',
                  color: const Color(0xFFF0FFF0),
                  image: Assets.png.depression,
                  onTap: () => _startQuiz(context, 'depression'),
                ),
                _buildQuizCard(
                  title: 'Social & Relationship Well-Being',
                  duration: '4 Min',
                  color: const Color(0xFFFFF0F8),
                  image: Assets.png.socialRelationship,
                  onTap: () => _startQuiz(context, 'social'),
                ),
                _buildQuizCard(
                  title: 'Coping & Resilience Skills',
                  duration: '5 Min',
                  color: const Color(0xFFF8F0FF),
                  image: Assets.png.copingandresilence,
                  onTap: () => _startQuiz(context, 'coping'),
                ),
              ],
            ),

            8.sh,
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard({
    required String title,
    required String duration,
    required Color color,
    required AssetGenImage image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Duration badge
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    duration,
                    style: AppTextStyles.body2.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              2.sh,

              // Illustration
              Expanded(
                child: Center(
                  child: image.image(
                    height: 85,
                    width: 85,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              3.sh,

              // Title
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, String quizType) {
  String title = '';
  switch (quizType) {
    case 'emotional':
      title = 'Emotional Well-Being Check';
      break;
    case 'stress':
      title = 'Stress & Anxiety Assessment';
      break;
    case 'depression':
      title = 'Depression & Low Mood Screening';
      break;
    case 'social':
      title = 'Social & Relationship Well-Being';
      break;
    case 'coping':
      title = 'Coping & Resilience Skills';
      break;
    default:
      title = 'Mental Health Quiz';
  }

  context.push(
    AppRouter.quizDetail,
    extra: {'title': title, 'type': quizType},
  );
}
}