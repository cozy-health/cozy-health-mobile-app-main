import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/models/chat_message.dart';
import 'package:cozy_health/core/models/chat_conversation.dart';
import 'package:cozy_health/core/models/safety_plan.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';
import 'package:cozy_health/core/models/saved_article.dart';
import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/core/models/subscription_status.dart';
import 'package:cozy_health/core/models/user_preferences.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/restore_service.dart';
import 'package:cozy_health/core/services/user_data_merge.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/auth/presentation/screens/restore_screen.dart';
import '../../support/local_fonts.dart';

final date = DateTime.utc(2026, 10, 8);
Map<String, dynamic> mood(
  String id, {
  DateTime? updated,
  String value = 'calm',
}) => {
  'id': id,
  'user_id': '1',
  'mood': value,
  'intensity': 5,
  'client_created_at': date.toIso8601String(),
  'client_updated_at': (updated ?? date).toIso8601String(),
};
Map<String, dynamic> page(List<Map<String, dynamic>> rows, {int last = 1}) => {
  'data': {'data': rows, 'last_page': last},
};
Map<String, dynamic> profile() => {
  'data': {
    'id': 'profile-1',
    'user_id': '1',
    'name': 'Sample User',
    'email': 'sample@example.test',
    'client_updated_at': date.toIso8601String(),
    'preferences': {
      'focus_areas': ['sleep'],
      'current_challenges': ['work'],
      'check_in_frequency': 'few_times',
      'attribution': null,
      'completed_at': date.toIso8601String(),
      'skipped': false,
    },
  },
};

class FakeApi {
  final calls = <String, int>{};
  final failures = <String>{};
  final rows = <String, List<Map<String, dynamic>>>{};
  Future<dynamic> get(String path, Map<String, dynamic> query) async {
    calls.update(path, (count) => count + 1, ifAbsent: () => 1);
    if (failures.contains(path)) throw StateError('Unavailable');
    if (path == '/user/profile') return profile();
    if (path == '/safety-plan') {
      return {
        'data': {
          'id': 'plan-1',
          'user_id': '1',
          'is_complete': true,
          'last_updated_at': date.toIso8601String(),
          'people': [
            {'name': 'Sample contact', 'phone': '000-0000'},
          ],
        },
      };
    }
    return page(rows[path] ?? []);
  }
}

class WidgetController extends RestoreController {
  WidgetController({bool failure = false}) : super(userId: '1') {
    busy = !failure;
    if (failure) failed.add('Mood entries');
  }
  bool didCancel = false;
  bool didRetry = false;
  bool didFinish = false;
  @override
  int get restored => 47;
  @override
  double get progress => .5;
  @override
  Future<void> run({bool retryOnly = false}) async {
    didRetry = retryOnly;
  }

  @override
  Future<void> cancel() async {
    didCancel = true;
  }

  @override
  Future<void> finish({bool acceptPartial = false}) async {
    didFinish = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  late Directory temporary;
  late FakeApi api;
  setUpAll(() async {
    await installLocalTestFonts();
    FlutterSecureStorage.setMockInitialValues({});
    temporary = await Directory.systemTemp.createTemp('cozy_restore_test_');
    Hive.init(temporary.path);
    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(ChatConversationAdapter());
    Hive.registerAdapter(SafetyPlanAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(QuizAttemptAdapter());
    Hive.registerAdapter(SavedArticleAdapter());
    Hive.registerAdapter(AppNotificationAdapter());
    Hive.registerAdapter(SubscriptionStatusAdapter());
    Hive.registerAdapter(UserPreferencesAdapter());
    local.syncPaused = true;
    await local.activateAccount('1', email: 'sample@example.test');
  });
  setUp(() async {
    await local.activateAccount('1', email: 'sample@example.test');
    for (final box in [
      local.moodBox,
      local.journalBox,
      local.chatMessageBox,
      local.chatConversationBox,
      local.safetyPlanBox,
      local.userProfileBox,
      local.quizAttemptBox,
      local.savedArticleBox,
      local.appNotificationBox,
      local.subscriptionStatusBox,
      local.syncQueueBox,
      await local.preferencesBox(),
      await local.settingsBox(),
    ]) {
      await box.clear();
    }
    await (await local.settingsBox()).put('device_user_id', '1');
    FlutterSecureStorage.setMockInitialValues({});
    api = FakeApi();
  });
  tearDownAll(() async {
    resetLocalTestFonts();
    await Hive.close();
    Hive.resetAdapters();
    await temporary.delete(recursive: true);
  });
  RestoreController controller() =>
      RestoreController(userId: '1', get: api.get, now: date);

  test('fresh device with empty history requests restore', () async {
    expect(await RestoreService.prepare('1'), isTrue);
    expect(await RestoreService.required, isTrue);
  });
  test('completed restore skips subsequent login', () async {
    final restore = controller();
    await RestoreService.prepare('1');
    await restore.run();
    await restore.finish();
    expect(await RestoreService.prepare('1'), isFalse);
    expect((await local.settingsBox()).get('has_restored_on_device'), isTrue);
    restore.dispose();
  });
  test(
    'existing history skips restore without removing local records',
    () async {
      await local.saveMoodEntry(MoodEntry.fromJson(mood('local')));
      expect(await RestoreService.prepare('1'), isFalse);
      expect(local.moodBox.containsKey('local'), isTrue);
    },
  );
  test('registration has no existing server backup to restore', () async {
    expect(await RestoreService.prepare('1', registration: true), isFalse);
  });
  test('restores all available domains and counts distinct items', () async {
    api.rows.addAll({
      '/mood-entries': [mood('m1'), mood('m2')],
      '/journal-entries': [
        {
          'id': 'j1',
          'user_id': '1',
          'body': 'A quiet walk.',
          'created_at': date.toIso8601String(),
          'updated_at': date.toIso8601String(),
        },
      ],
      '/quiz-attempts': [
        {
          'id': 'q1',
          'quiz_slug': 'wellbeing',
          'score': 2,
          'completed_at': date.toIso8601String(),
        },
      ],
      '/content/saved': [
        {
          'id': 'saved-1',
          'article_id': 'breathing',
          'title': 'Breathing',
          'saved_at': date.toIso8601String(),
        },
      ],
      '/notifications': [
        {
          'id': 'n1',
          'is_read': true,
          'title': 'Welcome',
          'created_at': date.toIso8601String(),
          'read_at': date.toIso8601String(),
        },
      ],
      '/conversations': [
        {
          'id': 'c1',
          'title': 'Getting started',
          'created_at': date.toIso8601String(),
          'updated_at': date.toIso8601String(),
        },
      ],
    });
    final restore = controller();
    await restore.run();
    expect(restore.failed, isEmpty);
    expect(restore.progress, 1);
    expect(restore.restored, 11);
    expect(local.getUserProfile()?.id, 'profile-1');
    expect((await local.getUserPreferences())?.focusAreas, ['sleep']);
    expect(
      local.getSafetyPlan()?.peopleToCall?.single['name'],
      'Sample contact',
    );
    expect(local.moodBox.length, 2);
    expect(local.journalBox.get('j1')?.createdAt.toUtc(), date);
    expect(local.quizAttemptBox.length, 1);
    expect(local.savedArticleBox.get('breathing')?.title, 'Breathing');
    expect(restore.unavailable, isNot(contains('Saved articles')));
    expect(local.appNotificationBox.get('n1')?.read, isTrue);
    expect(local.chatConversationBox.length, 1);
    expect(local.chatMessageBox, isEmpty);
    expect(api.calls.keys.any((path) => path.contains('/messages')), isFalse);
    expect(api.calls.containsKey('/emergency-contacts'), isFalse);
    expect(api.calls.containsKey('/content/saved'), isTrue);
    restore.dispose();
  });
  test(
    'partial failure continues and retry fetches only failed sets',
    () async {
      api.failures.add('/mood-entries');
      api.rows['/journal-entries'] = [
        {'id': 'j1', 'body': 'A small thought.'},
      ];
      final restore = controller();
      await restore.run();
      expect(restore.failed, {'Mood entries'});
      expect(local.journalBox.length, 1);
      final prior = Map<String, int>.from(api.calls);
      api.failures.clear();
      api.rows['/mood-entries'] = [mood('m1')];
      await restore.run(retryOnly: true);
      expect(restore.failed, isEmpty);
      expect(api.calls['/mood-entries'], 2);
      for (final path in prior.keys.where((path) => path != '/mood-entries')) {
        expect(api.calls[path], prior[path]);
      }
      restore.dispose();
    },
  );
  test('partial continuation remains retryable on next login', () async {
    await RestoreService.prepare('1');
    api.failures.add('/mood-entries');
    final restore = controller();
    await restore.run();
    await restore.finish(acceptPartial: true);
    expect(await RestoreService.required, isFalse);
    expect(await RestoreService.prepare('1'), isTrue);
    restore.dispose();
  });
  test(
    'paginated history downloads recent pages and leaves local-only entries',
    () async {
      await local.saveMoodEntry(MoodEntry.fromJson(mood('offline-only')));
      final pages = <int>[];
      final restore = RestoreController(
        userId: '1',
        now: date,
        get: (path, query) async {
          if (path != '/mood-entries') return api.get(path, query);
          final current = query['page'] as int;
          pages.add(current);
          return page([
            current == 1
                ? mood('recent')
                : {
                    ...mood('old'),
                    'client_created_at': date
                        .subtract(const Duration(days: 91))
                        .toIso8601String(),
                  },
          ], last: 3);
        },
      );
      await restore.run();
      expect(pages, [1, 2]);
      expect(local.moodBox.keys, containsAll(['recent', 'offline-only']));
      expect(local.moodBox.containsKey('old'), isFalse);
      restore.dispose();
    },
  );
  test(
    'retrying a partially downloaded page does not double-count records',
    () async {
      var failSecond = true;
      final restore = RestoreController(
        userId: '1',
        now: date,
        get: (path, query) async {
          if (path != '/mood-entries') return api.get(path, query);
          if (query['page'] == 2 && failSecond) {
            throw StateError('Temporary failure');
          }
          return page([mood('m${query['page']}')], last: 2);
        },
      );
      await restore.run();
      final before = restore.restored;
      failSecond = false;
      await restore.run(retryOnly: true);
      expect(restore.restored, before + 1);
      expect(local.moodBox.length, 2);
      restore.dispose();
    },
  );
  test('newer local record wins and is queued for upload', () async {
    await local.saveMoodEntry(
      MoodEntry.fromJson(
        mood('m1', updated: date.add(const Duration(hours: 1)), value: 'good'),
      ),
    );
    await UserDataMerge().apply('mood_entry', mood('m1'));
    expect(local.moodBox.get('m1')?.mood, 'good');
    expect(local.hasPending('mood_entry', 'm1'), isTrue);
  });
  test('newer server record wins and removes obsolete queued edit', () async {
    final value = mood('m1');
    await local.saveMoodEntry(MoodEntry.fromJson(value));
    await local.enqueueSync(
      type: 'mood_entry',
      action: 'upsert',
      recordId: 'm1',
      payload: value,
    );
    await UserDataMerge().apply(
      'mood_entry',
      mood('m1', updated: date.add(const Duration(hours: 1)), value: 'good'),
    );
    expect(local.moodBox.get('m1')?.mood, 'good');
    expect(local.hasPending('mood_entry', 'm1'), isFalse);
  });
  test('equal timestamps retain pending local edit', () async {
    final value = mood('m1', value: 'good');
    await local.saveMoodEntry(MoodEntry.fromJson(value));
    await local.enqueueSync(
      type: 'mood_entry',
      action: 'upsert',
      recordId: 'm1',
      payload: value,
    );
    await UserDataMerge().apply('mood_entry', mood('m1'));
    expect(local.moodBox.get('m1')?.mood, 'good');
    expect(local.hasPending('mood_entry', 'm1'), isTrue);
  });
  test('draft journal cannot be overwritten by downloaded content', () async {
    await local.saveJournalEntry(
      JournalEntry.fromJson({
        'id': 'j1',
        'body': 'Draft',
        'is_draft': true,
        'client_updated_at': date.toIso8601String(),
      }),
    );
    await UserDataMerge().apply('journal_entry', {
      'id': 'j1',
      'body': 'Server',
      'client_updated_at': date.add(const Duration(hours: 1)).toIso8601String(),
    });
    expect(local.journalBox.get('j1')?.body, 'Draft');
    expect(local.pendingItems, isEmpty);
  });
  test('pending deletion prevents downloaded record resurrection', () async {
    await local.enqueueSync(
      type: 'mood_entry',
      action: 'delete',
      recordId: 'm1',
      payload: null,
    );
    await UserDataMerge().apply('mood_entry', mood('m1'));
    expect(local.moodBox.containsKey('m1'), isFalse);
    expect(local.pendingItems.single.action, 'delete');
  });
  test('record belonging to another user is rejected', () async {
    await expectLater(
      UserDataMerge().apply('mood_entry', {...mood('m1'), 'user_id': '2'}),
      throwsFormatException,
    );
    expect(local.moodBox, isEmpty);
  });
  test('account switching preserves isolated data and queue', () async {
    await local.saveMoodEntry(MoodEntry.fromJson(mood('private')));
    await local.enqueueSync(
      type: 'mood_entry',
      action: 'upsert',
      recordId: 'private',
      payload: mood('private'),
    );
    await local.activateAccount('2', email: 'second@example.test');
    expect(local.moodBox.containsKey('private'), isFalse);
    expect(local.pendingItems, isEmpty);
    await local.activateAccount('1', email: 'sample@example.test');
    expect(local.moodBox.containsKey('private'), isTrue);
    expect(local.hasPending('mood_entry', 'private'), isTrue);
  });
  test('cancel clears login and blocks an in-flight restore write', () async {
    await RestoreService.prepare('1');
    final waiting = Completer<dynamic>();
    final requested = Completer<void>();
    final restore = RestoreController(
      userId: '1',
      now: date,
      get: (path, query) {
        if (path == '/user/profile') {
          if (!requested.isCompleted) requested.complete();
          return waiting.future;
        }
        return api.get(path, query);
      },
    );
    final run = restore.run();
    await requested.future;
    await restore.cancel();
    waiting.complete(profile());
    await run;
    expect(await TokenStorage().getToken(), isNull);
    expect(local.getUserProfile(), isNull);
    await local.activateAccount('1');
    expect(local.getUserProfile(), isNull);
    expect(await RestoreService.prepare('1'), isTrue);
    restore.dispose();
  });
  test('progress emits increasing distinct restored counts', () async {
    api.rows['/mood-entries'] = [mood('m1'), mood('m2')];
    final restore = controller();
    final counts = <int>[];
    restore.addListener(() => counts.add(restore.restored));
    await restore.run();
    expect(counts, containsAllInOrder([4, 5, 6]));
    expect(counts.last, restore.restored);
    restore.dispose();
  });

  test('failed preferences retry refetches their profile source', () async {
    var broken = true;
    var profileCalls = 0;
    final restore = RestoreController(
      userId: '1',
      now: date,
      get: (path, query) async {
        if (path != '/user/profile') return api.get(path, query);
        profileCalls++;
        final value = profile();
        if (broken) {
          (value['data']['preferences'] as Map)['completed_at'] = 'invalid';
        }
        return value;
      },
    );
    await restore.run();
    expect(restore.failed, {'User preferences'});
    broken = false;
    await restore.run(retryOnly: true);
    expect(restore.failed, isEmpty);
    expect(profileCalls, 2);
    expect((await local.getUserPreferences())?.focusAreas, ['sleep']);
    restore.dispose();
  });

  Future<GoRouter> mount(
    WidgetTester tester,
    WidgetController controller,
  ) async {
    final router = GoRouter(
      initialLocation: '/restore',
      routes: [
        GoRoute(
          path: '/restore',
          builder: (_, _) => RestoreScreen(controller: controller),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login destination')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home destination')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    return router;
  }

  test(
    'auth placeholder does not replace the canonical server profile',
    () async {
      await local.saveUserProfile(
        UserProfile(
          id: '1',
          name: 'Login placeholder',
          email: 'sample@example.test',
          updatedAt: date.add(const Duration(days: 1)),
        ),
      );
      await (await local.settingsBox()).put('auth_profile_placeholder', true);
      await UserDataMerge().apply(
        'user_profile',
        Map<String, dynamic>.from(profile()['data']),
      );
      expect(local.getUserProfile()?.id, 'profile-1');
      expect(local.getUserProfile()?.name, 'Sample User');
      expect(local.pendingItems, isEmpty);
    },
  );
  test(
    'restore queues newer onboarding answers with a valid operation ID',
    () async {
      final preferences = UserPreferences(
        focusAreas: ['stress'],
        currentChallenges: ['school'],
        checkInFrequency: 'daily',
        attribution: null,
        completedAt: date.add(const Duration(days: 1)),
        skipped: false,
      );
      await (await local.preferencesBox()).put('current', preferences);
      final restore = controller();
      await restore.run();
      expect((await local.getUserPreferences())?.focusAreas, ['stress']);
      final pending = local.pendingItems.singleWhere(
        (item) => item.type == 'user_preferences',
      );
      expect(pending.payload!['id'], pending.recordId);
      restore.dispose();
    },
  );
  test(
    'account change during download prevents writes into either account',
    () async {
      final waiting = Completer<dynamic>();
      final requested = Completer<void>();
      final restore = RestoreController(
        userId: '1',
        now: date,
        get: (path, query) {
          if (path == '/mood-entries') {
            requested.complete();
            return waiting.future;
          }
          return api.get(path, query);
        },
      );
      final run = restore.run();
      await requested.future;
      await local.activateAccount('2');
      await (await local.settingsBox()).put('device_user_id', '2');
      waiting.complete(page([mood('in-flight')]));
      await run;
      expect(local.moodBox.containsKey('in-flight'), isFalse);
      await local.activateAccount('1');
      expect(local.moodBox.containsKey('in-flight'), isFalse);
      restore.dispose();
    },
  );
  testWidgets('restore UI shows item count and progress', (tester) async {
    final router = await mount(tester, WidgetController());
    expect(find.text('Restoring your data... 47 items'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .5,
    );
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
  testWidgets('cancel returns to login', (tester) async {
    final state = WidgetController();
    final router = await mount(tester, state);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(state.didCancel, isTrue);
    expect(find.text('Login destination'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
  testWidgets('retry button requests failed sets only', (tester) async {
    final state = WidgetController(failure: true);
    final router = await mount(tester, state);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(state.didRetry, isTrue);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
  testWidgets('partial continuation reaches Home', (tester) async {
    final state = WidgetController(failure: true);
    final router = await mount(tester, state);
    await tester.ensureVisible(find.text('Continue with restored data'));
    await tester.tap(find.text('Continue with restored data'));
    await tester.pumpAndSettle();
    expect(state.didFinish, isTrue);
    expect(find.text('Home destination'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
}
