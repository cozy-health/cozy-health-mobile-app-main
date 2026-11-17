import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/widgets/chip.dart' as design;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_support.dart';

Material chipMaterial(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(design.Chip), matching: find.byType(Material))
      .first,
);

void main() {
  sharedWidgetTestSetup();

  testWidgets('renders label and optional leading icon', (tester) async {
    await pumpSharedWidget(
      tester,
      const design.Chip(label: 'Happy', leading: Icon(Icons.mood)),
    );
    expect(find.text('Happy'), findsOneWidget);
    expect(find.byIcon(Icons.mood), findsOneWidget);
  });

  testWidgets('selected state has blue outline and pale fill', (tester) async {
    await pumpSharedWidget(
      tester,
      const design.Chip(label: 'Week', selected: true),
    );
    final material = chipMaterial(tester);
    expect(material.color, AppColors.accentSky);
    expect(
      (material.shape! as RoundedRectangleBorder).side.color,
      AppColors.primary,
    );
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(design.Chip),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.properties.selected, isTrue);
  });

  testWidgets('unselected state uses a surface and default border', (
    tester,
  ) async {
    await pumpSharedWidget(tester, const design.Chip(label: 'Month'));
    final material = chipMaterial(tester);
    expect(material.color, AppColors.surfaceLight);
    expect(
      (material.shape! as RoundedRectangleBorder).side.color,
      AppColors.borderDefault,
    );
  });

  testWidgets('tap calls owner without changing controlled selection', (
    tester,
  ) async {
    var taps = 0;
    await pumpSharedWidget(
      tester,
      design.Chip(label: 'Anxiety', onTap: () => taps++),
    );
    await tester.tap(find.text('Anxiety'));
    expect(taps, 1);
    expect(
      tester.widget<design.Chip>(find.byType(design.Chip)).selected,
      isFalse,
    );
  });

  testWidgets('all variants render and compact tags have radius eight', (
    tester,
  ) async {
    for (final variant in design.ChipVariant.values) {
      await pumpSharedWidget(
        tester,
        design.Chip(label: variant.name, variant: variant),
      );
      expect(find.text(variant.name), findsOneWidget);
      final shape = chipMaterial(tester).shape! as RoundedRectangleBorder;
      expect(
        shape.borderRadius,
        BorderRadius.circular(variant == design.ChipVariant.tag ? 8 : 16),
      );
    }
  });

  testWidgets('dark selected and unselected states use dark tokens', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      const design.Chip(label: 'Week', selected: true),
      brightness: Brightness.dark,
    );
    expect(chipMaterial(tester).color, AppColors.accentSkyDark);
    await pumpSharedWidget(
      tester,
      const design.Chip(label: 'Week'),
      brightness: Brightness.dark,
    );
    expect(chipMaterial(tester).color, AppColors.surfaceDark);
    expect(
      (chipMaterial(tester).shape! as RoundedRectangleBorder).side.color,
      AppColors.borderDefaultDark,
    );
  });

  testWidgets('custom fills and compact variant are supported', (tester) async {
    await pumpSharedWidget(
      tester,
      const design.Chip(
        label: 'Happy',
        compact: true,
        backgroundColor: AppColors.accentWarmYellow,
      ),
    );
    expect(chipMaterial(tester).color, AppColors.accentWarmYellow);
    expect(
      (chipMaterial(tester).shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(8),
    );
    await pumpSharedWidget(
      tester,
      const design.Chip(
        label: 'Happy',
        selected: true,
        selectedBackgroundColor: AppColors.accentSage,
      ),
    );
    expect(chipMaterial(tester).color, AppColors.accentSage);
  });

  testWidgets('long text scales without horizontal overflow', (tester) async {
    await pumpSharedWidget(
      tester,
      const design.Chip(
        label: 'Social and relationship wellbeing',
        leading: Icon(Icons.people),
      ),
      width: 180,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
