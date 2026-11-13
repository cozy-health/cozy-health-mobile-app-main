import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/features/settings/presentation/screens/student_verification_screen.dart';
import 'package:cozy_health/features/settings/presentation/widgets/launch_billing_panel.dart';
import 'package:cozy_health/features/settings/data/native_billing_service.dart';
import 'package:cozy_health/utils/screen_util.dart';
import 'support/local_fonts.dart';

class StudentReviewTransport implements HttpClientAdapter {
  String status = 'pending';
  bool fail = false;
  bool empty = false, renewal = false, emailVerified = false, failEmail = false;
  Map<String, dynamic>? schoolRequest;
  String? challengeId;
  Map<String, dynamic>? confirmation;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/student-school-requests') {
      if (options.method == 'POST') {
        schoolRequest = Map<String, dynamic>.from(options.data as Map);
      }
      return ResponseBody.fromString(
        jsonEncode({
          'data': schoolRequest == null
              ? []
              : [
                  {
                    'institution': schoolRequest!['institution'],
                    'status': 'pending',
                  },
                ],
        }),
        options.method == 'POST' ? 201 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (options.method == 'POST' &&
        options.path == '/student-verification/email') {
      challengeId = 'fixture-email-challenge';
      return ResponseBody.fromString(
        jsonEncode(
          failEmail
              ? {
                  'message':
                      'This school domain is not supported. Request to add your Nigerian institution.',
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
    'rejection shows its reason and opens school email verification explicitly',
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
      await tester.ensureVisible(find.text('Verify school email'));
      await tester.tap(find.text('Verify school email'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('student-evidence')), findsNothing);
      expect(
        find.byKey(const ValueKey('student-email-request')),
        findsOneWidget,
      );
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
  testWidgets('unsupported school emails offer a school request without uploads', (
    tester,
  ) async {
    transport.empty = true;
    transport.failEmail = true;
    await show(tester);
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
      find.text(
        'This school domain is not supported. Request to add your Nigerian institution.',
      ),
    );
    expect(
      find.text(
        'This school domain is not supported. Request to add your Nigerian institution.',
      ),
      findsOneWidget,
    );
    await reveal(
      tester,
      find.byKey(const ValueKey('student-school-request-toggle')),
      step: -200,
    );
    await tester.tap(
      find.byKey(const ValueKey('student-school-request-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('student-evidence')), findsNothing);
    await reveal(
      tester,
      find.byKey(const ValueKey('student-school-request-submit')),
    );
    expect(
      find.byKey(const ValueKey('student-school-request-submit')),
      findsOneWidget,
    );
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
      await reveal(tester, find.byKey(const ValueKey('student-email-request')));
      expect(
        find.byKey(const ValueKey('student-email-request')),
        findsOneWidget,
      );
      await reveal(
        tester,
        find.textContaining('Current eligibility ends:'),
        step: -200,
      );
      expect(find.textContaining('Current eligibility ends:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('school requests submit the domain and retain visible status', (
    tester,
  ) async {
    transport.empty = true;
    await show(tester);
    await tester.enterText(
      find.byKey(const ValueKey('student-school-email')),
      'learner@school.org',
    );
    await reveal(
      tester,
      find.byKey(const ValueKey('student-school-request-toggle')),
    );
    await tester.tap(
      find.byKey(const ValueKey('student-school-request-toggle')),
    );
    await tester.pumpAndSettle();
    await reveal(
      tester,
      find.byKey(const ValueKey('student-school-institution')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('student-school-institution')),
      'Nigerian School',
    );
    await reveal(tester, find.byKey(const ValueKey('student-school-website')));
    await tester.enterText(
      find.byKey(const ValueKey('student-school-website')),
      'https://school.org',
    );
    await reveal(
      tester,
      find.byKey(const ValueKey('student-school-request-submit')),
    );
    await tester.tap(
      find.byKey(const ValueKey('student-school-request-submit')),
    );
    await tester.pumpAndSettle();
    expect(transport.schoolRequest, {
      'domain': 'school.org',
      'institution': 'Nigerian School',
      'website': 'https://school.org',
    });
    await reveal(
      tester,
      find.text('School request: Nigerian School - Awaiting review'),
    );
    expect(
      find.text('School request: Nigerian School - Awaiting review'),
      findsOneWidget,
    );
    expect(transport.emailVerified, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'plans prompt for email renewal without claiming to cancel paid access',
    (tester) async {
      final billing = NativeBillingService.instance;
      billing.studentReverificationRequired = true;
      try {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              ScreenUtil.init(context);
              return child!;
            },
            home: const Scaffold(
              body: SingleChildScrollView(child: LaunchBillingPanel()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            'Your store-confirmed paid access and successful renewals remain valid.',
          ),
          findsOneWidget,
        );
        expect(find.text('Verify school email again'), findsOneWidget);
        await tester.ensureVisible(find.text('Verify school email again'));
        await tester.tap(find.text('Verify school email again'));
        await tester.pumpAndSettle();
        expect(find.byType(StudentVerificationScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        billing.studentReverificationRequired = false;
      }
    },
  );
}
