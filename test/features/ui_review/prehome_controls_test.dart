import 'package:cozy_health/features/personalization/presentation/screens/personalization_screen.dart';
import 'package:cozy_health/features/auth/presentation/screens/congratulations_screen.dart';
import 'package:cozy_health/core/api/api_client.dart';
import '../../audit/auth_reset_audit_test.dart' show AuditTransport;
import 'dart:io';
import 'package:cozy_health/utils/screen_util.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/auth/presentation/widgets/auth_ui.dart';
import 'package:cozy_health/features/auth/presentation/screens/create_account_screen.dart';
import 'package:cozy_health/features/auth/presentation/screens/login_screen.dart';
import 'package:cozy_health/features/auth/presentation/screens/welcome_screen.dart';
import 'package:cozy_health/features/auth/presentation/screens/forgot_password_screen.dart';
import '../../support/local_fonts.dart';

void main() {
  setUpAll(
    () => installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    ),
  );
  tearDownAll(resetLocalTestFonts);
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    bool dark = false,
    bool large = false,
    bool keyboard = false,
    bool landscape = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = landscape
        ? const Size(667, 375)
        : const Size(320, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: large
            ? AppTheme.highContrast(dark ? AppTheme.dark : AppTheme.light)
            : dark
            ? AppTheme.dark
            : AppTheme.light,
        builder: (context, child) {
          ScreenUtil.init(context);
          return RepaintBoundary(
            key: const ValueKey('prehome-capture'),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(large ? 2 : 1),
                highContrast: large,
                disableAnimations: true,
                viewInsets: EdgeInsets.only(bottom: keyboard ? 280 : 0),
              ),
              child: child!,
            ),
          );
        },
        home: child,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> snap(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('PREHOME_CAPTURE')) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('prehome-capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final folder = Directory('../output/prehome-captures');
      await folder.create(recursive: true);
      await File(
        '${folder.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final mode in [
    'light',
    'dark',
    'large-light',
    'large-dark',
    'keyboard',
    'landscape',
  ]) {
    for (final entry in <String, Widget>{
      'welcome': const WelcomeScreen(),
      'login': const LoginScreen(),
      'registration': const CreateAccountScreen(),
      'reset': const ForgotPasswordScreen(),
      'personalization': const PersonalizationScreen(),
      'congratulations': const CongratulationsScreen(),
    }.entries) {
      testWidgets('${entry.key} layout $mode', (tester) async {
        await mount(
          tester,
          entry.value,
          dark: mode.contains('dark'),
          large: mode.startsWith('large'),
          keyboard: mode == 'keyboard',
          landscape: mode == 'landscape',
        );
        await snap(tester, '${entry.key}-$mode');
        if (entry.key == 'login' || entry.key == 'registration') {
          final key = entry.key == 'login'
              ? 'auth-stay-logged-in'
              : 'auth-terms-consent';
          final row = find.byKey(ValueKey(key));
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          final before = tester.widget<AuthSelectionRow>(row).value;
          await tester.tap(
            find.text(tester.widget<AuthSelectionRow>(row).label),
          );
          await tester.pumpAndSettle();
          expect(tester.widget<AuthSelectionRow>(row).value, !before);
          expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
          await snap(tester, '${entry.key}-$mode-selection');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'email input configuration and password visibility are explicit',
    (tester) async {
      final email = TextEditingController();
      final password = TextEditingController();
      addTearDown(email.dispose);
      addTearDown(password.dispose);
      await mount(
        tester,
        Scaffold(
          body: ListView(
            children: [
              AuthTextField(
                label: 'Email',
                controller: email,
                keyboardType: TextInputType.emailAddress,
              ),
              AuthTextField(
                label: 'Password',
                controller: password,
                obscure: true,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      );
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.first.autocorrect, false);
      expect(fields.first.enableSuggestions, false);
      expect(fields.first.textInputAction, TextInputAction.next);
      expect(fields.last.obscureText, true);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<TextField>(find.byType(TextField)).last.obscureText,
        false,
      );
      expect(find.byTooltip('Hide password'), findsOneWidget);
    },
  );

  for (final mode in ['light', 'large-dark', 'keyboard', 'landscape']) {
    testWidgets('reset code and success remain reachable $mode', (
      tester,
    ) async {
      final api = ApiClient();
      final previous = api.transportForTesting;
      api.transportForTesting = AuditTransport();
      addTearDown(() => api.transportForTesting = previous);
      await mount(
        tester,
        const ForgotPasswordScreen(),
        dark: mode.contains('dark'),
        large: mode.startsWith('large'),
        keyboard: mode == 'keyboard',
        landscape: mode == 'landscape',
      );
      await tester.enterText(
        find.byType(EditableText).first,
        'audit@example.test',
      );
      await tester.ensureVisible(find.text('Send Code'));
      await tester.tap(find.text('Send Code'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await snap(tester, 'reset-code-$mode');
      await tester.enterText(find.byType(EditableText).first, '123456');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Code verified'), findsNothing);
      final fields = find.byType(EditableText);
      await tester.enterText(fields.first, 'SyntheticPass9!');
      await tester.enterText(fields.last, 'SyntheticPass9!');
      await tester.ensureVisible(find.text('Reset Password'));
      await snap(tester, 'reset-new-password-$mode');
      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();
      expect(find.text("You're all set."), findsOneWidget);
      await tester.ensureVisible(find.text('Log In'));
      expect(find.text('Log In').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await snap(tester, 'reset-success-$mode');
    });
  }
}
