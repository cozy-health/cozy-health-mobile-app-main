import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/services/consent_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/widgets/consent_gate.dart';
import 'local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(
    () => installLocalTestFonts(
      useRealFonts: true,
      visualFontPath: 'test/golden_assets/Outfit.ttf',
    ),
  );
  tearDownAll(resetLocalTestFonts);
  for (final dark in [false, true]) {
    for (final accent in {
      'blue': AppColors.primary,
      'green': AppColors.warmGreen,
      'orange': AppColors.warmOrange,
      'yellow': AppColors.warmYellow,
    }.entries) {
      for (final large in [false, true]) {
        for (final screen in ['consent']) {
          testWidgets(
            '$screen ${dark ? 'dark' : 'light'} ${accent.key} ${large ? 'large' : 'normal'}',
            (tester) async {
              FlutterSecureStorage.setMockInitialValues({});
              SharedPreferences.setMockInitialValues({});
              await TokenStorage().saveToken(
                'screenshot-fixture',
                stayLoggedIn: false,
              );
              tester.view.physicalSize = Size(large ? 320 : 390, 844);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final consent = ConsentService(
                token: () async => 'screenshot-fixture',
                get: (path) async => path == '/config'
                    ? {
                        'consent': {
                          'enforce_blocking': true,
                          'documents': {
                            'health_data': {
                              'title': 'Health data consent',
                              'version': 'review-fixture-1',
                              'published': true,
                              'required': true,
                              'content':
                                  'Screenshot fixture only. This is not published legal text.\n\nReview how your health information is used and stored. You can withdraw your permission in privacy settings.',
                            },
                          },
                        },
                      }
                    : {'owner_id': 1, 'data': []},
              );
              final boundary = GlobalKey();
              await tester.pumpWidget(
                RepaintBoundary(
                  key: boundary,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.withAccent(
                      dark ? AppTheme.dark : AppTheme.light,
                      accent.value,
                    ),
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(large ? 1.8 : 1),
                      ),
                      child: child!,
                    ),
                    home: ConsentGate(
                      service: consent,
                      observeRoutes: false,
                      child: const Text('Private content'),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final output = Directory('build/approved-plan-review');
              await tester.runAsync(() async {
                await output.create(recursive: true);
                final render =
                    boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final image = await render.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                if (bytes == null) throw StateError('Screenshot unavailable');
                await File(
                  '${output.path}/$screen-${dark ? 'dark' : 'light'}-${accent.key}-${large ? 'large' : 'normal'}.png',
                ).writeAsBytes(bytes.buffer.asUint8List());
                image.dispose();
              });
              await tester.pumpWidget(const SizedBox());
            },
          );
        }
      }
    }
  }
}
