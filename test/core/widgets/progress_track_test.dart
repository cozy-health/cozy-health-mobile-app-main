import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/progress_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_support.dart';

Finder fill() => find.descendant(
  of: find.byType(FractionallySizedBox),
  matching: find.byType(DecoratedBox),
);

void main() {
  sharedWidgetTestSetup();

  testWidgets('renders a four-pixel track with proportional fill', (
    tester,
  ) async {
    await pumpSharedWidget(tester, const ProgressTrack(value: 0.25));
    expect(tester.getSize(find.byType(ProgressTrack)), const Size(343, 4));
    expect(tester.getSize(fill()).width, closeTo(343 / 4, 0.01));
  });

  testWidgets('zero progress has no visible fill width', (tester) async {
    await pumpSharedWidget(tester, const ProgressTrack(value: 0));
    expect(tester.getSize(fill()).width, 0);
  });

  testWidgets('complete progress fills the track', (tester) async {
    await pumpSharedWidget(tester, const ProgressTrack(value: 1));
    expect(tester.getSize(fill()).width, 343);
  });

  testWidgets('values outside the range clamp safely', (tester) async {
    await pumpSharedWidget(tester, const ProgressTrack(value: -0.5));
    expect(tester.getSize(fill()).width, 0);
    await pumpSharedWidget(tester, const ProgressTrack(value: 2));
    expect(tester.getSize(fill()).width, 343);
  });

  testWidgets('twelve-pixel variant has matching half-height radius', (
    tester,
  ) async {
    await pumpSharedWidget(tester, const ProgressTrack(value: 0.5, height: 12));
    expect(tester.getSize(find.byType(ProgressTrack)).height, 12);
    expect(
      firstBoxDecoration(tester, find.byType(ProgressTrack)).borderRadius,
      BorderRadius.circular(6),
    );
    expect(
      (tester.widget<DecoratedBox>(fill()).decoration as BoxDecoration)
          .borderRadius,
      BorderRadius.circular(6),
    );
  });

  testWidgets('dark track and custom paints use theme or overrides', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      const ProgressTrack(value: 0.5),
      brightness: Brightness.dark,
    );
    expect(
      firstBoxDecoration(tester, find.byType(ProgressTrack)).color,
      AppColors.borderSubtleDark,
    );
    expect(
      (tester.widget<DecoratedBox>(fill()).decoration as BoxDecoration).color,
      AppTheme.dark.colorScheme.primary,
    );
    await pumpSharedWidget(
      tester,
      const ProgressTrack(
        value: 0.5,
        trackColor: AppColors.accentPeach,
        fillColor: AppColors.accentRose,
      ),
    );
    expect(
      firstBoxDecoration(tester, find.byType(ProgressTrack)).color,
      AppColors.accentPeach,
    );
    expect(
      (tester.widget<DecoratedBox>(fill()).decoration as BoxDecoration).color,
      AppColors.accentRose,
    );
  });

  testWidgets('announces label and percentage without a tap action', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      const ProgressTrack(value: 0.5, semanticLabel: 'Quiz progress'),
    );
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(ProgressTrack),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.properties.label, 'Quiz progress');
    expect(semantics.properties.value, '50%');
    expect(semantics.properties.onTap, isNull);
  });

  testWidgets('fill follows right-to-left reading direction', (tester) async {
    await pumpSharedWidget(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: ProgressTrack(value: 0.25),
      ),
    );
    expect(
      tester.getRect(fill()).right,
      tester.getRect(find.byType(ProgressTrack)).right,
    );
  });
}
