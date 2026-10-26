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
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(
      fail
          ? {'message': 'Fixture unavailable'}
          : {
              'enabled': true,
              'application': {
                'id': 'fictional-application',
                'status': status,
                'review_note': status == 'rejected'
                    ? 'Please submit a course form for the current semester.'
                    : null,
                'eligible_until': status == 'approved'
                    ? '2099-01-01T00:00:00Z'
                    : null,
              },
            },
    ),
    fail ? 503 : 200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
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
}
