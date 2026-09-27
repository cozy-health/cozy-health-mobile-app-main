import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../core/widgets/app_button.dart';

class CopingMechanismsScreen extends StatefulWidget {
  final int selectedFeelingExpId;
  final int intensity;
  final List<int> selectedReasonIds;

  const CopingMechanismsScreen({
    super.key,
    required this.selectedFeelingExpId,
    required this.intensity,
    required this.selectedReasonIds,
  });

  @override
  State<CopingMechanismsScreen> createState() => _CopingMechanismsScreenState();
}

class _CopingMechanismsScreenState extends State<CopingMechanismsScreen> {
  final Set<int> selectedCopingIds = {};

  final List<String> copingMechanisms = [
    'Deep breathing',
    'Meditation',
    'Journaling',
    'Talking to a friend',
    'Exercise',
    'Listening to music',
    'Watching a movie',
    'Writing',
    'Painting',
    'Baking',
    'Resting',
    'Cooking',
    'Taking a walk',
    'Reading',
    'Practicing gratitude',
    'Seeking therapy',
    'Using affirmations',
    'Drinking water',
    'Snacking',
    'Limiting screen time',
    'Setting boundaries',
    'Problem-solving',
    'Crying',
    'Avoiding responsibilities',
    'Smoking',
    'Drinking',
    'Sleeping',
    'Taking drugs',
    'Excessive screen time',
    'Excessive shopping',
    'Ignoring problems',
    'Procrastination',
    'Emotional outbursts',
    'Isolation from friends and family',
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
          'How have you expressed these feelings?',
          style: AppTextStyles.heading2.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.black),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coping Mechanisms',
                    style: AppTextStyles.heading2,
                  ),
                  3.sh,
                  Text(
                    'Select all that apply',
                    style: AppTextStyles.body1.copyWith(color: AppColors.grey),
                  ),
                  4.sh,

Wrap(
  spacing: 3.w,
  runSpacing: 2.5.h,
  children: copingMechanisms.asMap().entries.map((entry) {
    final index = entry.key;
    final mechanism = entry.value;

    final mechanismId = index + 1;

    final isSelected =
        selectedCopingIds.contains(mechanismId);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedCopingIds.remove(mechanismId);
          } else {
            selectedCopingIds.add(mechanismId);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 5.w,
          vertical: 2.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.lightGrey,

          borderRadius:
              BorderRadius.circular(30),

          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.midGrey,
            width: 1.5,
          ),
        ),
        child: Text(
          mechanism,
          style:
              AppTextStyles.body2.copyWith(
            color: isSelected
                ? AppColors.white
                : AppColors.black,

            fontWeight: isSelected
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }).toList(),
),
                ],
              ),
            ),
          ),

          // Bottom Continue Button
          Padding(
            padding: EdgeInsets.all(6.w),
            child: AppButton(
              text: 'Continue',
              onPressed: selectedCopingIds.isNotEmpty
                  ? () {
                      // For now, go to journal prompt
                     context.push(
  AppRouter.moodJournal,
  extra: {
    'feeling_exp_id': widget.selectedFeelingExpId,
    'intensity': widget.intensity,
    'reason_ids': widget.selectedReasonIds,
        'coping_mechanism_ids': selectedCopingIds.toList(),

  },
);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}