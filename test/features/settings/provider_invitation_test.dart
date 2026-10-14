import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/features/settings/data/settings_service.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_screen.dart';
import 'package:cozy_health/utils/screen_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/local_fonts.dart';

class InvitationApi extends Fake implements ApiClient {
  Map<String, dynamic>? provider;
  Map<String, dynamic>? sent;
  final calls = <String>[];
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
    provider = {
      'id': 42,
      'provider_email': sent!['provider_email'],
      'provider_name': 'Dr Avery',
      'status': 'pending',
      'verification_actor': 'provider',
      'invitation_sent_at': DateTime.now().toUtc().toIso8601String(),
      'consent_flags': sent!['consent_flags'],
    };
    return response({'has_provider': false, 'provider': provider});
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
      await tester.ensureVisible(find.text('Send invitation'));
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
      expect(find.text('Verification Code'), findsNothing);
      expect(api.calls, isNot(contains('POST /provider/verify')));
      expect(find.text('Check connection status'), findsOneWidget);
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
