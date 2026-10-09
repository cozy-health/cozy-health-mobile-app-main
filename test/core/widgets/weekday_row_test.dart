import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/widgets/weekday_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_support.dart';

List<WeekdayItem> withFirst(WeekdayItem first) => [
  first,
  const WeekdayItem(label: 'Tue'),
  const WeekdayItem(label: 'Wed'),
  const WeekdayItem(label: 'Thur'),
  const WeekdayItem(label: 'Fri'),
  const WeekdayItem(label: 'Sat'),
  const WeekdayItem(label: 'Sun'),
];

void main() {
  sharedWidgetTestSetup();

  testWidgets('renders exactly seven labelled circles', (tester) async {
    await pumpSharedWidget(tester, const WeekdayRow());
    for (final label in ['Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(label), findsOneWidget);
    }
    final circles = find.descendant(
      of: find.byType(WeekdayRow),
      matching: find.byType(Container),
    );
    expect(circles, findsNWidgets(7));
    expect(tester.getSize(circles.first), const Size(15, 15));
  });

  testWidgets('filled day supports a custom mood color', (tester) async {
    await pumpSharedWidget(
      tester,
      WeekdayRow(
        days: withFirst(
          const WeekdayItem(
            label: 'Mon',
            filled: true,
            color: AppColors.accentPeach,
          ),
        ),
      ),
    );
    final box = firstBoxDecoration(tester, find.byType(WeekdayRow));
    expect(box.color, AppColors.accentPeach);
    expect(box.border, isNull);
  });

  testWidgets('unfilled day is outlined rather than filled', (tester) async {
    await pumpSharedWidget(tester, const WeekdayRow());
    final box = firstBoxDecoration(tester, find.byType(WeekdayRow));
    expect(box.color, isNull);
    expect((box.border! as Border).top.color, AppColors.borderDefault);
  });

  testWidgets('day tap reaches the owner callback', (tester) async {
    var taps = 0;
    await pumpSharedWidget(
      tester,
      WeekdayRow(
        days: withFirst(WeekdayItem(label: 'Mon', onTap: () => taps++)),
      ),
    );
    await tester.tap(find.text('Mon'));
    expect(taps, 1);
  });

  testWidgets('inner completion indicator uses configured color', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      WeekdayRow(
        days: withFirst(
          const WeekdayItem(
            label: 'Mon',
            filled: true,
            indicator: Icon(Icons.check),
          ),
        ),
        indicatorColor: AppColors.accentRose,
      ),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      IconTheme.of(tester.element(find.byIcon(Icons.check))).color,
      AppColors.accentRose,
    );
  });

  testWidgets('dark outline and label use the active theme', (tester) async {
    await pumpSharedWidget(
      tester,
      const WeekdayRow(),
      brightness: Brightness.dark,
    );
    expect(
      (firstBoxDecoration(tester, find.byType(WeekdayRow)).border! as Border)
          .top
          .color,
      AppColors.borderDefaultDark,
    );
    expect(
      tester.widget<Text>(find.text('Mon')).style?.color,
      AppColors.textDark,
    );
  });

  testWidgets('accessible day status and tap action are exposed', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      WeekdayRow(
        days: withFirst(
          WeekdayItem(
            label: 'Mon',
            filled: true,
            semanticLabel: 'Monday, journal written',
            onTap: () {},
          ),
        ),
      ),
    );
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(WeekdayRow),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.properties.label, 'Monday, journal written');
    expect(semantics.properties.value, 'Recorded');
    expect(semantics.properties.onTap, isNotNull);
  });

  testWidgets('labels support large text on a narrow phone', (tester) async {
    await pumpSharedWidget(
      tester,
      const WeekdayRow(),
      width: 280,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
