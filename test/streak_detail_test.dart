import 'package:cozy_health/core/repositories/home_repository.dart';
import 'package:cozy_health/core/repositories/streak_repository.dart';
import 'package:cozy_health/core/services/streak_controller.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/local_fonts.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/features/home/presentation/widgets/home_design_widgets.dart';
import 'package:cozy_health/features/settings/presentation/widgets/streak_progress_panel.dart';
import 'package:cozy_health/features/settings/data/wellness_progress.dart';
import 'streak_progress_test.dart' show baseline;

class StreakFixture extends HomeRepository {
  bool fail = false;
  @override
  Future<Map<String, dynamic>?> getCachedStreak() async => null;
  @override
  Future<Map<String, dynamic>> fetchStreak() async {
    if (fail) throw StateError('offline');
    return {
      'current_days': 7,
      'rest_days': 0,
      'earning_progress': 0,
      'local_date': '2026-10-09',
      'completed_dates': ['2026-10-07'],
      'protected_dates': ['2026-10-08'],
    };
  }
}

void main() {
  setUp(installLocalTestFonts);
  tearDown(resetLocalTestFonts);
  StreakController controllerFor(StreakFixture fixture) {
    final controller = StreakController(
      repository: StreakRepository(api: fixture),
      localMoods: () => [],
      moodChanges: const Stream.empty(),
      accountChanges: const Stream.empty(),
      syncResults: const Stream.empty(),
      tick: false,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  for (final dark in [false, true]) {
    testWidgets('protected day stays at seven with large text, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: StreakDetailScreen(
            streak: 99,
            controller: controllerFor(StreakFixture()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('99 days'), findsNothing);
      expect(find.text('0 of 2 rest days saved'), findsOneWidget);
      expect(find.text('2026-10-08 · Rest day used'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('failed fetch offers retry and then shows actual progress', (
    tester,
  ) async {
    final fixture = StreakFixture()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StreakDetailScreen(
          streak: 99,
          controller: controllerFor(fixture),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('99 days'), findsNothing);
    fixture.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('7 days'), findsOneWidget);
  });

  testWidgets(
    'Home and Profile panels show the same protected day and number',
    (tester) async {
      final progress = baseline().project(
        DateTime.utc(2026, 10, 9, 12),
        <MoodEntry>[],
      );
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  HomeRhythmCard(
                    entries: const [],
                    streak: progress.currentDays,
                    hasMoodToday: false,
                    progress: progress,
                    onStreak: () {},
                  ),
                  StreakProgressPanel(
                    progress: WellnessProgress(
                      moods: const [],
                      journals: const [],
                      now: DateTime.utc(2026, 10, 9),
                    ),
                    streak: progress,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7 day streak'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.byIcon(Icons.nightlight_outlined), findsNWidgets(2));
      expect(find.bySemanticsLabel(RegExp('rest day used')), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
