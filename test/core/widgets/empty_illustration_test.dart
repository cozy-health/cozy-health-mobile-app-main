import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/widgets/app_button.dart';
import 'package:cozy_health/core/widgets/empty_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_support.dart';

void main() {
  sharedWidgetTestSetup();

  testWidgets('renders heading message and default bell', (tester) async {
    await pumpSharedWidget(
      tester,
      const EmptyIllustration(
        heading: 'Notifications',
        message: 'Check back later',
      ),
    );
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Check back later'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  testWidgets('supports a supplied illustration instead of the bell', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      const EmptyIllustration(
        heading: 'Mood history',
        message: 'Start a check-in',
        illustration: Icon(Icons.mood),
      ),
    );
    expect(find.byIcon(Icons.mood), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsNothing);
  });

  testWidgets('no action label means no CTA', (tester) async {
    await pumpSharedWidget(
      tester,
      const EmptyIllustration(heading: 'Empty', message: 'Nothing yet'),
    );
    expect(find.byType(AppButton), findsNothing);
  });

  testWidgets('CTA invokes owner callback', (tester) async {
    var taps = 0;
    await pumpSharedWidget(
      tester,
      EmptyIllustration(
        heading: 'Empty',
        message: 'Nothing yet',
        actionLabel: 'Try again',
        onAction: () => taps++,
      ),
    );
    await tester.tap(find.text('Try again'));
    expect(taps, 1);
  });

  testWidgets('CTA without callback uses existing disabled-button behavior', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      const EmptyIllustration(
        heading: 'Empty',
        message: 'Nothing yet',
        actionLabel: 'Try again',
      ),
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('dark icon and copy use active theme tokens', (tester) async {
    await pumpSharedWidget(
      tester,
      const EmptyIllustration(heading: 'Empty', message: 'Nothing yet'),
      brightness: Brightness.dark,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.notifications_none)).color,
      AppColors.borderDefaultDark,
    );
    expect(
      tester.widget<Text>(find.text('Empty')).style?.color,
      AppColors.textDark,
    );
    expect(
      tester.widget<Text>(find.text('Nothing yet')).style?.color,
      AppColors.textMutedDark,
    );
  });

  testWidgets('illustration size and copy alignment are configurable', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      const EmptyIllustration(
        heading: 'Empty',
        message: 'Nothing yet',
        icon: Icons.mood,
        illustrationSize: 96,
      ),
    );
    expect(tester.getSize(find.byIcon(Icons.mood)), const Size(96, 96));
    expect(
      tester.widget<Text>(find.text('Nothing yet')).textAlign,
      TextAlign.center,
    );
  });

  testWidgets('long copy with enlarged text remains scrollable', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      EmptyIllustration(
        heading: 'No notifications available',
        message:
            'Your notifications will appear here. Check back later for updates and reminders.',
        actionLabel: 'Return home',
        onAction: () {},
      ),
      width: 220,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Return home'));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
