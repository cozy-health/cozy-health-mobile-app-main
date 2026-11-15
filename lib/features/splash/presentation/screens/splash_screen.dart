import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/install_marker_service.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/splash_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _openSession();
  }

  Future<void> _openSession() async {
    await InstallMarkerService().clearLingeringSessionOnFreshInstall();
    final hasToken = await SplashService().hasStoredSession();
    final onboardingDone = await OnboardingService().hasCompletedOnboarding();
    if (!mounted) return;
    if (!hasToken) {
      context.go(onboardingDone ? AppRouter.welcome : AppRouter.onboarding);
      return;
    }
    try {
      await AuthService().resumeStoredSession();
      if (mounted) context.go(AppRouter.home);
    } on ApiAuthException {
      await TokenStorage().clearToken();
      await LocalDbService.instance.activateGuest();
      if (mounted) context.go(AppRouter.welcome);
    } catch (_) {
      if (!mounted) return;
      context.go(
        LocalDbService().getUserProfile() != null
            ? AppRouter.home
            : AppRouter.welcome,
      );
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: ScreenSkeleton());
}
