import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/app_pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'keyboard activation and disabled semantics match touch behavior',
    (tester) async {
      var taps = 0;
      var enabled = true;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return AppPressable(
                    label: 'Choose response',
                    checked: true,
                    onPressed: enabled ? () => taps++ : null,
                    child: const Text('Response'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      final semantics = tester.ensureSemantics();
      try {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(taps, 2);
        expect(
          tester.getSize(find.byType(AppPressable)).height,
          greaterThanOrEqualTo(48),
        );
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Choose response'))
              .getSemanticsData()
              .label,
          'Choose response',
        );
        rebuild(() => enabled = false);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.tap(find.byType(AppPressable));
        expect(taps, 2);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('reduced motion keeps press feedback stationary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: AppPressable(
                onPressed: () {},
                child: const Text('Continue'),
              ),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppPressable)),
    );
    await tester.pump();
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 1);
    expect(scale.duration, Duration.zero);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
