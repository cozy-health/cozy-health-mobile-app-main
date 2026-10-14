import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/utils/screen_util.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/features/auth/presentation/screens/forgot_password_screen.dart';
import '../support/local_fonts.dart';

class AuditTransport implements HttpClientAdapter {
  int status = 200;
  final paths = <String>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    return ResponseBody.fromString(
      jsonEncode({
        'success': status == 200,
        'message': 'Audit response',
        'data': {},
      }),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  for (final status in [200, 429, 500]) {
    testWidgets(
      'diagnostic reset request status $status and unverified six digit code',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = ApiClient();
        final previous = api.transportForTesting;
        final transport = AuditTransport()..status = status;
        api.transportForTesting = transport;
        addTearDown(() => api.transportForTesting = previous);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              ScreenUtil.init(context);
              return child!;
            },
            home: const ForgotPasswordScreen(),
          ),
        );
        await tester.enterText(
          find.byType(EditableText).first,
          'audit@example.test',
        );
        final send = find.text('Send Code');
        expect(send, findsOneWidget);
        await tester.ensureVisible(send);
        await tester.tap(send);
        await tester.pumpAndSettle();
        expect(find.text('Check your\ninbox.'), findsOneWidget);
        final before = transport.paths.length;
        await tester.enterText(find.byType(EditableText).first, '000000');
        final verify = find.text('Verify Code');
        expect(verify, findsOneWidget);
        await tester.ensureVisible(verify);
        await tester.tap(verify);
        await tester.pumpAndSettle();
        expect(find.text('Set a new\npassword.'), findsOneWidget);
        expect(transport.paths.length, before);
        // Confirms observed defects; a green diagnostic does not mean this flow is correct.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
