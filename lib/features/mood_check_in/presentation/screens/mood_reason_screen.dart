import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../core/widgets/app_button.dart';

class MoodReasonScreen extends StatefulWidget {
  final int selectedFeelingExpId;
  final int intensity;

  const MoodReasonScreen({
    super.key,
    required this.selectedFeelingExpId,
    required this.intensity,
  });

  @override
  State<MoodReasonScreen> createState() => _MoodReasonScreenState();
}

class _MoodReasonScreenState extends State<MoodReasonScreen> {
  final Set<int> selectedReasonIds = {};

  final List<ReasonCategory> reasonCategories = [
    ReasonCategory(
      title: 'Work',
      color: const Color(0xFFE5FFEA),
      reasons: [
        {'id': 1, 'icon': '⏰', 'label': 'Deadlines'},
        {'id': 2, 'icon': '❤️', 'label': 'Conflict'},
        {'id': 3, 'icon': '💼', 'label': 'Workload'},
        {'id': 4, 'icon': '🔦', 'label': 'Job Insecurity'},
        {'id': 5, 'icon': '🔥', 'label': 'Burnout'},
        {'id': 6, 'icon': '💰', 'label': 'Salary'},
      ],
    ),
    ReasonCategory(
      title: 'School',
      color: const Color(0xFFFFF0E5),
      reasons: [
        {'id': 7, 'icon': '📚', 'label': 'Exam stress'},
        {'id': 8, 'icon': '👥', 'label': 'Bullying'},
        {'id': 9, 'icon': '👩‍🏫', 'label': 'Teacher'},
        {'id': 10, 'icon': '🧠', 'label': 'Lack of motivation'},
        {'id': 11, 'icon': '❌', 'label': 'Fear of failure'},
        {'id': 12, 'icon': '⏳', 'label': 'Time Management'},
      ],
    ),
    ReasonCategory(
      title: 'Relationship',
      color: const Color(0xFFE5F0FF),
      reasons: [
        {'id': 13, 'icon': '👫', 'label': 'Conflict with partner'},
        {'id': 14, 'icon': '🔗', 'label': 'Trust Issues'},
        {'id': 15, 'icon': '🌍', 'label': 'Long Distance'},
        {'id': 16, 'icon': '💬', 'label': 'Lack of communication'},
        {'id': 17, 'icon': '👨‍👩‍👧', 'label': 'Family tension'},
        {'id': 18, 'icon': '💔', 'label': 'Betrayal'},
        {'id': 19, 'icon': '👻', 'label': 'Ghosting'},
        {'id': 20, 'icon': '😠', 'label': 'Jealousy'},
      ],
    ),
    ReasonCategory(
      title: 'Sleep',
      color: const Color(0xFFFFE5E5),
      reasons: [
        {'id': 21, 'icon': '🌙', 'label': 'Insomnia'},
        {'id': 22, 'icon': '😱', 'label': 'Nightmares'},
        {'id': 23, 'icon': '🔊', 'label': 'Noise'},
        {'id': 24, 'icon': '😣', 'label': 'Stress'},
        {'id': 25, 'icon': '🛌', 'label': 'Restlessness'},
        {'id': 26, 'icon': '\u{1F635}', 'label': 'Sleep Paralysis'},
        {'id': 27, 'icon': '🌃', 'label': 'Late night work/study'},
      ],
    ),
    ReasonCategory(
      title: 'Health',
      color: const Color(0xFFFFF4E5),
      reasons: [
        {'id': 28, 'icon': '🩸', 'label': 'Period'},
        {'id': 29, 'icon': '😟', 'label': 'Anxiety'},
        {'id': 30, 'icon': '🍔', 'label': 'Poor diet'},
        {'id': 31, 'icon': '💪', 'label': 'Physical pain'},
        {'id': 32, 'icon': '🤧', 'label': 'Allergies'},
        {'id': 33, 'icon': '🏃', 'label': 'Lack of exercise'},
        {'id': 34, 'icon': '🦠', 'label': 'Chronic illness'},
        {'id': 35, 'icon': '💊', 'label': 'Medication'},
        {'id': 36, 'icon': '🍽️', 'label': 'Digestive issues'},
        {'id': 37, 'icon': '⚖️', 'label': 'Hormonal imbalance'},
        {'id': 38, 'icon': '😫', 'label': 'Fatigue'},
        {'id': 39, 'icon': '🚫', 'label': 'Substance withdrawal'},
      ],
    ),
    ReasonCategory(
      title: 'Life changes',
      color: const Color(0xFFE5FFEA),
      reasons: [
        {'id': 40, 'icon': '🎉', 'label': 'Anniversaries'},
        {'id': 41, 'icon': '🎂', 'label': 'Birthday'},
        {'id': 42, 'icon': '❤️', 'label': 'Loss of a loved one'},
        {'id': 43, 'icon': '🐾', 'label': 'Loss of a pet'},
        {'id': 44, 'icon': '🏠', 'label': 'Moving homes'},
        {'id': 45, 'icon': '👨‍👩‍👧', 'label': 'Parenthood'},
        {'id': 46, 'icon': '🌱', 'label': 'New beginnings'},
        {'id': 47, 'icon': '👨‍👩‍👧‍👦', 'label': 'Family reunion'},
        {'id': 48, 'icon': '💸', 'label': 'Financial struggles'},
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
          'What made you feel this way?',
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
          children: reasonCategories.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 2.w, bottom: 3.h),
                  child: Text(
                    category.title,
                    style: AppTextStyles.heading2.copyWith(fontSize: 18),
                  ),
                ),
                Wrap(
                  spacing: 3.w,
                  runSpacing: 2.h,
                  children: category.reasons.map((reason) {
                    final reasonId = reason['id'] as int;
                    final isSelected = selectedReasonIds.contains(reasonId);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedReasonIds.remove(reasonId);
                          } else {
                            selectedReasonIds.add(reasonId);
                          }
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.8.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : category.color,
                          borderRadius: BorderRadius.circular(30),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reason['icon'].toString(),
                              style: const TextStyle(fontSize: 22),
                            ),
                            2.w.sw,
                            Text(
                              reason['label'].toString(),
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
      bottomNavigationBar: selectedReasonIds.isNotEmpty
          ? Padding(
              padding: EdgeInsets.all(6.w),
              child: AppButton(
                text: 'Continue',
                onPressed: () {
                  context.push(
                    AppRouter.copingMechanisms,
                    extra: {
                      'feeling_exp_id': widget.selectedFeelingExpId,
                      'intensity': widget.intensity,
                      'reason_ids': selectedReasonIds.toList(),
                    },
                  );
                },
              ),
            )
          : null,
    );
  }
}

class ReasonCategory {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> reasons;

  ReasonCategory({
    required this.title,
    required this.color,
    required this.reasons,
  });
}
