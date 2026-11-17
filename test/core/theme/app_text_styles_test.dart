import 'package:cozy_health/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);

  test('new role aliases retain the existing Outfit scale', () {
    expect(AppTextStyles.display.fontSize, 32);
    expect(AppTextStyles.h1, AppTextStyles.heading1);
    expect(AppTextStyles.h2, AppTextStyles.heading2);
    expect(AppTextStyles.h3, AppTextStyles.heading3);
    expect(AppTextStyles.bodyLarge, AppTextStyles.body1);
    expect(AppTextStyles.body, AppTextStyles.body2);
    expect(AppTextStyles.button, AppTextStyles.buttonText);
  });

  test('small copy and emphasized labels use consistent scale steps', () {
    expect(AppTextStyles.bodySmall.fontSize, 12);
    expect(AppTextStyles.caption, AppTextStyles.bodySmall);
    expect(AppTextStyles.label.fontSize, 14);
    expect(AppTextStyles.label.fontWeight, FontWeight.w600);
    expect(AppTextStyles.buttonSmall.fontSize, 14);
    expect(AppTextStyles.buttonSmall.fontWeight, FontWeight.w600);
  });

  test('legacy styles keep their sizes and weights', () {
    expect(AppTextStyles.heading1.fontSize, 24);
    expect(AppTextStyles.heading1.fontWeight, FontWeight.bold);
    expect(AppTextStyles.heading2.fontSize, 20);
    expect(AppTextStyles.heading3.fontSize, 18);
    expect(AppTextStyles.body1.fontSize, 16);
    expect(AppTextStyles.body2.fontSize, 14);
    expect(AppTextStyles.buttonText.fontSize, 16);
    expect(AppTextStyles.linkText.fontSize, 14);
  });
}
