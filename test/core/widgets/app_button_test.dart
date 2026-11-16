import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/local_fonts.dart';

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  for (final dark in [false, true]) {
    testWidgets('disabled action retains a visible surface, dark=$dark', (
      tester,
    ) async {
      final theme = dark ? AppTheme.dark : AppTheme.light;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: Center(child: AppButton(text: 'Save changes')),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppButton),
              matching: find.byType(Container),
            )
            .first,
      );
      final fill = (container.decoration! as BoxDecoration).color;
      expect(fill, isNot(theme.colorScheme.surface));
      expect(tester.takeException(), isNull);
    });
  }
}
