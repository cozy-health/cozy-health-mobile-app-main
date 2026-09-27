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
  String? selectedFeeling;

  final List<MoodCategory> moodCategories = [
    MoodCategory(
      title: 'Angry',
      color: const Color(0xFFFFE5E5),
      feelings: [
        {'emoji': '😠', 'label': 'Resentful'},
        {'emoji': '😡', 'label': 'Displaced'},
        {'emoji': '😤', 'label': 'Irritated'},
        {'emoji': '😣', 'label': 'Annoyed'},
        {'emoji': '🤬', 'label': 'Hostile'},
        {'emoji': '😠', 'label': 'Bitter'},
        {'emoji': '😡', 'label': 'Frustrated'},
        {'emoji': '😠', 'label': 'Provoked'},
        {'emoji': '😡', 'label': 'Livid'},
        {'emoji': '🤯', 'label': 'Furious'},
        {'emoji': '😤', 'label': 'Agitated'},
        {'emoji': '😠', 'label': 'Aggressive'},
      ],
    ),
    MoodCategory(
      title: 'Sad',
      color: const Color(0xFFE5F0FF),
      feelings: [
        {'emoji': '😢', 'label': 'Gloomy'},
        {'emoji': '💔', 'label': 'Heartbroken'},
        {'emoji': '😔', 'label': 'Lost'},
        {'emoji': '😞', 'label': 'Hopeless'},
        {'emoji': '😭', 'label': 'Miserable'},
        {'emoji': '🥺', 'label': 'Empty'},
        {'emoji': '😣', 'label': 'Frustrated'},
        {'emoji': '🥱', 'label': 'Drained'},
        {'emoji': '😩', 'label': 'Weary'},
        {'emoji': '😞', 'label': 'Disappointed'},
        {'emoji': '😔', 'label': 'Defeated'},
        {'emoji': '😢', 'label': 'Lonely'},
      ],
    ),
    MoodCategory(
      title: 'Good',
      color: const Color(0xFFE5FFEA),
      feelings: [
        {'emoji': '🙂', 'label': 'Content'},
        {'emoji': '😊', 'label': 'Satisfied'},
        {'emoji': '😌', 'label': 'Grateful'},
        {'emoji': '😐', 'label': 'Neutral'},
        {'emoji': '😊', 'label': 'Mildly Happy'},
        {'emoji': '👍', 'label': 'Okay'},
        {'emoji': '😊', 'label': 'Light Hearted'},
        {'emoji': '😊', 'label': 'Hopeful'},
        {'emoji': '😌', 'label': 'Relaxed'},
        {'emoji': '😊', 'label': 'Comfortable'},
        {'emoji': '😌', 'label': 'Peaceful'},
        {'emoji': '😊', 'label': 'Secure'},
      ],
    ),
    MoodCategory(
      title: 'Upset',
      color: const Color(0xFFFFF0E5),
      feelings: [
        {'emoji': '😟', 'label': 'Uneasy'},
        {'emoji': '😣', 'label': 'Hurt'},
        {'emoji': '😟', 'label': 'Worried'},
        {'emoji': '😢', 'label': 'Distraught'},
        {'emoji': '😫', 'label': 'Overwhelmed'},
        {'emoji': '😟', 'label': 'Insecure'},
        {'emoji': '😣', 'label': 'Stressed'},
        {'emoji': '😕', 'label': 'Doubtful'},
        {'emoji': '😟', 'label': 'Anxious'},
        {'emoji': '😕', 'label': 'Unsettled'},
        {'emoji': '😵', 'label': 'Disoriented'},
        {'emoji': '😣', 'label': 'Troubled'},
      ],
    ),
    MoodCategory(
      title: 'Spectacular',
      color: const Color(0xFFFFF4E5),
      feelings: [
        {'emoji': '⚡', 'label': 'Energized'},
        {'emoji': '🥳', 'label': 'Elated'},
        {'emoji': '😍', 'label': 'Blissful'},
        {'emoji': '🎉', 'label': 'Thrilled'},
        {'emoji': '🎊', 'label': 'Jubilant'},
        {'emoji': '🔥', 'label': 'Hyped'},
        {'emoji': '🌟', 'label': 'Over the moon'},
        {'emoji': '🥰', 'label': 'Overjoyed'},
        {'emoji': '😊', 'label': 'Proud'},
        {'emoji': '✨', 'label': 'Radiant'},
        {'emoji': '🌟', 'label': 'Inspired'},
        {'emoji': '🏆', 'label': 'Victorious'},
      ],
    ),
    MoodCategory(
      title: 'Happy',
      color: const Color(0xFFE5FFEA),
      feelings: [
        {'emoji': '😊', 'label': 'Cheerful'},
        {'emoji': '😄', 'label': 'Playful'},
        {'emoji': '😊', 'label': 'Glad'},
        {'emoji': '😊', 'label': 'Uplifted'},
        {'emoji': '😃', 'label': 'Lively'},
        {'emoji': '😊', 'label': 'Satisfied'},
        {'emoji': '🥰', 'label': 'Warm'},
        {'emoji': '😊', 'label': 'Optimistic'},
        {'emoji': '😊', 'label': 'Delighted'},
        {'emoji': '🥳', 'label': 'Joyful'},
        {'emoji': '😃', 'label': 'Excited'},
        {'emoji': '😊', 'label': 'Contented'},
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
          children: moodCategories.map((category) {
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
                    final isSelected = selectedFeeling == feeling['label'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFeeling = feeling['label'];
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : category.color,
                          borderRadius: BorderRadius.circular(30),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              feeling['emoji']!,
                              style: const TextStyle(fontSize: 20),
                            ),
                            2.w.sw,
                            Text(
                              feeling['label']!,
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
          }).toList(),
        ),
      ),
      bottomNavigationBar: selectedFeeling != null
          ? Padding(
              padding: EdgeInsets.all(6.w),
              child: AppButton(
                text: 'Continue',
                onPressed: () {
                  // TODO: Pass selectedFeeling to next screen
                  // For now, navigate to reason screen
                  context.push('/mood-reason');
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
  final List<Map<String, String>> feelings;

  MoodCategory({
    required this.title,
    required this.color,
    required this.feelings,
  });
}