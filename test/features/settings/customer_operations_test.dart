import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/constants/api_constants.dart';
import 'package:cozy_health/features/settings/data/customer_operations.dart';
import 'package:cozy_health/features/settings/data/support_inbox_link.dart';
import 'package:cozy_health/features/settings/presentation/screens/customer_operations_screens.dart';

Response<dynamic> response(dynamic data) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/fixture'),
  data: data,
);
Map<String, dynamic> thread({String status = 'open', int version = 0}) => {
  'data': {
    'id': 1,
    'subject': 'My question',
    'message': 'Original question',
    'status': status,
    'version': version,
    'messages': <dynamic>[],
    'admin_notes': 'NEVER_RENDER_STAFF_NOTE',
  },
};

void main() {
  test(
    'late support results cannot cross accounts or same-account session generations',
    () async {
      var account = 'A', generation = 1;
      final pending = Completer<dynamic>();
      final repository = CustomerOperations(
        account: () => account,
        generation: () => generation,
        get: (path, {queryParameters}) => pending.future,
        post: (path, {data, options}) async => response(thread()),
      );
      final result = repository.conversation(1);
      final assertion = expectLater(result, throwsStateError);
      account = 'B';
      pending.complete(response(thread()));
      await assertion;
      account = 'A';
      generation = 2;
      await expectLater(repository.conversation(1), throwsStateError);
    },
  );

  test(
    'customer parser never exposes staff notes and rejects malformed list responses',
    () async {
      final repository = CustomerOperations(
        account: () => 'A',
        generation: () => 1,
        get: (path, {queryParameters}) async => response(thread()),
        post: (path, {data, options}) async => response(thread()),
      );
      final value = await repository.conversation(1);
      expect(value.message, 'Original question');
      expect(value.messages, isEmpty);
      await expectLater(repository.support(1), throwsFormatException);
    },
  );

  test(
    'reply and privacy requests preserve supplied idempotency identifiers',
    () async {
      final sent = <Map<String, dynamic>>[];
      final repository = CustomerOperations(
        account: () => 'A',
        generation: () => 1,
        get: (path, {queryParameters}) async => response(thread()),
        post: (path, {data, options}) async {
          sent.add(Map<String, dynamic>.from(data as Map));
          return response(thread());
        },
      );
      await repository.reply(1, 2, 'Reply', 'same-request');
      await repository.reply(1, 2, 'Reply', 'same-request');
      expect(sent[0], sent[1]);
      await repository.requestPrivacy(
        kind: 'correction',
        password: 'fixture-only',
        requestId: 'privacy-request',
        changes: {'bio': 'Corrected'},
      );
      expect(sent.last['confirmed'], isTrue);
      expect(sent.last['changes'], {'bio': 'Corrected'});
    },
  );

  test(
    'support links are generic and reject foreign hosts and token-bearing URLs',
    () {
      final origin = Uri.parse(ApiConstants.baseUrl).origin;
      expect(
        SupportInboxLink.accepts(Uri.parse('$origin/support-inbox')),
        isTrue,
      );
      expect(
        SupportInboxLink.accepts(Uri.parse('cozyhealth://support-inbox')),
        isTrue,
      );
      for (final uri in [
        'https://foreign.example/support-inbox',
        '$origin/support-inbox?token=private',
        '$origin/support-inbox#private',
        'cozyhealth://support-inbox/other',
        'cozyhealth://support-inbox?account=A',
      ]) {
        expect(SupportInboxLink.accepts(Uri.parse(uri)), isFalse);
      }
    },
  );

  testWidgets(
    'failed replies retain text and reuse the request ID after refresh',
    (tester) async {
      var fail = true;
      final ids = <String>[];
      final repository = CustomerOperations(
        account: () => 'A',
        generation: () => 1,
        get: (path, {queryParameters}) async => response(thread()),
        post: (path, {data, options}) async {
          ids.add((data as Map)['request_id'] as String);
          if (fail) throw StateError('offline');
          return response(thread(version: 1));
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SupportConversationScreen(id: 1, repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('NEVER_RENDER_STAFF_NOTE'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('support-reply')),
        'Keep this draft',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('support-send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('support-send')));
      await tester.pumpAndSettle();
      expect(find.text('Keep this draft'), findsOneWidget);
      await tester.ensureVisible(find.text('Refresh conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refresh conversation'));
      await tester.pumpAndSettle();
      fail = false;
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('support-reply')))
            .controller
            ?.text,
        'Keep this draft',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('support-send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('support-send')));
      await tester.pumpAndSettle();
      expect(ids.length, 2);
      expect(ids.first, ids.last);
      expect(find.text('Keep this draft'), findsNothing);
      expect(find.textContaining('Reply saved.'), findsOneWidget);
    },
  );

  testWidgets(
    'privacy submission requires confirmation and retains input on failure',
    (tester) async {
      var posts = 0;
      final repository = CustomerOperations(
        account: () => 'A',
        generation: () => 1,
        get: (path, {queryParameters}) async => response({
          'data': {'data': <dynamic>[], 'last_page': 1},
        }),
        post: (path, {data, options}) async {
          posts++;
          throw StateError('offline');
        },
      );
      await tester.pumpWidget(
        MaterialApp(home: PrivacyRequestsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('privacy-password')),
        'fixture-password',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('privacy-submit')));
      await tester.tap(find.byKey(const ValueKey('privacy-submit')));
      await tester.pumpAndSettle();
      expect(posts, 0);
      await tester.tap(find.byKey(const ValueKey('privacy-confirm')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('privacy-submit')));
      await tester.pumpAndSettle();
      expect(posts, 1);
      expect(find.text('fixture-password'), findsOneWidget);
      expect(
        find.textContaining('Could not confirm your request.'),
        findsOneWidget,
      );
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'support conversation preserves layout at large text in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = CustomerOperations(
          account: () => 'A',
          generation: () => 1,
          get: (path, {queryParameters}) async => response(thread()),
          post: (path, {data, options}) async => response(thread()),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child ?? const SizedBox.shrink(),
            ),
            home: SupportConversationScreen(id: 1, repository: repository),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(const ValueKey('support-send')));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
