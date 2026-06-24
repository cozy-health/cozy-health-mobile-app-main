import 'package:cozy_health/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../data/splash_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SplashService _splashService = SplashService();

  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    final hasSession = await _splashService.hasValidSession();

    if (!mounted) return;

    if (hasSession) {
      context.go(AppRouter.home);
    } else {
      context.go(AppRouter.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SvgPicture.asset(Assets.svg.logo),
      ),
    );
  }
}