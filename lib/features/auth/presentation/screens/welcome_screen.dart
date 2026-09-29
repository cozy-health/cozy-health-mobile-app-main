import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/auth_ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 47, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              const AuthLogoMark(),
              const SizedBox(height: 48),
              Text(
                'Welcome to\nCozy Health.',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'A quiet space to check in with yourself.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              AuthPrimaryButton(
                text: 'Sign Up',
                onPressed: () => context.go(AppRouter.createAccount),
              ),
              const SizedBox(height: 12),
              AuthPrimaryButton(
                text: 'Log In',
                isOutlined: true,
                onPressed: () => context.go(AppRouter.login),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRouter.home),
                child: Text(
                  'Continue as Guest',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const LegalFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
