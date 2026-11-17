import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/wellness_panel.dart';
import 'package:cozy_health/features/auth/data/signin_security.dart';
import 'package:cozy_health/features/auth/presentation/screens/signin_protection_screen.dart';
import 'package:cozy_health/features/auth/presentation/widgets/auth_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/local_fonts.dart';
import '../../support/signin_protection_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clearToken();
  });

  Future<void> open(
    WidgetTester tester,
    ProtectionAuth auth, {
    bool settings = false,
    bool dark = false,
    PendingSignIn? pending,
  }) async {
    var authenticated = false;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(dark ? 2 : 1)),
            child: child!,
          ),
          home: StatefulBuilder(
            builder: (context, update) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final value = await Navigator.of(context)
                      .push<Map<String, dynamic>>(
                        MaterialPageRoute(
                          builder: (_) => SignInProtectionScreen(
                            auth: auth,
                            settings: settings,
                            attempt: settings
                                ? null
                                : pending ?? attempt(auth.now),
                          ),
                        ),
                      );
                  update(() => authenticated = value != null);
                },
                child: Text(
                  authenticated ? 'Authenticated' : 'Start test sign-in',
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.tap(find.text('Start test sign-in'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(finder);
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    final field = find.descendant(
      of: find.byKey(key),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pump();
  }

  testWidgets(
    'bootstrap code does not open private content before enrollment; cancellation clears answers',
    (tester) async {
      final auth = ProtectionAuth();
      await open(tester, auth);
      await enter(tester, const ValueKey('protection-email-code'), '123456');
      await tap(tester, find.byKey(const ValueKey('protection-verify')));
      expect(auth.finishes, 0);
      expect(find.text('Authenticated'), findsNothing);
      for (var i = 0; i < 3; i++) {
        await enter(
          tester,
          ValueKey('protection-enrollment-answer-$i'),
          'private test answer',
        );
        final field = find.descendant(
          of: find.byKey(ValueKey('protection-enrollment-answer-$i')),
          matching: find.byType(TextField),
        );
        expect(tester.widget<TextField>(field).obscureText, true);
        expect(tester.widget<TextField>(field).enableSuggestions, false);
      }
      await tap(tester, find.text('Start sign-in again'));
      expect(auth.discards, 1);
      expect(auth.finishes, 0);
      expect(find.byType(AuthTextField), findsNothing);
      expect(await TokenStorage().getToken(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'lost enrollment save requires checking and explicitly continuing with the saved method',
    (tester) async {
      final auth = ProtectionAuth()..loseSaveResponse = true;
      await open(tester, auth);
      await enter(tester, const ValueKey('protection-email-code'), '123456');
      await tap(tester, find.byKey(const ValueKey('protection-verify')));
      await tap(tester, find.text('Email code'));
      await tap(tester, find.byKey(const ValueKey('protection-save')));
      expect(auth.finishes, 0);
      expect(find.textContaining('save response was lost'), findsOneWidget);
      await tap(tester, find.text('Check saved protection'));
      expect(auth.finishes, 0);
      expect(find.text('Authenticated'), findsNothing);
      await tap(tester, find.text('Continue with saved protection'));
      expect(auth.finishes, 1);
      expect(find.text('Authenticated'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'disabled settings stay honest in dark mode at 320px and 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = ProtectionAuth()..enabled = false;
      await open(tester, auth, settings: true, dark: true);
      expect(
        find.textContaining('not available in this development build'),
        findsOneWidget,
      );
      expect(find.text('Confirm identity'), findsNothing);
      await tester.scrollUntilVisible(find.text('Back to settings'), 120);
      expect(tester.takeException(), isNull);
      expect(auth.reauthentications, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('expired code cannot be submitted', (tester) async {
    final auth = ProtectionAuth();
    final base = attempt(auth.now);
    final pending = base.withChallenge(
      SignInChallenge(
        token: base.challenge.token,
        method: 'email',
        expiresAt: auth.now.subtract(const Duration(seconds: 1)),
        questions: const [],
        emailDelivery: 'queued',
        supportEmail: 'team@cozyhealth.org',
      ),
    );
    await open(tester, auth, pending: pending);
    expect(
      tester
          .widget<WellnessAction>(
            find.byKey(const ValueKey('protection-verify')),
          )
          .onPressed,
      isNull,
    );
    expect(auth.verifications, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'settings use a centered identity popup and require email proof before saving',
    (tester) async {
      await TokenStorage().saveToken('current-owner');
      final auth = ProtectionAuth()..enrolled = true;
      await open(tester, auth, settings: true);
      await tap(tester, find.text('Confirm identity'));
      expect(find.byType(Dialog), findsOneWidget);
      final password = find.widgetWithText(AuthTextField, 'Current password');
      await tester.enterText(
        find.descendant(of: password, matching: find.byType(TextField)),
        'test-only-password',
      );
      await tap(tester, find.text('Send verification code'));
      expect(auth.reauthentications, 1);
      expect(auth.saves, 0);
      expect(find.text('Confirm your identity'), findsNothing);
      await enter(tester, const ValueKey('protection-email-code'), '123456');
      await tap(tester, find.byKey(const ValueKey('protection-verify')));
      await tap(tester, find.text('Email code'));
      await tap(tester, find.byKey(const ValueKey('protection-save')));
      expect(
        find.text('Your sign-in protection setting is saved.'),
        findsOneWidget,
      );
      expect(auth.saves, 1);
      expect(auth.finishes, 0);
      expect(await TokenStorage().getToken(), 'current-owner');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'changing accounts closes the owned identity popup and clears its password',
    (tester) async {
      final auth = ProtectionAuth()..enrolled = true;
      await open(tester, auth, settings: true);
      await tap(tester, find.text('Confirm identity'));
      final password = find.widgetWithText(AuthTextField, 'Current password');
      final field = find.descendant(
        of: password,
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'private-test-secret');
      final controller = tester.widget<TextField>(field).controller!;
      await tester.runAsync(() => TokenStorage().saveToken('another-account'));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(find.byType(Dialog), findsNothing);
      expect(find.textContaining('This sign-in attempt ended'), findsWidgets);
      expect(auth.reauthentications, 0);
      expect(await TokenStorage().getToken(), 'another-account');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
