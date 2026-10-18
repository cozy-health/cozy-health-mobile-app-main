import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/home/presentation/widgets/mood_chips_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'support/local_fonts.dart';
import 'support/mood_review_capture.dart';

void main() {
  setUp(
    () => installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    ),
  );
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
      expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      expect(tester.widget<Text>(find.text('Angry')).style!.fontSize, 12);
      expect(find.text('Calm'), findsNothing);
      expect(find.text('Anxious'), findsNothing);
      expect(find.text('Spectacular'), findsOneWidget);
      await tester.ensureVisible(find.text('Happy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Happy'));
      await tester.pumpAndSettle();
      expect(mood, 'happy');
      expect(tester.takeException(), isNull);
    });
  }

  for (final slug in [
    'angry',
    'sad',
    'good',
    'upset',
    'spectacular',
    'happy',
  ]) {
    testWidgets('reference Home option $slug opens the matching group', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 240);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? selected;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How are you feeling?'),
                    SizedBox(height: 16),
                    MoodChipsRow(),
                  ],
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/mood-feeling',
            builder: (_, state) {
              selected = state.uri.queryParameters['mood'];
              return const Scaffold(body: Text('Mood selected'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          builder: (_, child) =>
              RepaintBoundary(key: const ValueKey('capture'), child: child!),
        ),
      );
      await tester.pumpAndSettle();
      final label = '${slug[0].toUpperCase()}${slug.substring(1)}';
      await tester.ensureVisible(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );
      await tester.pumpAndSettle();
      await captureMoodReview(tester, 'home-$slug');
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(selected, slug);
      router.pop();
      await tester.pumpAndSettle();
      final semantics = tester.ensureSemantics();
      final option = find.ancestor(
        of: find.text(label),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(option).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(option),
        matchesSemantics(
          label: label,
          hint: 'Open mood check-in',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('capture the complete reference Home mood strip', (tester) async {
    tester.view.physicalSize = const Size(760, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: MoodChipsRow()),
        ),
        builder: (_, child) =>
            RepaintBoundary(key: const ValueKey('capture'), child: child!),
      ),
    );
    await tester.pumpAndSettle();
    await captureMoodReview(tester, 'home-full-strip');
  });
}
