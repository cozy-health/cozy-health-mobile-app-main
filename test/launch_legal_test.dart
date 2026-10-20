import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cozy_health/core/services/legal_documents.dart';
import 'package:cozy_health/core/services/consent_service.dart';
import 'package:cozy_health/core/widgets/consent_gate.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'legal links reject credentials, foreign hosts and insecure schemes',
    () {
      expect(
        LegalDocuments.trustedUrl('https://cozyhealth.org/privacy'),
        isNotNull,
      );
      for (final url in [
        'http://cozyhealth.org/privacy',
        'https://cozyhealth.org.evil.test/privacy',
        'https://user@cozyhealth.org/privacy',
        'javascript:alert(1)',
      ]) {
        expect(LegalDocuments.trustedUrl(url), isNull);
      }
    },
  );
  testWidgets(
    'health-data consent starts unchecked and requires an explicit choice',
    (tester) async {
      final saved = <Map<String, dynamic>>[];
      final service = ConsentService(
        token: () async => 'session',
        get: (path) async => path == '/config'
            ? {
                'consent': {
                  'enforce_blocking': true,
                  'documents': {
                    'health_data': {
                      'title': 'Health Data Consent',
                      'version': '1.0',
                      'required': true,
                      'published': true,
                      'content': 'Fixture health processing notice.',
                    },
                  },
                },
              }
            : {'owner_id': 1, 'data': []},
        post: (body) async {
          saved.add(body);
          return {
            'owner_id': 1,
            'data': {...body, 'status': 'accepted'},
          };
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ConsentGate(
            service: service,
            observeRoutes: false,
            child: const Text('App content'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        false,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Accept'))
            .onPressed,
        isNull,
      );
      expect(find.text('Get urgent support'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(saved.single['accepted'], true);
      expect(find.text('App content'), findsOneWidget);
    },
  );
}
