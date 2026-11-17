import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_intensity_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

bool containsValue(SemanticsNode node, String value) {
  if (node.value == value) return true;
  var found = false;
  node.visitChildren((child) {
    found = containsValue(child, value) || found;
    return true;
  });
  return found;
}

void main() {
  for (final reducedMotion in [false, true]) {
    testWidgets(
      'intensity feedback and semantics, reduced motion $reducedMotion',
      (tester) async {
        var value = 3;
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reducedMotion),
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, update) => MoodIntensityControl(
                    value: value,
                    feeling: 'Resentful',
                    onChanged: (next) => update(() => value = next),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('Moderate · 3/5'), findsOneWidget);
        final preview = find.byKey(const ValueKey('intensity-visual-layer-3'));
        final initialWidth = tester
            .widget<AnimatedContainer>(preview)
            .constraints!
            .maxWidth;
        const labels = ['Slight', 'Mild', 'Moderate', 'Strong', 'Very strong'];
        for (var level = 1; level <= 5; level++) {
          tester.widget<Slider>(find.byType(Slider)).onChanged!(
            level.toDouble(),
          );
          await tester.pumpAndSettle();
          expect(value, level);
          expect(find.text('${labels[level - 1]} · $level/5'), findsOneWidget);
          expect(
            containsValue(
              tester.getSemantics(find.bySemanticsLabel('Resentful intensity')),
              '${labels[level - 1]}, $level out of 5',
            ),
            isTrue,
          );
        }
        final last = tester.widget<AnimatedContainer>(preview);
        expect(last.constraints!.maxWidth, greaterThan(initialWidth));
        expect(last.duration, Duration(milliseconds: reducedMotion ? 0 : 200));

        // Exercise the actual tap gesture, rather than only the callback.
        final rect = tester.getRect(find.byType(Slider));
        await tester.tapAt(Offset(rect.left + 25, rect.center.dy));
        await tester.pumpAndSettle();
        expect(value, 1);
        semantics.dispose();
      },
    );
  }
}
