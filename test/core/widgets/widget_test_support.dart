import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/local_fonts.dart';

void sharedWidgetTestSetup() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
}

Future<void> pumpSharedWidget(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double width = 343,
  double textScale = 1,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      themeAnimationDuration: Duration.zero,
      theme:
          theme ??
          (brightness == Brightness.dark ? AppTheme.dark : AppTheme.light),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            platformBrightness: brightness,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

BoxDecoration firstBoxDecoration(WidgetTester tester, Finder root) {
  return tester
      .widgetList<Container>(
        find.descendant(of: root, matching: find.byType(Container)),
      )
      .map((container) => container.decoration)
      .whereType<BoxDecoration>()
      .first;
}
