import 'package:cozy_health/core/widgets/app_scroll_body.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';

class PreparingCozyScreen extends StatefulWidget {
  const PreparingCozyScreen({super.key});

  @override
  State<PreparingCozyScreen> createState() => _PreparingCozyScreenState();
}

class _PreparingCozyScreenState extends State<PreparingCozyScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: AppScrollBody(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Loading spinner
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
