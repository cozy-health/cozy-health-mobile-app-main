import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../core/widgets/app_button.dart';

class MoodSuccessScreen extends StatelessWidget {
  final String userName;
  final String selectedFeeling;
  final List<String> selectedReasons;
  final List<String> selectedCoping;
  final String journalText;

  const MoodSuccessScreen({
    super.key,
    this.userName = 'Cordelia',
    required this.selectedFeeling,
    required this.selectedReasons,
    required this.selectedCoping,
    required this.journalText,
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
              const Spacer(flex: 2),

              // Confetti + Great Job illustration
              Stack(
                alignment: Alignment.center,
                children: [
                  Assets.png.confetti.image(
                    height: 220,
                    width: 220,
                    fit: BoxFit.contain,
                  ),

                  Positioned(
                    top: 45,
                    child: Text(
                      'Great Job!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00C853),
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              8.sh,

              // Personalized message
              Text(
                'Welldone $userName',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              2.sh,

              Text(
                'You have completed the mood check in for today',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              3.sh,

              // Optional summary
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood Summary',
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    2.sh,

                    Text(
                      'Feeling: $selectedFeeling',
                      style: AppTextStyles.body1,
                    ),

                    1.sh,

                    Text(
                      'Reasons: ${selectedReasons.join(', ')}',
                      style: AppTextStyles.body1,
                    ),

                    1.sh,

                    Text(
                      'Coping: ${selectedCoping.join(', ')}',
                      style: AppTextStyles.body1,
                    ),

                    if (journalText.isNotEmpty) ...[
                      2.sh,

                      Text(
                        'Journal:',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      1.sh,

                      Text(
                        journalText,
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Finish button
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: AppButton(
                  text: 'Finish',
                  onPressed: () {
                    context.go(AppRouter.home);
                  },
                  isOutlined: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}