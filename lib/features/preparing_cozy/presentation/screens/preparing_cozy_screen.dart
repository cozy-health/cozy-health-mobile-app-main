import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/skeleton_loader.dart';

class PreparingCozyScreen extends StatefulWidget {
  const PreparingCozyScreen({super.key});

  @override
  State<PreparingCozyScreen> createState() => _PreparingCozyScreenState();
}

class _PreparingCozyScreenState extends State<PreparingCozyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: ScreenSkeleton());
}
