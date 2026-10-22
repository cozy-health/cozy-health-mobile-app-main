import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/insights/presentation/screens/activity_mood_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/insights_home_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/mood_trend_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/sleep_mood_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/triggers_analysis_screen.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/quiz_progress_indicator.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/quiz_support_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/local_fonts.dart';

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  setUp(() => DemoMode.instance.enabled = true);
  tearDown(() => DemoMode.instance.enabled = false);

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    required bool reduce,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (_, child) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: child!,
      ),
      home: child,
    ),
  );

  for (final screen in <Widget>[
    const ActivityMoodScreen(),
    const InsightsHomeScreen(),
    const MoodTrendScreen(),
    const SleepMoodScreen(),
  ]) {
    testWidgets('${screen.runtimeType} stops an active entrance immediately', (
      tester,
    ) async {
      await mount(tester, screen, reduce: false);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await mount(tester, screen, reduce: true);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      if (screen is MoodTrendScreen) {
        await tester.tap(find.text('30 days'));
        await tester.pump();
        expect(tester.binding.transientCallbackCount, 0);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('quiz and trigger bars honor reduced motion', (tester) async {
    for (final screen in <Widget>[
      const Scaffold(
        body: QuizProgressIndicator(currentIndex: 2, totalQuestions: 9),
      ),
      const TriggersAnalysisScreen(),
    ]) {
      await mount(tester, screen, reduce: true);
      await tester.pump();
      final bars = tester.widgetList<TweenAnimationBuilder<double>>(
        find.byType(TweenAnimationBuilder<double>),
      );
      expect(bars, isNotEmpty);
      expect(bars.every((bar) => bar.duration == Duration.zero), isTrue);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
    'support sheet opens without motion and has accessible controls',
    (tester) async {
      await mount(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => QuizSupportSheet.show(context),
              child: const Text('Open support'),
            ),
          ),
        ),
        reduce: true,
      );
      await tester.tap(find.text('Open support'));
      await tester.pump();
      expect(find.text('Support is here for you'), findsOneWidget);
      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.animationController?.duration, Duration.zero);
      final semantics = tester.ensureSemantics();
      try {
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      } finally {
        semantics.dispose();
      }
      await tester.tap(find.text("I'm okay right now"));
      await tester.pump();
      expect(find.text('Support is here for you'), findsNothing);
    },
  );
}
