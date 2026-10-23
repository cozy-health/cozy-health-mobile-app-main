import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cozy_health/core/services/consent_service.dart';
import 'package:cozy_health/core/widgets/consent_gate.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/routing/app_router.dart';

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
    'saved emergency contacts require consent while public support stays reachable',
    (tester) async {
      await TokenStorage().saveToken('fixture-session', stayLoggedIn: false);
      AppRouter.router.go(AppRouter.crisisContact);
      await tester.pumpWidget(
        MaterialApp(
          home: ConsentGate(
            service: service(blocking: true, published: true),
            child: const Text('Route content'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Route content'), findsNothing);
      expect(find.text('Approved privacy text for this test.'), findsOneWidget);
      AppRouter.router.go(AppRouter.crisisHub);
      await tester.pumpAndSettle();
      expect(find.text('Route content'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      AppRouter.router.go(AppRouter.home);
      await TokenStorage().clearToken();
    },
  );
  testWidgets('session change hides old consent while the new account loads', (
    tester,
  ) async {
    await TokenStorage().saveToken('first');
    final next = Completer<Map<String, dynamic>>();
    var loadingSecond = false;
    final scoped = ConsentService(
      get: (path) async {
        if (path == '/config') {
          if (loadingSecond) return next.future;
          return {
            'consent': {
              'enforce_blocking': false,
              'documents': <String, dynamic>{},
            },
          };
        }
        return {
          'owner_id': loadingSecond ? 2 : 1,
          'data': <Map<String, dynamic>>[],
        };
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ConsentGate(
          service: scoped,
          observeRoutes: false,
          child: const Text('Private content'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private content'), findsOneWidget);
    loadingSecond = true;
    await TokenStorage().saveToken('second');
    await tester.pump();
    expect(find.text('Private content'), findsNothing);
    next.completeError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Private content'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await TokenStorage().clearToken();
  });
  testWidgets(
    'unknown consent hides private content and failure offers retry',
    (tester) async {
      var attempts = 0;
      final pending = Completer<Map<String, dynamic>>();
      final recovery = ConsentService(
        token: () async => 'fixture-session',
        get: (path) async {
          attempts++;
          if (attempts == 1) return pending.future;
          return path == '/config'
              ? {
                  'consent': {
                    'enforce_blocking': false,
                    'documents': <String, dynamic>{},
                  },
                }
              : {'owner_id': 1, 'data': <Map<String, dynamic>>[]};
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ConsentGate(
            service: recovery,
            observeRoutes: false,
            child: const Text('Private content'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Private content'), findsNothing);
      pending.completeError(StateError('Network unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('Private content'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Private content'), findsOneWidget);
    },
  );
  testWidgets(
    'age enforcement requires current effective consent even before the legacy blocking flag changes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConsentGate(
            service: service(blocking: false, published: true),
            forceBlocking: true,
            observeRoutes: false,
            child: const Scaffold(body: Text('Application content')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Application content'), findsNothing);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(find.text('Application content'), findsOneWidget);
    },
  );
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
