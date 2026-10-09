import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/widgets/icon_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_support.dart';

Material iconChipMaterial(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(IconChip), matching: find.byType(Material))
      .first,
);

void main() {
  sharedWidgetTestSetup();

  testWidgets('renders label and icon at normal compact height', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      const IconChip(label: 'Work', icon: Icon(Icons.work)),
    );
    expect(find.text('Work'), findsOneWidget);
    expect(find.byIcon(Icons.work), findsOneWidget);
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byType(IconChip),
              matching: find.byType(InkWell),
            ),
          )
          .height,
      28,
    );
  });

  testWidgets('selected state has primary outline', (tester) async {
    await pumpSharedWidget(
      tester,
      const IconChip(label: 'Work', icon: Icon(Icons.work), selected: true),
    );
    expect(
      (iconChipMaterial(tester).shape! as RoundedRectangleBorder).side.color,
      AppColors.primary,
    );
  });

  testWidgets('unselected state has no selected outline', (tester) async {
    await pumpSharedWidget(
      tester,
      const IconChip(label: 'Work', icon: Icon(Icons.work)),
    );
    expect(
      (iconChipMaterial(tester).shape! as RoundedRectangleBorder).side,
      BorderSide.none,
    );
  });

  testWidgets('tap invokes callback without toggling state', (tester) async {
    var taps = 0;
    await pumpSharedWidget(
      tester,
      IconChip(
        label: 'Work',
        icon: const Icon(Icons.work),
        onTap: () => taps++,
      ),
    );
    await tester.tap(find.text('Work'));
    expect(taps, 1);
    expect(tester.widget<IconChip>(find.byType(IconChip)).selected, isFalse);
  });

  testWidgets('dark surface and badge use parallel tokens', (tester) async {
    await pumpSharedWidget(
      tester,
      const IconChip(label: 'Work', icon: Icon(Icons.work)),
      brightness: Brightness.dark,
    );
    expect(iconChipMaterial(tester).color, AppColors.surfaceSubtleDark);
    expect(
      firstBoxDecoration(tester, find.byType(IconChip)).color,
      AppColors.accentSkyDark,
    );
    expect(
      tester.widget<Text>(find.text('Work')).style?.color,
      AppColors.textDark,
    );
  });

  testWidgets('custom category colors and badge radius are honored', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      const IconChip(
        label: 'Work',
        icon: Icon(Icons.work),
        backgroundColor: AppColors.accentSage,
        badgeColor: AppColors.accentPeach,
      ),
    );
    expect(iconChipMaterial(tester).color, AppColors.accentSage);
    expect(
      firstBoxDecoration(tester, find.byType(IconChip)).color,
      AppColors.accentPeach,
    );
    expect(
      (iconChipMaterial(tester).shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(8),
    );
  });

  testWidgets('selection and tap are available to accessibility', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      IconChip(
        label: 'Work',
        icon: const Icon(Icons.work),
        selected: true,
        onTap: () {},
      ),
    );
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(IconChip),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.properties.selected, isTrue);
    expect(semantics.properties.onTap, isNotNull);
  });

  testWidgets('large text grows past nominal height instead of clipping', (
    tester,
  ) async {
    await pumpSharedWidget(
      tester,
      const IconChip(label: 'Lack of communication', icon: Icon(Icons.chat)),
      width: 180,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byType(IconChip),
              matching: find.byType(InkWell),
            ),
          )
          .height,
      greaterThan(28),
    );
  });
}
