import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/home/presentation/widgets/mood_chips_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'support/local_fonts.dart';

void main() {
  setUp(installLocalTestFonts);
  tearDown(resetLocalTestFonts);

  for (final brightness in Brightness.values) {
    testWidgets('Home moods are readable and navigate in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? mood;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: MoodChipsRow()),
          ),
          GoRoute(
            path: '/mood-feeling',
            builder: (_, state) {
              mood = state.uri.queryParameters['mood'];
              return const Scaffold(body: Text('Mood selected'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final control = find.ancestor(
        of: find.text('Angry'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(control).height, greaterThanOrEqualTo(56));
      expect(tester.widget<Text>(find.text('Angry')).style!.fontSize, 16);
      await tester.ensureVisible(find.text('Excited'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excited'));
      await tester.pumpAndSettle();
      expect(mood, 'excited');
      expect(tester.takeException(), isNull);
    });
  }
}
