import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';

void main() {
  runApp(const CozyHealthApp());
}

class CozyHealthApp extends StatelessWidget {
  const CozyHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cozy Health',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0460D8)),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
