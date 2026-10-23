import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/mood_artwork.dart';
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
        const labels = [
          'Angry',
          'Sad',
          'Good',
          'Upset',
          'Spectacular',
          'Happy',
        ];
        final readingOrder = List<String>.of(labels)
          ..sort((a, b) {
            final first = tester.getTopLeft(
              find.byKey(ValueKey('mood-category-${a.toLowerCase()}')),
            );
            final second = tester.getTopLeft(
              find.byKey(ValueKey('mood-category-${b.toLowerCase()}')),
            );
            return (first.dy - second.dy).abs() < 1
                ? first.dx.compareTo(second.dx)
                : first.dy.compareTo(second.dy);
          });
        expect(readingOrder, labels);
        for (final label in labels) {
          final tile = find.byKey(
            ValueKey('mood-category-${label.toLowerCase()}'),
          );
          final rect = tester.getRect(tile);
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.left, greaterThanOrEqualTo(16));
          expect(rect.right, lessThanOrEqualTo(width - 16));
          final artwork = tester.getRect(
            find.descendant(of: tile, matching: find.byType(MoodArtwork)),
          );
          final text = tester.getRect(find.text(label));
          expect(
            rect.contains(artwork.topLeft) &&
                rect.contains(artwork.bottomRight),
            isTrue,
            reason: '$label artwork fits',
          );
          expect(
            rect.contains(text.topLeft) && rect.contains(text.bottomRight),
            isTrue,
            reason: '$label label fits',
          );
        }
        if (scale == 1 && width == 375) {
          expect(
            tester.getSize(find.byType(HomeQuizCard)).height,
            greaterThanOrEqualTo(179),
          );
          expect(
            tester.getSize(find.byType(MoodChipsRow)).height,
            greaterThanOrEqualTo(48),
            reason: 'Home mood choices must meet the minimum touch target.',
          );
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
