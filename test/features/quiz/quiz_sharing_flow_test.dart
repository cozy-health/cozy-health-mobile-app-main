import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_shared_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_result_screen.dart';
import '../../support/repository_fixture.dart';

class _HeldResult implements HttpClientAdapter {
  final started = Completer<void>();
  final released = Completer<void>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelled,
  ) async {
    started.complete();
    await released.future;
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'quiz_title': 'Private delayed result',
          'score': 1,
          'maximum_score': 3,
          'interpretation': 'Fixture',
          'completed_at': '2026-10-13',
          'disclaimer': 'Fixture disclaimer',
        },
      }),
      200,
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
  final fixture = RepositoryFixture<QuizAttempt>(
    LocalDbService.quizAttemptBoxName,
    QuizAttemptAdapter(),
  );
  setUpAll(fixture.open);
  setUp(fixture.reset);
  tearDownAll(fixture.close);
  Map<String, dynamic> inbox(String sender) => {
    'data': {
      'data': [
        {
          'id': 'share-$sender',
          'sender': sender,
          'quiz_title': 'Shared fixture',
          'completed_at': '2026-10-13',
          'read_at': null,
        },
      ],
      'last_page': 2,
    },
  };
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'friend inbox pages through authenticated results and clears on logout',
    (tester) async {
      fixture.body = inbox('First friend');
      await tester.pumpWidget(const MaterialApp(home: QuizSharedScreen()));
      await settle(tester);
      expect(find.text('First friend'), findsOneWidget);
      expect(find.text('Page 1 of 2'), findsOneWidget);
      fixture.body = inbox('Second friend');
      await tester.tap(find.text('Next'));
      await settle(tester);
      expect(find.text('First friend'), findsNothing);
      expect(find.text('Second friend'), findsOneWidget);
      expect(fixture.requests.last.queryParameters['page'], '2');
      await tester.runAsync(() => TokenStorage().clearToken());
      await tester.pumpAndSettle();
      expect(find.text('Second friend'), findsNothing);
      expect(
        find.text('Sign in again to view shared results.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('a result arriving after logout cannot repopulate the screen', (
    tester,
  ) async {
    final original = ApiClient.instance.transportForTesting;
    final held = _HeldResult();
    ApiClient.instance.transportForTesting = held;
    addTearDown(() => ApiClient.instance.transportForTesting = original);
    await tester.pumpWidget(
      const MaterialApp(home: QuizSharedScreen(shareId: 'share-held')),
    );
    for (var i = 0; i < 20 && !held.started.isCompleted; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(held.started.isCompleted, isTrue);
    await tester.runAsync(() async {
      await TokenStorage().clearToken();
      held.released.complete();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Private delayed result'), findsNothing);
    expect(find.text('Sign in again to view shared results.'), findsOneWidget);
  });
  testWidgets('deletion cannot restore a result from navigation extras', (
    tester,
  ) async {
    final attempt = QuizAttempt(
      id: 'saved',
      quizId: 'fixture',
      quizSlug: 'fixture',
      quizTitle: 'Private saved result',
      answers: [],
      score: 0,
      interpretation: '',
      isCrisisFlagged: false,
      completedAt: DateTime.utc(2026, 10, 13),
    );
    await tester.runAsync(() => fixture.box.put(attempt.id, attempt));
    await tester.pumpWidget(
      MaterialApp(home: QuizResultScreen(extra: {'attempt': attempt})),
    );
    await settle(tester);
    expect(find.text('Private saved result'), findsOneWidget);
    await tester.runAsync(() => fixture.box.delete(attempt.id));
    await tester.pumpAndSettle();
    expect(find.text('Private saved result'), findsNothing);
    expect(find.text('This result is no longer available.'), findsOneWidget);
  });
}
