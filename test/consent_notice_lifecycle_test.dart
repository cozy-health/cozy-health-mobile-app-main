import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/core/services/consent_service.dart';
import 'package:cozy_health/core/widgets/consent_gate.dart';

ConsentService noticeService({
  bool published = true,
  bool history = true,
  int owner = 1,
  String version = '2.0',
  String previousVersion = '1.0',
}) => ConsentService(
  token: () async => 'account-$owner',
  get: (path) async => path == '/config'
      ? {
          'consent': {
            'enforce_blocking': false,
            'documents': {
              'ugc_guidelines': {
                'title': 'Community Guidelines',
                'version': published ? version : 'draft-0.2',
                'published': published,
                'required': false,
                'content': published ? 'Published community guidance.' : null,
              },
            },
          },
        }
      : {
          'owner_id': owner,
          'data': [
            if (history)
              {
                'document_type': 'ugc_guidelines',
                'version': published ? previousVersion : 'draft-0.1',
                'status': published ? 'accepted' : 'pre_acceptance',
              },
          ],
        },
);

Widget noticeApp(ConsentService service) => MaterialApp(
  home: ConsentGate(
    service: service,
    observeRoutes: false,
    child: const Scaffold(body: Text('Home content')),
  ),
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('drafts do not announce an update on repeated launches', (
    tester,
  ) async {
    for (var launch = 0; launch < 2; launch++) {
      await tester.pumpWidget(noticeApp(noticeService(published: false)));
      await tester.pumpAndSettle();
      expect(find.text('Home content'), findsOneWidget);
      expect(find.byType(MaterialBanner), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('first publication is not described as an update', (
    tester,
  ) async {
    await tester.pumpWidget(noticeApp(noticeService(history: false)));
    await tester.pumpAndSettle();
    expect(find.text('Home content'), findsOneWidget);
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('accepted current version stays silent after relaunch', (
    tester,
  ) async {
    for (var launch = 0; launch < 2; launch++) {
      await tester.pumpWidget(noticeApp(noticeService(previousVersion: '2.0')));
      await tester.pumpAndSettle();
      expect(find.text('Home content'), findsOneWidget);
      expect(find.byType(MaterialBanner), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
    'dismissal survives restart and belongs to its account and version',
    (tester) async {
      await tester.pumpWidget(noticeApp(noticeService()));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialBanner), findsOneWidget);
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialBanner), findsNothing);
      await tester.pumpWidget(const SizedBox());

      await tester.pumpWidget(noticeApp(noticeService()));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialBanner), findsNothing);
      await tester.pumpWidget(const SizedBox());

      await tester.pumpWidget(noticeApp(noticeService(owner: 2)));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialBanner), findsOneWidget);
      await tester.pumpWidget(const SizedBox());

      await tester.pumpWidget(noticeApp(noticeService(version: '3.0')));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialBanner), findsOneWidget);
    },
  );

  testWidgets('normal startup does not display an urgent-support prompt', (
    tester,
  ) async {
    AppRouter.router.go(AppRouter.home);
    final config = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(
      MaterialApp(
        home: ConsentGate(
          service: ConsentService(
            token: () async => 'session',
            get: (_) => config.future,
          ),
          child: const Text('Private content'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Get urgent support'), findsNothing);
    expect(find.text('Private content'), findsNothing);
    config.completeError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Get urgent support'), findsOneWidget);
    expect(find.text('Private content'), findsNothing);
  });
}
