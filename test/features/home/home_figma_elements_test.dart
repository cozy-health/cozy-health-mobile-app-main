import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/home/presentation/widgets/home_quiz_card.dart';
import 'package:cozy_health/features/home/presentation/widgets/mood_chips_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/local_fonts.dart';

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);

  for (final width in [320.0, 375.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('Figma home elements fit width $width at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      MoodChipsRow(),
                      SizedBox(height: 24),
                      HomeQuizCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getTopLeft(find.text('Angry')).dx,
          lessThan(tester.getTopLeft(find.text('Sad')).dx),
        );
        expect(
          tester.getTopLeft(find.text('Sad')).dx,
          lessThan(tester.getTopLeft(find.text('Good')).dx),
        );
        if (scale == 1 && width == 375) {
          expect(
            tester.getSize(find.byType(HomeQuizCard)).height,
            greaterThanOrEqualTo(179),
          );
          expect(tester.getSize(find.byType(MoodChipsRow)).height, 45);
        }
      });
    }
  }

  testWidgets(
    'Figma emotion chips still pass the selected mood to navigation',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: MoodChipsRow()),
          ),
          GoRoute(
            path: '/mood-feeling',
            builder: (_, state) => Scaffold(
              body: Text('Selected ${state.uri.queryParameters['mood']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Angry'));
      await tester.pumpAndSettle();
      expect(find.text('Selected angry'), findsOneWidget);
    },
  );
}
