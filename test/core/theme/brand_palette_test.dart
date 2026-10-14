import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/app_theme.dart';

import '../../support/local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(installLocalTestFonts);
  tearDown(resetLocalTestFonts);
  test(
    'brand colors are exact and saved accents cannot introduce other colors',
    () {
      expect(AppColors.brandPalette.map((c) => c.toARGB32()), [
        0xff0460d8,
        0xff00bc4c,
        0xfff25c05,
        0xfff2cb05,
      ]);
      for (final color in AppColors.brandPalette) {
        expect(AppColors.resolveAccent(color.toARGB32().toString()), color);
        expect(
          AppColors.resolveAccent(
            '#${color.toARGB32().toRadixString(16).substring(2)}',
          ),
          color,
        );
      }
      for (final invalid in [
        null,
        'lavender',
        '#8B5CF6',
        '#zzzzzz',
        '4294967295',
      ]) {
        expect(AppColors.resolveAccent(invalid), AppColors.primary);
      }
    },
  );
  test(
    'both themes use black or white surfaces and identical brand accents',
    () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final background = theme.brightness == Brightness.dark
            ? Colors.black
            : Colors.white;
        expect(theme.scaffoldBackgroundColor, background);
        expect(theme.colorScheme.surface, background);
        expect(theme.colorScheme.surfaceContainer, background);
        expect(theme.colorScheme.primary, AppColors.primary);
        expect(theme.colorScheme.secondary, AppColors.success);
        expect(theme.colorScheme.tertiary, AppColors.warmYellow);
        expect(theme.colorScheme.onPrimary, Colors.white);
        expect(
          AppTheme.highContrast(theme).colorScheme.primary,
          AppColors.primary,
        );
      }
    },
  );
}
