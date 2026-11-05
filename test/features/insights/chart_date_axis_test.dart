import 'package:cozy_health/features/insights/presentation/widgets/chart_date_axis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [160.0, 272.0, 520.0]) {
    testWidgets('month axis fits width $width at twice normal text size', (
      tester,
    ) async {
      final days = List.generate(
        31,
        (i) => '10-${(i + 1).toString().padLeft(2, '0')}',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Center(
              child: SizedBox(
                width: width,
                child: ChartDateAxis(days: days),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('10-01'), findsOneWidget);
      if (width >= 192) expect(find.text('10-31'), findsOneWidget);
      expect(
        find.byType(Text).evaluate().length,
        lessThanOrEqualTo((width / 96).floor()),
      );
      expect(days, hasLength(31));
    });
  }

  testWidgets('empty and single-day axes render without invented dates', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChartDateAxis(days: [])));
    expect(find.byType(Text), findsNothing);
    await tester.pumpWidget(
      const MaterialApp(home: ChartDateAxis(days: ['10-01'])),
    );
    expect(find.text('10-01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
