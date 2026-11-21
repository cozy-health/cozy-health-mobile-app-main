import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/auth/presentation/screens/create_account_screen.dart';
import 'package:cozy_health/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:cozy_health/features/auth/presentation/screens/login_screen.dart';
import 'package:cozy_health/features/auth/presentation/widgets/auth_ui.dart';
import 'package:cozy_health/utils/screen_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/endpoint_fixture.dart';
import '../../support/local_fonts.dart';

class PendingAuthTransport implements HttpClientAdapter {
  PendingAuthTransport(this.path);
  final String path;
  final responses = <Completer<ResponseBody>>[];
  final entered = Completer<void>();
  bool released = false;

  ResponseBody response(int status) => ResponseBody.fromString(
    jsonEncode({
      'success': status == 200,
      'message': 'Synthetic response',
      'data': {},
    }),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (!options.path.endsWith(path)) return Future.value(response(200));
    final pending = Completer<ResponseBody>();
    responses.add(pending);
    if (!entered.isCompleted) entered.complete();
    if (released) pending.complete(response(422));
    return pending.future;
  }

  void finish() {
    released = true;
    for (final pending in responses) {
      if (!pending.isCompleted) pending.complete(response(422));
    }
  }

  @override
  void close({bool force = false}) => finish();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = EndpointFixture();
  setUpAll(() async {
    await fixture.open();
    await installLocalTestFonts();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await fixture.reset();
  });
  tearDownAll(() async {
    await fixture.close();
    resetLocalTestFonts();
  });

  for (final action in [
    'registration',
    'login',
    'reset request',
    'reset confirmation',
  ]) {
    testWidgets(
      '$action submits once before redraw and retries after failure',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final path = switch (action) {
          'registration' => '/auth/register',
          'login' => '/auth/login',
          'reset request' => '/auth/forgot-password',
          _ => '/auth/reset-password',
        };
        final transport = PendingAuthTransport(path);
        final api = ApiClient(), previous = ApiClient().transportForTesting;
        api.transportForTesting = transport;
        addTearDown(() => api.transportForTesting = previous);
        final Widget screen = switch (action) {
          'registration' => const CreateAccountScreen(),
          'login' => const LoginScreen(),
          _ => const ForgotPasswordScreen(),
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) {
              ScreenUtil.init(context);
              return child!;
            },
            home: screen,
          ),
        );
        await tester.pumpAndSettle();
        Future<void> enter(String label, String value) async {
          final field = find.descendant(
            of: find.byWidgetPredicate(
              (widget) => widget is AuthTextField && widget.label == label,
            ),
            matching: find.byType(TextField),
          );
          await tester.ensureVisible(field);
          await tester.enterText(field, value);
          await tester.pump();
        }

        if (action == 'registration') {
          await enter('Full Name', 'Synthetic Test');
        }
        await enter('Email', 'submission@example.test');
        if (action == 'registration' || action == 'login') {
          await enter('Password', 'Synthetic-pass123');
        }
        if (action == 'registration') {
          await enter('Confirm Password', 'Synthetic-pass123');
          final terms = find.byKey(const ValueKey('auth-terms-consent'));
          await tester.ensureVisible(terms);
          await tester.tap(terms);
          await tester.pump();
        }
        if (action == 'reset confirmation') {
          await tester.ensureVisible(find.text('Send Code'));
          await tester.tap(find.text('Send Code'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(EditableText).first, '123456');
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
          await enter('New Password', 'Synthetic-pass123');
          await enter('Confirm New Password', 'Synthetic-pass123');
        }
        final label = switch (action) {
          'registration' => 'Create Account',
          'login' => 'Log In',
          'reset request' => 'Send Code',
          _ => 'Reset Password',
        };
        final button = find.byWidgetPredicate(
          (widget) => widget is AuthPrimaryButton && widget.text == label,
        );
        final submit = tester.widget<AuthPrimaryButton>(button).onPressed;
        expect(submit, isNotNull);
        var completed = 0;
        void invoke(VoidCallback callback) {
          final result = Function.apply(callback, const []);
          expect(result, isA<Future<void>>());
          if (result is Future<void>) {
            unawaited(
              result.then((_) {
                completed++;
              }),
            );
          }
        }

        Future<void> driveUntil(bool Function() ready) async {
          for (var frame = 0; frame < 200; frame++) {
            await tester.pump(const Duration(milliseconds: 50));
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)),
            );
            if (ready()) return;
          }
          fail('The bounded form/transport completion was not observed.');
        }

        try {
          // Both events arrive before Flutter rebuilds the disabled button.
          invoke(submit!);
          invoke(submit);
          await driveUntil(() => transport.responses.isNotEmpty);
          transport.finish();
          await driveUntil(
            () =>
                completed == 2 &&
                !tester.widget<AuthPrimaryButton>(button).isLoading,
          );
          expect(transport.responses, hasLength(1));
        } finally {
          transport.finish();
          await tester.pumpAndSettle();
        }
        expect(tester.widget<AuthPrimaryButton>(button).onPressed, isNotNull);
        invoke(tester.widget<AuthPrimaryButton>(button).onPressed!);
        await driveUntil(
          () =>
              completed == 3 &&
              !tester.widget<AuthPrimaryButton>(button).isLoading,
        );
        await tester.pumpAndSettle();
        expect(transport.responses, hasLength(2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
