import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/install_marker_service.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/widgets/startup_cover.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/splash_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void>? _opening;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openSession();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    StartupCover.retryWith(context, _openSession);
  }

  void _openSession() {
    if (_opening != null) return;
    _opening = _prepare()
        .catchError((Object _) {})
        .whenComplete(() => _opening = null);
  }

  Future<void> _prepare() async {
    final router = GoRouter.of(context);
    final origin = router.routeInformationProvider.value.uri;
    await InstallMarkerService().clearLingeringSessionOnFreshInstall();
    final generation = TokenStorage.generation;
    final hasToken = await SplashService().hasStoredSession();
    final onboardingDone = await OnboardingService().hasCompletedOnboarding();
    if (!mounted ||
        generation != TokenStorage.generation ||
        router.routeInformationProvider.value.uri != origin) {
      return;
    }
    if (!hasToken) {
      context.go(onboardingDone ? AppRouter.welcome : AppRouter.onboarding);
      return;
    }
    final local = LocalDbService.instance;
    final account = local.activeUserId;
    if (account != null &&
        !account.startsWith('guest_') &&
        local.getUserProfile() != null) {
      context.go(AppRouter.home);
      unawaited(_refreshSession(generation, account, router));
      return;
    }
    try {
      await AuthService().resumeStoredSession();
      if (mounted &&
          generation == TokenStorage.generation &&
          router.routeInformationProvider.value.uri == origin) {
        context.go(AppRouter.home);
      }
    } on ApiAuthException {
      if (generation != TokenStorage.generation) return;
      await AuthService().logout();
      if (mounted) context.go(AppRouter.welcome);
    } catch (_) {
      if (!mounted ||
          generation != TokenStorage.generation ||
          router.routeInformationProvider.value.uri != origin) {
        return;
      }
      context.go(
        LocalDbService().getUserProfile() != null
            ? AppRouter.home
            : AppRouter.welcome,
      );
    }
  }

  Future<void> _refreshSession(
    int generation,
    String account,
    GoRouter router,
  ) async {
    try {
      await AuthService().resumeStoredSession();
    } on ApiAuthException {
      if (generation != TokenStorage.generation ||
          account != LocalDbService.instance.activeUserId) {
        return;
      }
      await AuthService().logout();
      if (LocalDbService.instance.activeUserId?.startsWith('guest_') == true) {
        router.go(AppRouter.welcome);
      }
    } catch (_) {
      // Saved account content remains available during connectivity failures.
    }
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: const StartupIcon()));
}
