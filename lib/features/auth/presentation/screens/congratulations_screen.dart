import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../utils/screen_util.dart';
import '../../../../gen/assets.gen.dart';

class CongratulationsScreen extends StatefulWidget {
  const CongratulationsScreen({super.key});

  @override
  State<CongratulationsScreen> createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToPersonalization();
  }

  _navigateToPersonalization() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go(AppRouter.personalization);
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Confetti SVG illustration
              Image.asset(
                Assets.png.confetti.path,
                height: 200,
                width: 200,
              ),
              
              8.sh,
              
              // Congratulations title
              Text(
                'Congratulations!',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              4.sh,
              
              // First description
              Text(
                'You\'ve just taken an important step toward prioritizing your mental well-being.',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              4.sh,
              
              // Second description
              Text(
                'Cozy is here to support you every step of the way.',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Loading indicator (optional)
              CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
              
              2.sh,
            ],
          ),
        ),
      ),
    );
  }
}