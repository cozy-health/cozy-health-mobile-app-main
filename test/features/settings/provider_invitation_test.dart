import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/features/settings/data/settings_service.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_screen.dart';
import 'package:cozy_health/utils/screen_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/local_fonts.dart';

class InvitationApi extends Fake implements ApiClient {
  Map<String, dynamic>? provider;
  Map<String, dynamic>? sent;
  final calls = <String>[];
  bool failEmail = false;
  bool failCancel = false, acceptedBeforeCancel = false, failRequest = false;
  Response<dynamic> response(dynamic data) => Response(
    requestOptions: RequestOptions(path: ''),
    data: data,
  );

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? query,
    bool withAuth = true,
    Options? options,
  }) async {
    calls.add('GET $path');
    return response({
      'has_provider': provider?['status'] == 'verified',
      'provider': provider,
    });
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
    Options? options,
  }) async {
    calls.add('POST $path');
    sent = Map<String, dynamic>.from(data ?? body);
    if (failRequest) throw ApiServerException(statusCode: 500);
    provider = {
      'id': 42,
      'provider_email': sent!['provider_email'],
      'provider_name': 'Dr Avery',
      'status': 'pending',
      'verification_actor': 'provider',
      'invitation_sent_at': DateTime.now().toUtc().toIso8601String(),
      'invitation_code': '123456',
      'invitation_expires_at': DateTime.now()
          .add(const Duration(minutes: 15))
          .toUtc()
          .toIso8601String(),
      'invitation_portal_url': 'https://portal.example.test/provider',
      'consent_flags': sent!['consent_flags'],
    };
    if (failEmail) {
      provider!['invitation_sent_at'] = null;
      throw ApiUnknownException(
        'The invitation email could not be queued.',
        statusCode: 503,
      );
    }
    return response({'has_provider': false, 'provider': provider});
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
    Options? options,
  }) async {
    calls.add('DELETE $path');
    if (acceptedBeforeCancel) {
      provider!['status'] = 'verified';
      throw ApiUnknownException('Already accepted', statusCode: 409);
    }
    if (failCancel) throw ApiServerException(statusCode: 500);
    provider = null;
    return response({'message': 'Invitation cancelled.'});
  }
}

Future<void> showScreen(WidgetTester tester, InvitationApi api) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProviderScreen(settingsService: SettingsService(apiClient: api)),
      builder: (context, child) {
        ScreenUtil.init(context);
        return child!;
      },
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);

  Future<InvitationApi> pending(WidgetTester tester) async {
    final api = InvitationApi();
    await api.post(
      '/provider/request',
      body: {
        'provider_email': 'wrong@example.test',
        'consent_flags': {
          'moods': true,
          'journals': false,
          'quizzes': false,
          'notes': false,
        },
      },
    );
    await showScreen(tester, api);
    await tester.ensureVisible(find.text('Wrong provider email?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wrong provider email?'));
    await tester.pumpAndSettle();
    return api;
  }

  Future<void> submitCorrection(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextFormField), email);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send corrected invitation'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'correcting email cancels the old invitation before sending and preserves sharing',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = await pending(tester);
      api.calls.clear();
      await submitCorrection(tester, 'correct@example.test');
      expect(api.calls, [
        'DELETE /provider/invitations/42',
        'POST /provider/request',
      ]);
      expect(api.sent!['provider_email'], 'correct@example.test');
      expect(api.sent!['provider_name'], 'Dr Avery');
      expect((api.sent!['consent_flags'] as Map)['moods'], true);
      expect(find.textContaining('correct@example.test'), findsWidgets);
      expect(find.text('Copy code'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('invalid or unchanged corrected emails do not cancel anything', (
    tester,
  ) async {
    final api = await pending(tester);
    api.calls.clear();
    await submitCorrection(tester, 'invalid');
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await submitCorrection(tester, 'WRONG@example.test');
    expect(find.text('Enter a different email address.'), findsOneWidget);
    expect(api.calls, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'cancellation failure retains original invitation and corrected draft',
    (tester) async {
      final api = await pending(tester);
      api.failCancel = true;
      api.calls.clear();
      await submitCorrection(tester, 'correct@example.test');
      expect(api.calls, ['DELETE /provider/invitations/42']);
      expect(api.provider!['provider_email'], 'wrong@example.test');
      await tester.ensureVisible(find.text('Wrong provider email?'));
      await tester.tap(find.text('Wrong provider email?'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).initialValue,
        'correct@example.test',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'replacement send failure keeps corrected email and sharing for retry',
    (tester) async {
      final api = await pending(tester);
      api.failRequest = true;
      await submitCorrection(tester, 'correct@example.test');
      expect(api.provider, isNull);
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'therapist@example.com'),
            )
            .controller!
            .text,
        'correct@example.test',
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('invitation-moods')),
            )
            .value,
        true,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'acceptance during correction refreshes connection without replacing it',
    (tester) async {
      final api = await pending(tester);
      api.acceptedBeforeCancel = true;
      api.calls.clear();
      await submitCorrection(tester, 'correct@example.test');
      expect(api.calls, ['DELETE /provider/invitations/42', 'GET /provider']);
      expect(api.provider!['status'], 'verified');
      expect(api.provider!['provider_email'], 'wrong@example.test');
      expect(find.text('Wrong provider email?'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'email queue failure refreshes the saved invitation and allows retry',
    (tester) async {
      final api = InvitationApi()..failEmail = true;
      await showScreen(tester, api);
      await tester.enterText(
        find.widgetWithText(TextField, 'therapist@example.com'),
        'avery@example.test',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Send invitation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send invitation'));
      await tester.pumpAndSettle();
      expect(find.text('Waiting for your provider'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
      expect(find.textContaining('could not be queued'), findsWidgets);
      api.failEmail = false;
      await tester.ensureVisible(find.text('Resend invitation'));
      await tester.tap(find.text('Resend invitation'));
      await tester.pumpAndSettle();
      expect(api.provider!['invitation_sent_at'], isNotNull);
      expect(find.text('Copy code'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'patient chooses sharing before sending and provider redeems the code',
    (tester) async {
      final api = InvitationApi();
      await showScreen(tester, api);
      for (final type in ['moods', 'journals', 'quizzes', 'notes']) {
        expect(
          tester
              .widget<SwitchListTile>(find.byKey(ValueKey('invitation-$type')))
              .value,
          isFalse,
        );
      }
      await tester.enterText(
        find.widgetWithText(TextField, 'therapist@example.com'),
        'avery@example.test',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('invitation-moods')),
      );
      await tester.tap(find.byKey(const ValueKey('invitation-moods')));
      await tester.pump();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Send invitation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send invitation'));
      await tester.pumpAndSettle();
      expect(api.sent!['verification_actor'], 'provider');
      expect(api.sent!['consent_flags'], {
        'moods': true,
        'journals': false,
        'quizzes': false,
        'notes': false,
      });
      expect(find.text('Waiting for your provider'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
      expect(find.text('Copy code'), findsOneWidget);
      expect(find.text('Share invitation'), findsOneWidget);
      expect(find.text('Verification Code'), findsNothing);
      expect(api.calls, isNot(contains('POST /provider/verify')));
      expect(find.text('Check connection status'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'reopened invitation copies and shares the owner code without health records',
    (tester) async {
      final api = InvitationApi();
      await api.post(
        '/provider/request',
        body: {'provider_email': 'avery@example.test', 'consent_flags': {}},
      );
      String? copied;
      String? shared;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
      messenger.setMockMethodCallHandler(shareChannel, (call) async {
        shared = (call.arguments as Map)['text'] as String;
        return 'com.example.test';
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
        messenger.setMockMethodCallHandler(shareChannel, null);
      });
      await showScreen(tester, api);
      expect(find.text('123456'), findsOneWidget);
      await tester.ensureVisible(find.text('Copy code'));
      await tester.tap(find.text('Copy code'));
      await tester.pumpAndSettle();
      expect(copied, '123456');
      await tester.ensureVisible(find.text('Share invitation'));
      await tester.tap(find.text('Share invitation'));
      await tester.pumpAndSettle();
      expect(shared, contains('123456'));
      expect(shared, contains('avery@example.test'));
      expect(shared, contains('https://portal.example.test/provider'));
      expect(shared, contains('Expires:'));
      expect(shared, isNot(contains('consent_flags')));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'expiry removes displayed code and sharing actions without reopening',
    (tester) async {
      final api = InvitationApi();
      await api.post(
        '/provider/request',
        body: {'provider_email': 'avery@example.test', 'consent_flags': {}},
      );
      api.provider!['invitation_expires_at'] = DateTime.now()
          .add(const Duration(seconds: 3))
          .toUtc()
          .toIso8601String();
      await showScreen(tester, api);
      expect(find.text('123456'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('123456'), findsNothing);
      expect(find.text('Copy code'), findsNothing);
      expect(find.text('Share invitation'), findsNothing);
      expect(find.textContaining('code has expired'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'old invitations offer resend instead of a missing shareable code',
    (tester) async {
      final api = InvitationApi()
        ..provider = {
          'id': 42,
          'provider_email': 'avery@example.test',
          'status': 'pending',
          'verification_actor': 'provider',
          'consent_flags': {},
        };
      await showScreen(tester, api);
      expect(find.text('Copy code'), findsNothing);
      expect(
        find.textContaining('get a code you can copy or share'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Resend invitation'));
      await tester.tap(find.text('Resend invitation'));
      await tester.pumpAndSettle();
      expect(find.text('123456'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('older pending requests retain patient-side verification', (
    tester,
  ) async {
    final api = InvitationApi()
      ..provider = {
        'id': 42,
        'provider_email': 'avery@example.test',
        'status': 'pending',
        'verification_actor': 'patient',
      };
    await showScreen(tester, api);
    expect(find.text('Verification Code'), findsOneWidget);
    expect(find.text('Verify Provider'), findsOneWidget);
    expect(find.text('Waiting for your provider'), findsNothing);
  });

  testWidgets(
    'reopened failed invitation resends to the intended email with the same permissions',
    (tester) async {
      final api = InvitationApi()
        ..provider = {
          'id': 42,
          'provider_email': 'avery@example.test',
          'status': 'pending',
          'verification_actor': 'provider',
          'invitation_sent_at': null,
          'consent_flags': {
            'moods': true,
            'journals': false,
            'quizzes': false,
            'notes': false,
          },
        };
      await showScreen(tester, api);
      expect(find.textContaining('could not be queued'), findsOneWidget);
      await tester.ensureVisible(find.text('Resend invitation'));
      await tester.tap(find.text('Resend invitation'));
      await tester.pumpAndSettle();
      expect(api.sent!['provider_email'], 'avery@example.test');
      expect(api.sent!['consent_flags'], {
        'moods': true,
        'journals': false,
        'quizzes': false,
        'notes': false,
      });
      expect(find.text('Verification Code'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
