import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/core/services/age_eligibility_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/widgets/age_eligibility_gate.dart';

class _Service extends AgeEligibilityService {
  _Service()
    : super(
        token: () => TokenStorage().getToken(),
        enforcement: () => true,
        fetch: () async => {
          'owner_id': 1,
          'allowed': false,
          'enforced': true,
          'online_required': true,
          'reason': 'guardian_required',
          'age_band': 'minor',
          'email_verified': true,
          'invitations_enabled': true,
          'date_of_birth': '2010-01-01',
          'residence_country': 'NG',
        },
      );
  Object failure = ApiAgeActionException(
    statusCode: 422,
    fieldErrors: {
      'guardian_email': ['Enter a valid guardian email.'],
    },
  );
  Completer<void>? pending;
  @override
  Future<void> submit(String path, Map<String, dynamic> data) async {
    if (pending != null) await pending!.future;
    throw failure;
  }
}

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await TokenStorage().saveToken('fixture-a', stayLoggedIn: false);
  });

  Future<void> open(WidgetTester tester, _Service service) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: AgeEligibilityGate(
          service: service,
          observeRoutes: false,
          review: true,
          child: const Text('Private content'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(field('Guardian name'));
    await tester.enterText(field('Guardian name'), 'Test Parent');
    await tester.ensureVisible(field('Guardian email'));
    await tester.enterText(field('Guardian email'), 'parent@example.com');
    await tester.ensureVisible(find.text('Send / resend guardian invitation'));
    await tester.tap(find.text('Send / resend guardian invitation'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'failed submission preserves input and renders an announced summary with field errors',
    (tester) async {
      final service = _Service();
      await open(tester, service);
      final semantics = tester.ensureSemantics();
      await submit(tester);
      expect(find.text('Enter a valid guardian email.'), findsOneWidget);
      expect(
        find.text('Check the highlighted details, then try again.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(field('Guardian name')).controller!.text,
        'Test Parent',
      );
      expect(
        tester.widget<TextField>(field('Guardian email')).controller!.text,
        'parent@example.com',
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
    },
  );

  testWidgets(
    'rate limits explain the wait without discarding the guardian details',
    (tester) async {
      final service = _Service()
        ..failure = ApiAgeActionException(
          statusCode: 429,
          fieldErrors: {},
          retryAfterSeconds: 120,
        );
      await open(tester, service);
      await submit(tester);
      expect(find.textContaining('wait 2 minute'), findsOneWidget);
      expect(
        tester.widget<TextField>(field('Guardian email')).controller!.text,
        'parent@example.com',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
    },
  );

  testWidgets(
    'an account change clears contact drafts and ignores the previous submission error',
    (tester) async {
      final service = _Service()..pending = Completer<void>();
      await open(tester, service);
      await submit(tester);
      await TokenStorage().saveToken('fixture-b', stayLoggedIn: false);
      await tester.pumpAndSettle();
      service.pending!.complete();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field('Guardian email')).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<TextField>(field('Guardian name')).controller!.text,
        isEmpty,
      );
      expect(find.textContaining('highlighted'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
    },
  );
}
