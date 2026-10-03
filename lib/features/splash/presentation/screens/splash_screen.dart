import 'dart:async';

import 'package:cozy_health/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/install_marker_service.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/services/user_data_fetcher.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/splash_service.dart';
import '../widgets/breathing_glow.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _brandMomentDuration = Duration(milliseconds: 2500);
  static const Duration _fadeOutDuration = Duration(milliseconds: 500);

  final SplashService _splashService = SplashService();

  late final AnimationController _timeline;
  late final AnimationController _breathing;
  late final AnimationController _fadeOutCtrl;

  late final Animation<double> _glowOpacity;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoBreathScale;
  late final Animation<double> _headlineOpacity;
  late final Animation<Offset> _headlineOffset;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineOffset;
  late final Animation<double> _screenOpacity;

  @override
  void initState() {
    super.initState();

    _timeline = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _breathing = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _fadeOutCtrl = AnimationController(vsync: this, duration: _fadeOutDuration);

    _glowOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _timeline,
        curve: const Interval(0, 0.44, curve: Curves.easeOutCubic),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _timeline,
        curve: const Interval(0, 0.44, curve: Curves.easeOutCubic),
      ),
    );

    _logoScale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _timeline,
        curve: const Interval(0, 0.44, curve: Curves.easeOutCubic),
      ),
    );

    _logoBreathScale = Tween<double>(
      begin: 0.98,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _breathing, curve: Curves.easeInOut));

    _headlineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _timeline,
        curve: const Interval(0.36, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _headlineOffset =
        Tween<Offset>(begin: const Offset(0, 0.32), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _timeline,
            curve: const Interval(0.36, 0.72, curve: Curves.easeOutCubic),
          ),
        );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _timeline,
        curve: const Interval(0.48, 0.86, curve: Curves.easeOutCubic),
      ),
    );

    _taglineOffset =
        Tween<Offset>(begin: const Offset(0, 0.32), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _timeline,
            curve: const Interval(0.48, 0.86, curve: Curves.easeOutCubic),
          ),
        );

    _screenOpacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _fadeOutCtrl, curve: Curves.easeInCubic));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await InstallMarkerService().clearLingeringSessionOnFreshInstall();

    final hasToken = await _splashService.hasStoredSession();
    final onboardingDone = await OnboardingService().hasCompletedOnboarding();
    debugPrint('APP_START: token present = $hasToken');

    _timeline.forward();
    _breathing.repeat(reverse: true);

    final results = await Future.wait([
      Future.value(hasToken),
      Future.delayed(_brandMomentDuration, () => false),
    ]);

    if (!mounted) return;

    await _fadeOutCtrl.forward();

    if (!mounted) return;

    if (!results.first) {
      context.go(onboardingDone ? AppRouter.welcome : AppRouter.onboarding);
      return;
    }

    try {
      await ApiClient.instance.get(ApiConstants.me);
      if (!mounted) return;
      context.go(AppRouter.home);
      unawaited(_syncUserDataInBackground());
    } catch (e) {
      debugPrint('Stored session validation failed: $e');
      await TokenStorage().clearToken();
      await LocalDbService.instance.clearAllUserData();
      if (!mounted) return;
      context.go(AppRouter.welcome);
    }
  }

  Future<void> _syncUserDataInBackground() async {
    await UserDataFetcher().fetchAll();
    debugPrint('Background data sync complete');
  }

  @override
  void dispose() {
    _timeline.dispose();
    _breathing.dispose();
    _fadeOutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return FadeTransition(
      opacity: _screenOpacity,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FadeTransition(
                        opacity: reduceMotion
                            ? const AlwaysStoppedAnimation(1)
                            : _glowOpacity,
                        child: const BreathingGlow(
                          size: 220,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      FadeTransition(
                        opacity: reduceMotion
                            ? const AlwaysStoppedAnimation(1)
                            : _logoOpacity,
                        child: ScaleTransition(
                          scale: reduceMotion
                              ? const AlwaysStoppedAnimation(1)
                              : _logoScale,
                          child: AnimatedBuilder(
                            animation: _logoBreathScale,
                            builder: (_, child) => Transform.scale(
                              scale: reduceMotion ? 1 : _logoBreathScale.value,
                              child: child,
                            ),
                            child: SvgPicture.asset(
                              Assets.svg.logo,
                              width: 140,
                              height: 140,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: reduceMotion
                      ? const AlwaysStoppedAnimation(1)
                      : _headlineOpacity,
                  child: SlideTransition(
                    position: reduceMotion
                        ? const AlwaysStoppedAnimation(Offset.zero)
                        : _headlineOffset,
                    child: Text(
                      'COZY HEALTH',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 2,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: reduceMotion
                      ? const AlwaysStoppedAnimation(1)
                      : _taglineOpacity,
                  child: SlideTransition(
                    position: reduceMotion
                        ? const AlwaysStoppedAnimation(Offset.zero)
                        : _taglineOffset,
                    child: Text(
                      'Breathe. Reflect. Grow.',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
