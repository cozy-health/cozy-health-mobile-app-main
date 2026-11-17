import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/widgets/illustrated_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_support.dart';

void main() {
  sharedWidgetTestSetup();

  testWidgets('renders title and description without optional content', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      const IllustratedCard(title: 'Journal', description: 'Reflect today'),
    );
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Reflect today'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('places illustration left of copy', (tester) async {
    await pumpSharedWidget(
      tester,
      const IllustratedCard(title: 'Quiz', illustration: Icon(Icons.mood)),
    );
    expect(
      tester.getCenter(find.byIcon(Icons.mood)).dx,
      lessThan(tester.getCenter(find.text('Quiz')).dx),
    );
  });

  testWidgets('places top illustration above copy', (tester) async {
    await pumpSharedWidget(
      tester,
      const IllustratedCard(
        title: 'Quiz',
        illustration: Icon(Icons.mood),
        illustrationPlacement: IllustrationPlacement.top,
      ),
    );
    expect(
      tester.getCenter(find.byIcon(Icons.mood)).dy,
      lessThan(tester.getCenter(find.text('Quiz')).dy),
    );
  });

  testWidgets('action invokes callback and shows chevron', (tester) async {
    var taps = 0;
    await pumpSharedWidget(
      tester,
      IllustratedCard(
        title: 'Quiz',
        actionLabel: 'Start',
        onAction: () => taps++,
      ),
    );
    await tester.tap(find.text('Start'));
    expect(taps, 1);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('action without callback is disabled', (tester) async {
    await pumpSharedWidget(
      tester,
      const IllustratedCard(title: 'Quiz', actionLabel: 'Start'),
    );
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
  });

  testWidgets('uses approved light and dark default surfaces', (tester) async {
    const card = IllustratedCard(title: 'Quiz');
    await pumpSharedWidget(tester, card);
    expect(
      firstBoxDecoration(tester, find.byType(IllustratedCard)).color,
      AppColors.surfaceSubtle,
    );
    await pumpSharedWidget(tester, card, brightness: Brightness.dark);
    expect(
      firstBoxDecoration(tester, find.byType(IllustratedCard)).color,
      AppColors.surfaceSubtleDark,
    );
    expect(
      tester.widget<Text>(find.text('Quiz')).style?.color,
      AppColors.textDark,
    );
  });

  testWidgets('respects custom background and radius', (tester) async {
    await pumpSharedWidget(
      tester,
      const IllustratedCard(
        title: 'Quiz',
        backgroundColor: AppColors.accentPeach,
      ),
    );
    final box = firstBoxDecoration(tester, find.byType(IllustratedCard));
    expect(box.color, AppColors.accentPeach);
    expect(box.borderRadius, BorderRadius.circular(8));
  });

  testWidgets('narrow layout and enlarged copy remain usable', (tester) async {
    await pumpSharedWidget(
      tester,
      IllustratedCard(
        title: 'Mental Health Quiz',
        description: 'Take time to reflect on your wellbeing.',
        illustration: const Icon(Icons.mood),
        actionLabel: 'Start Quiz',
        onAction: () {},
      ),
      width: 220,
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getCenter(find.byIcon(Icons.mood)).dy,
      lessThan(tester.getCenter(find.text('Mental Health Quiz')).dy),
    );
  });
}
