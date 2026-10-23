import 'package:cozy_health/features/crisis/presentation/screens/crisis_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('breathing has an explicit start and visible remaining time', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BreathingExerciseScreen()));
    expect(find.text('1:20 remaining'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('4 seconds'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'timer preserves progress through pauses and backgrounding and completes once',
    (tester) async {
      var now = Duration.zero;
      await tester.pumpWidget(
        MaterialApp(home: BreathingExerciseScreen(elapsed: () => now)),
      );
      Future<void> tap(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pump();
      }

      await tap('Start');
      now = const Duration(seconds: 3);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('1:17 remaining'), findsOneWidget);
      expect(find.text('1 seconds'), findsOneWidget);
      await tap('Pause');
      now = const Duration(seconds: 33);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1:17 remaining'), findsOneWidget);
      await tap('Resume');
      now = const Duration(seconds: 34);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Hold'), findsOneWidget);
      expect(find.text('7 seconds'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      await tester.pump();
      now = const Duration(seconds: 64);
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('1:16 remaining'), findsOneWidget);
      await tap('Resume');
      now = const Duration(seconds: 140);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('You did it.'), findsOneWidget);
      await tap('Restart');
      expect(find.text('1:20 remaining'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
