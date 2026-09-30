import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../utils/screen_util.dart';
import '../../../../gen/assets.gen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedMood;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                4.sh,
                
                // Header with profile and notification
                Row(
                  children: [
                    // Profile picture
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(Assets.png.profilePic.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    3.sw,
                    
                    // Welcome text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                          Text(
                            'Cordelia Ifeyinwa',
                            style: AppTextStyles.heading2.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Notification icon
                    GestureDetector(
                      onTap: () => context.push(AppRouter.notifications),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.lightGrey,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            Assets.svg.notification,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              AppColors.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                3.sh,
                
                // Mood check-in section
                Text(
                  'Tell cozy how you are feeling today',
                  style: AppTextStyles.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                2.sh,
                
                // Mood buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildMoodButton('Angry', Assets.svg.angry, const Color(0xFFFFE4B5)),
                    ),
                    2.sw,
                    Expanded(
                      child: _buildMoodButton('Sad', Assets.svg.sad, const Color(0xFFE0F7FA)),
                    ),
                    2.sw,
                    Expanded(
                      child: _buildMoodButton('Good', Assets.svg.good, const Color(0xFFFFF8DC)),
                    ),
                  ],
                ),
                
                6.sh,
                
                // Mental Health Quiz section - UPDATED NAVIGATION
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Quiz illustration
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            Assets.png.mentalQuiz.path,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      3.sw,
                      
                      // Quiz content
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mental Health Quiz',
                              style: AppTextStyles.heading2.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            1.sh,
                            Text(
                              'Take a quick self-assessment to gain insights into your mental well-being.',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                            2.sh,
                            AppButton(
                              text: 'Start Quiz',
                              onPressed: () => context.push(AppRouter.quizSelection),
                              isOutlined: true,
                              width: 30.w,
                              trailingIcon: Icons.arrow_forward,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                4.sh,
                
                // Cozy Calendar section (unchanged)
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cozy Calendar',
                            style: AppTextStyles.heading2.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Log',
                                  style: AppTextStyles.linkText.copyWith(
                                    color: Colors.orange,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      1.sh,
                      Text(
                        'Cozy Calendar tracks your mood by helping you log daily emotions to identify trends.',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                      3.sh,
                      
                      // Calendar days
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCalendarDay('Mon'),
                          _buildCalendarDay('Tue'),
                          _buildCalendarDay('Wed'),
                          _buildCalendarDay('Thur'),
                          _buildCalendarDay('Fri'),
                          _buildCalendarDay('Sat'),
                          _buildCalendarDay('Sun'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                4.sh,
                
                // Journaling section
                GestureDetector(
                  onTap: () => context.push(AppRouter.journal),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Journaling illustration
                        SvgPicture.asset(
                          Assets.svg.journaling,
                          width: 80,
                          height: 80,
                        ),
                        4.sw,
                        
                        // Journaling content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Journaling',
                                style: AppTextStyles.heading2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              1.sh,
                              Text(
                                'Your thoughts deserve a safe space. Write freely, reflect on your journey.',
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                10.sh, // Extra space for bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButton(String mood, String assetPath, Color backgroundColor) {
    final isSelected = selectedMood == mood;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMood = mood;
        });
        context.push(AppRouter.moodFeeling);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              assetPath,
              width: 35,
              height: 35,
              colorFilter: isSelected 
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  : null,
            ),
            1.sw,
            Text(
              mood,
              style: AppTextStyles.body2.copyWith(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDay(String day) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange,
          ),
        ),
        1.sh,
        Text(
          day,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}