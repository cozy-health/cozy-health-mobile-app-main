import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cozy_health/core/services/consent_service.dart';
import 'package:cozy_health/core/widgets/consent_gate.dart';

ConsentService service({required bool blocking, required bool published}) =>
    ConsentService(
      token: () async => 'fixture-session',
      get: (path) async => path == '/config'
          ? {
              'consent': {
                'enforce_blocking': blocking,
                'documents': {
                  'privacy_policy': {
                    'title': 'Privacy Policy',
                    'version': published ? '1.0' : 'draft-0.2',
                    'published': published,
                    'required': true,
                    'content': published
                        ? 'Approved privacy text for this test.'
                        : null,
                  },
                  'marketing': {
                    'title': 'Marketing',
                    'version': 'draft-0.1',
                    'published': false,
                    'required': false,
                    'content': null,
                  },
                },
              },
            }
          : {
              'owner_id': 1,
              'data': [
                {
                  'document_type': 'privacy_policy',
                  'version': 'draft-0.1',
                  'status': 'pre_acceptance',
                },
              ],
            },
      post: (body) async => {
        'owner_id': 1,
        'data': {...body, 'status': 'accepted'},
      },
    );

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets(
    'draft update can be dismissed and never offers fake acceptance',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConsentGate(
            service: service(blocking: false, published: false),
            observeRoutes: false,
            child: const Scaffold(body: Text('Application content')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Application content'), findsOneWidget);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.text('Accept'), findsNothing);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Review'), findsNothing);
      expect(find.text('Application content'), findsOneWidget);
    },
  );
  testWidgets(
    'published required document blocks only after server flag and explicit accept unblocks',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConsentGate(
            service: service(blocking: true, published: true),
            observeRoutes: false,
            child: const Text('Application content'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Application content'), findsNothing);
      expect(find.text('Approved privacy text for this test.'), findsOneWidget);
      expect(find.text('Marketing'), findsNothing);
      expect(find.text('Dismiss'), findsNothing);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(find.text('Application content'), findsOneWidget);
    },
  );
}
