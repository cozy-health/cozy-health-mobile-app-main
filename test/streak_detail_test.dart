import 'package:cozy_health/core/repositories/home_repository.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/local_fonts.dart';

class StreakFixture extends HomeRepository {
  bool fail = false;
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
          home: StreakDetailScreen(streak: 99, repository: StreakFixture()),
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
        home: StreakDetailScreen(streak: 99, repository: fixture),
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
}
