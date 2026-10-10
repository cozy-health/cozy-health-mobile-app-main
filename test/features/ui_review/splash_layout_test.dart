import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/splash/presentation/screens/splash_screen.dart';
import '../../support/local_fonts.dart';

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  for (final dark in [false, true]) {
    for (final size in [const Size(375, 667), const Size(667, 375)]) {
      testWidgets(
        'Splash stays readable and navigates, dark=$dark, size=$size',
        (tester) async {
          FlutterSecureStorage.setMockInitialValues({});
          SharedPreferences.setMockInitialValues({
            'install_marker_set': true,
            'has_completed_onboarding': true,
          });
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final router = GoRouter(
            initialLocation: '/splash',
            routes: [
              GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
              GoRoute(
                path: AppRouter.welcome,
                builder: (_, _) =>
                    const Scaffold(body: Text('Welcome destination')),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            MaterialApp.router(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.6)),
                child: child!,
              ),
              routerConfig: router,
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(milliseconds: 1600));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pump();
          expect(find.text('Welcome destination'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
