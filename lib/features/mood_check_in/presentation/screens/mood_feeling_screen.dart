import 'package:cozy_health/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';

class MoodFeelingScreen extends StatefulWidget {
  const MoodFeelingScreen({super.key});

  @override
  State<MoodFeelingScreen> createState() => _MoodFeelingScreenState();
}

class _MoodFeelingScreenState extends State<MoodFeelingScreen> {
  int? selectedFeelingExpId;
  int intensity = 5;

  final List<MoodCategory> moodCategories = [
    MoodCategory(
      title: 'Angry',
      color: const Color(0xFFFFE5E5),
      feelings: [
        {'id': 1, 'emoji': '😠', 'label': 'Resentful'},
        {'id': 2, 'emoji': '😡', 'label': 'Displaced'},
        {'id': 3, 'emoji': '😤', 'label': 'Irritated'},
        {'id': 4, 'emoji': '😣', 'label': 'Annoyed'},
        {'id': 5, 'emoji': '🤬', 'label': 'Hostile'},
        {'id': 6, 'emoji': '😠', 'label': 'Bitter'},
        {'id': 7, 'emoji': '😡', 'label': 'Frustrated'},
        {'id': 8, 'emoji': '😠', 'label': 'Provoked'},
        {'id': 9, 'emoji': '😡', 'label': 'Livid'},
        {'id': 10, 'emoji': '🤯', 'label': 'Furious'},
        {'id': 11, 'emoji': '😤', 'label': 'Agitated'},
        {'id': 12, 'emoji': '😠', 'label': 'Aggressive'},
      ],
    ),
    MoodCategory(
      title: 'Sad',
      color: const Color(0xFFE5F0FF),
      feelings: [
        {'id': 13, 'emoji': '😢', 'label': 'Gloomy'},
        {'id': 14, 'emoji': '💔', 'label': 'Heartbroken'},
        {'id': 15, 'emoji': '😔', 'label': 'Lost'},
        {'id': 16, 'emoji': '😞', 'label': 'Hopeless'},
        {'id': 17, 'emoji': '😭', 'label': 'Miserable'},
        {'id': 18, 'emoji': '🥺', 'label': 'Empty'},
        {'id': 19, 'emoji': '😣', 'label': 'Frustrated'},
        {'id': 20, 'emoji': '🥱', 'label': 'Drained'},
        {'id': 21, 'emoji': '😩', 'label': 'Weary'},
        {'id': 22, 'emoji': '😞', 'label': 'Disappointed'},
        {'id': 23, 'emoji': '😔', 'label': 'Defeated'},
        {'id': 24, 'emoji': '😢', 'label': 'Lonely'},
      ],
    ),
    MoodCategory(
      title: 'Good',
      color: const Color(0xFFE5FFEA),
      feelings: [
        {'id': 25, 'emoji': '🙂', 'label': 'Content'},
        {'id': 26, 'emoji': '😊', 'label': 'Satisfied'},
        {'id': 27, 'emoji': '😌', 'label': 'Grateful'},
        {'id': 28, 'emoji': '😐', 'label': 'Neutral'},
        {'id': 29, 'emoji': '😊', 'label': 'Mildly Happy'},
        {'id': 30, 'emoji': '👍', 'label': 'Okay'},
        {'id': 31, 'emoji': '😊', 'label': 'Light Hearted'},
        {'id': 32, 'emoji': '😊', 'label': 'Hopeful'},
        {'id': 33, 'emoji': '😌', 'label': 'Relaxed'},
        {'id': 34, 'emoji': '😊', 'label': 'Comfortable'},
        {'id': 35, 'emoji': '😌', 'label': 'Peaceful'},
        {'id': 36, 'emoji': '😊', 'label': 'Secure'},
      ],
    ),
    MoodCategory(
      title: 'Upset',
      color: const Color(0xFFFFF0E5),
      feelings: [
        {'id': 37, 'emoji': '😟', 'label': 'Uneasy'},
        {'id': 38, 'emoji': '😣', 'label': 'Hurt'},
        {'id': 39, 'emoji': '😟', 'label': 'Worried'},
        {'id': 40, 'emoji': '😢', 'label': 'Distraught'},
        {'id': 41, 'emoji': '😫', 'label': 'Overwhelmed'},
        {'id': 42, 'emoji': '😟', 'label': 'Insecure'},
        {'id': 43, 'emoji': '😣', 'label': 'Stressed'},
        {'id': 44, 'emoji': '😕', 'label': 'Doubtful'},
        {'id': 45, 'emoji': '😟', 'label': 'Anxious'},
        {'id': 46, 'emoji': '😕', 'label': 'Unsettled'},
        {'id': 47, 'emoji': '😵', 'label': 'Disoriented'},
        {'id': 48, 'emoji': '😣', 'label': 'Troubled'},
      ],
    ),
    MoodCategory(
      title: 'Spectacular',
      color: const Color(0xFFFFF4E5),
      feelings: [
        {'id': 49, 'emoji': '⚡', 'label': 'Energized'},
        {'id': 50, 'emoji': '🥳', 'label': 'Elated'},
        {'id': 51, 'emoji': '😍', 'label': 'Blissful'},
        {'id': 52, 'emoji': '🎉', 'label': 'Thrilled'},
        {'id': 53, 'emoji': '🎊', 'label': 'Jubilant'},
        {'id': 54, 'emoji': '🔥', 'label': 'Hyped'},
        {'id': 55, 'emoji': '🌟', 'label': 'Over the moon'},
        {'id': 56, 'emoji': '🥰', 'label': 'Overjoyed'},
        {'id': 57, 'emoji': '😊', 'label': 'Proud'},
        {'id': 58, 'emoji': '✨', 'label': 'Radiant'},
        {'id': 59, 'emoji': '🌟', 'label': 'Inspired'},
        {'id': 60, 'emoji': '🏆', 'label': 'Victorious'},
      ],
    ),
    MoodCategory(
      title: 'Happy',
      color: const Color(0xFFE5FFEA),
      feelings: [
        {'id': 61, 'emoji': '😊', 'label': 'Cheerful'},
        {'id': 62, 'emoji': '😄', 'label': 'Playful'},
        {'id': 63, 'emoji': '😊', 'label': 'Glad'},
        {'id': 64, 'emoji': '😊', 'label': 'Uplifted'},
        {'id': 65, 'emoji': '😃', 'label': 'Lively'},
        {'id': 66, 'emoji': '😊', 'label': 'Satisfied'},
        {'id': 67, 'emoji': '🥰', 'label': 'Warm'},
        {'id': 68, 'emoji': '😊', 'label': 'Optimistic'},
        {'id': 69, 'emoji': '😊', 'label': 'Delighted'},
        {'id': 70, 'emoji': '🥳', 'label': 'Joyful'},
        {'id': 71, 'emoji': '😃', 'label': 'Excited'},
        {'id': 72, 'emoji': '😊', 'label': 'Contented'},
      ],
    ),
  ];

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
          'How would you describe how you are feeling?',
          style: AppTextStyles.heading2.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.black),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...moodCategories.map((category) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 2.w, bottom: 3.h),
                    child: Text(
                      category.title,
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 18,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 3.w,
                    runSpacing: 2.h,
                    children: category.feelings.map((feeling) {
                      final feelingId = feeling['id'] as int;
                      final isSelected = selectedFeelingExpId == feelingId;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFeelingExpId = feelingId;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : category.color,
                            borderRadius: BorderRadius.circular(30),
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                feeling['emoji'].toString(),
                                style: const TextStyle(fontSize: 20),
                              ),
                              2.w.sw,
                              Text(
                                feeling['label'].toString(),
                                style: AppTextStyles.body2.copyWith(
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  6.sh,
                ],
              );
            }),
            10.sh,
          ],
        ),
      ),
      bottomNavigationBar: selectedFeelingExpId != null
          ? Padding(
              padding: EdgeInsets.all(6.w),
              child: AppButton(
                text: 'Continue',
                onPressed: () {
                  context.push(
                    AppRouter.moodReason,
                    extra: {
                      'feeling_exp_id': selectedFeelingExpId,
                      'intensity': intensity,
                    },
                  );
                },
              ),
            )
          : null,
    );
  }
}

class MoodCategory {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> feelings;

  MoodCategory({
    required this.title,
    required this.color,
    required this.feelings,
  });
}