import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../utils/screen_util.dart';

class PreparingCozyScreen extends StatefulWidget {
  const PreparingCozyScreen({super.key});

  @override
  State<PreparingCozyScreen> createState() => _PreparingCozyScreenState();
}

class _PreparingCozyScreenState extends State<PreparingCozyScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.repeat();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Loading spinner
          CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 4,
                ),
                8.sh,
                
                // Main title
                Text(
                  'Give us a few seconds while\nwe prepare cozy for you',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                4.sh,
                
                // Subtitle
                Text(
                  'This will help cozy understand you better',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}