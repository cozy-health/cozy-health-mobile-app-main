import 'package:cozy_health/features/settings/presentation/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cozy_health/gen/assets.gen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets(
    'About displays installed version and build instead of mock data',
    (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Cozy Health',
        packageName: 'com.cozyhealth.app',
        version: '1.2.3',
        buildNumber: '105',
        buildSignature: '',
      );
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
      await tester.pumpAndSettle();
      final identity = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(identity.data, contains('Version 1.2.3 (build 105)'));
      expect(find.text('Version 1.0.0 (build 42)'), findsNothing);
      final logo = tester.widget<SvgPicture>(
        find.byKey(const ValueKey('about-cozy-logo')),
      );
      expect((logo.bytesLoader as SvgAssetLoader).assetName, Assets.svg.logo);
      expect(logo.semanticsLabel, 'Cozy Health logo');
      expect(logo.fit, BoxFit.contain);
      expect(find.byIcon(Icons.favorite), findsNothing);
      const sha = String.fromEnvironment('BUILD_SHA');
      const run = String.fromEnvironment('BUILD_RUN_ID');
      if (sha.isNotEmpty) expect(identity.data, contains('Commit $sha'));
      if (run.isNotEmpty) expect(identity.data, contains('CI run $run'));
    },
  );
}
