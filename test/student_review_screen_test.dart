import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/features/settings/presentation/screens/student_verification_screen.dart';
import 'package:cozy_health/utils/screen_util.dart';
import 'support/local_fonts.dart';

class StudentReviewTransport implements HttpClientAdapter {
  String status = 'pending';
  bool fail = false;
  bool empty = false, renewal = false, emailVerified = false, failEmail = false;
  String? challengeId;
  Map<String, dynamic>? confirmation;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'POST' &&
        options.path == '/student-verification/email') {
      challengeId = 'fixture-email-challenge';
      return ResponseBody.fromString(
        jsonEncode(
          failEmail
              ? {
                  'message':
                      'This domain is not approved. Submit documents instead.',
                }
              : {'challenge_id': challengeId},
        ),
        failEmail ? 422 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (options.method == 'POST' &&
        options.path == '/student-verification/email/confirm') {
      confirmation = Map<String, dynamic>.from(options.data as Map);
      emailVerified = true;
      empty = false;
      status = 'approved';
      challengeId = null;
      return ResponseBody.fromString(
        '{}',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(
        fail
            ? {'message': 'Fixture unavailable'}
            : {
                'enabled': true,
                'email_challenge': challengeId == null
                    ? null
                    : {'id': challengeId},
                if (renewal)
                  'eligibility': {
                    'active': true,
                    'expires_at': DateTime.now()
                        .add(const Duration(days: 20))
                        .toIso8601String(),
                    'renewal_available': true,
                    'renewal_reminder': true,
                  },
                'application': empty
                    ? null
                    : {
                        'id': 'fictional-application',
                        'status': status,
                        'review_note': status == 'rejected'
                            ? 'Please submit a course form for the current semester.'
                            : null,
                        'eligible_until': status == 'approved'
                            ? '2099-01-01T00:00:00Z'
                            : null,
                        'verification_method': emailVerified
                            ? 'email'
                            : 'document',
                      },
              },
      ),
      fail ? 503 : 200,
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
  late StudentReviewTransport transport;
  late HttpClientAdapter previous;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    previous = ApiClient().transportForTesting;
    transport = StudentReviewTransport();
    ApiClient().transportForTesting = transport;
  });
  tearDown(() => ApiClient().transportForTesting = previous);
  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          ScreenUtil.init(context);
          return child!;
        },
        home: const StudentVerificationScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    double step = 200,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      step,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('pending submissions are locked rather than editable', (
    tester,
  ) async {
    await show(tester);
    expect(
      find.text('Your application is awaiting review and cannot be edited.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('student-submit')), findsNothing);
    expect(find.text('Refresh application status'), findsOneWidget);
  });
  testWidgets(
    'rejection shows its reason and opens a fresh evidence form explicitly',
    (tester) async {
      transport.status = 'rejected';
      await show(tester);
      expect(
        find.textContaining(
          'Please submit a course form for the current semester.',
        ),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Choose another plan'), findsOneWidget);
      await tester.ensureVisible(find.text('Submit new evidence'));
      await tester.tap(find.text('Submit new evidence'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      await reveal(tester, find.byKey(const ValueKey('student-evidence')));
      expect(find.byKey(const ValueKey('student-evidence')), findsOneWidget);
    },
  );
  testWidgets('active eligibility cannot be replaced with a new application', (
    tester,
  ) async {
    transport.status = 'approved';
    await show(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Renew student eligibility'), findsNothing);
  });
  testWidgets(
    'failed application loads offer retry without opening a new form',
    (tester) async {
      transport.fail = true;
      await show(tester);
      expect(find.text('Retry application'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      transport.fail = false;
      await tester.ensureVisible(find.text('Retry application'));
      await tester.tap(find.text('Retry application'));
      await tester.pumpAndSettle();
      expect(
        find.text('Your application is awaiting review and cannot be edited.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'school email verification works without a document or changing login',
    (tester) async {
      transport.empty = true;
      await show(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('student-email-route')),
      );
      await tester.tap(find.byKey(const ValueKey('student-email-route')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('student-evidence')), findsNothing);
      await tester.enterText(
        find.byType(TextField).first,
        'learner@students.synthetic.example',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('student-email-request')),
      );
      await tester.tap(find.byKey(const ValueKey('student-email-request')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('student-email-code')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('student-email-code')),
        '123456',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('student-email-confirm')),
      );
      await tester.tap(find.byKey(const ValueKey('student-email-confirm')));
      await tester.pumpAndSettle();
      expect(transport.confirmation, {
        'id': 'fixture-email-challenge',
        'token': '123456',
      });
      expect(
        find.textContaining('Student eligibility verified.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('student-email-code')), findsNothing);
    },
  );
  testWidgets('unapproved school emails retain the document route', (
    tester,
  ) async {
    transport.empty = true;
    transport.failEmail = true;
    await show(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('student-email-route')),
    );
    await tester.tap(find.byKey(const ValueKey('student-email-route')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'learner@unknown.example',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('student-email-request')),
    );
    await tester.tap(find.byKey(const ValueKey('student-email-request')));
    await tester.pumpAndSettle();
    await reveal(
      tester,
      find.text('This domain is not approved. Submit documents instead.'),
    );
    expect(
      find.text('This domain is not approved. Submit documents instead.'),
      findsOneWidget,
    );
    await reveal(
      tester,
      find.byKey(const ValueKey('student-document-route')),
      step: -200,
    );
    await tester.tap(find.byKey(const ValueKey('student-document-route')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('student-evidence')));
    expect(find.byKey(const ValueKey('student-evidence')), findsOneWidget);
  });
  testWidgets(
    'renewal opens early while active eligibility stays visible at large text',
    (tester) async {
      transport.status = 'approved';
      transport.renewal = true;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            ScreenUtil.init(context);
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            );
          },
          home: const StudentVerificationScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.textContaining('Current eligibility ends:'));
      expect(find.textContaining('Current eligibility ends:'), findsOneWidget);
      await reveal(tester, find.text('Renew student eligibility'));
      await tester.tap(find.text('Renew student eligibility'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const ValueKey('student-email-route')));
      expect(find.byKey(const ValueKey('student-email-route')), findsOneWidget);
      await reveal(
        tester,
        find.textContaining('Current eligibility ends:'),
        step: -200,
      );
      expect(find.textContaining('Current eligibility ends:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
