import 'dart:async';
import 'dart:typed_data';
import 'package:cozy_health/features/settings/data/avatar_repository.dart';
import 'package:cozy_health/features/settings/data/profile_repository.dart';
import 'package:cozy_health/core/models/next_of_kin_contact.dart';
import 'package:cozy_health/features/crisis/data/next_of_kin_repository.dart';
import 'package:cozy_health/features/crisis/presentation/screens/crisis_screens.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:cozy_health/features/auth/data/auth_service.dart';
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
import 'package:cozy_health/core/services/background_restore_service.dart';
import 'package:cozy_health/core/services/push_notification_service.dart';
import 'package:cozy_health/features/settings/presentation/screens/notification_preferences_screen.dart';
import 'package:cozy_health/features/notifications/presentation/widgets/push_notification_host.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cozy_health/core/services/user_data_merge.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/auth/presentation/screens/restore_screen.dart';
import '../../support/local_fonts.dart';

final date = DateTime.utc(2026, 10, 8);
Widget _notificationHost(BuildContext context, Widget? child) =>
    PushNotificationHost(child: child!);
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
    if (path == '/next-of-kin') {
      return {
        'data': {
          'id': 'primary',
          'contact': {
            'name': 'Real contact',
            'phone': '+2348031234567',
            'relationship': 'Sibling',
          },
          'client_updated_at': date.toIso8601String(),
        },
      };
    }
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

class SuccessfulLoginApi extends Fake implements ApiClient {
  @override
  void cancelSessionRequests() {}

  SuccessfulLoginApi({this.userId = '42'});
  final String userId;
  @override
  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
    Options? options,
  }) async => Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {
      'data': {
        'token': 'test-session',
        'user': {
          'id': userId,
          'name': 'Test User',
          'email': 'test@example.test',
        },
      },
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  late Directory temporary;
  late FakeApi api;
  final secureHiveKeys = <String, String>{};
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
    secureHiveKeys.addAll(await const FlutterSecureStorage().readAll());
  });
  setUp(() async {
    BackgroundRestoreService.instance.stop();
    secureHiveKeys.addAll(
      Map.fromEntries(
        (await const FlutterSecureStorage().readAll()).entries.where(
          (entry) => entry.key.startsWith('hive_'),
        ),
      ),
    );
    FlutterSecureStorage.setMockInitialValues(secureHiveKeys);
    SharedPreferences.setMockInitialValues({'install_marker_set': true});
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
    api = FakeApi();
  });
  tearDownAll(() async {
    BackgroundRestoreService.instance.stop();
    resetLocalTestFonts();
    await Hive.close();
    Hive.resetAdapters();
    await temporary.delete(recursive: true);
  });
  RestoreController controller() =>
      RestoreController(userId: '1', get: api.get, now: date);

  const kin = NextOfKinContact(
    name: 'Trusted Person',
    phone: '+2348031234567',
    relationship: 'Sibling',
  );

  test('next-of-kin persists offline and queues contact data only', () async {
    final repo = NextOfKinRepository();
    await repo.save(kin);
    expect((await repo.load())?.phone, kin.phone);
    final pending = local.pendingItems.single;
    expect(pending.type, 'next_of_kin');
    expect(pending.payload?['phone'], kin.phone);
    expect(pending.payload?.containsKey('message'), false);
    await (await local.settingsBox()).close();
    expect((await NextOfKinRepository().load())?.name, kin.name);
  });

  test('next-of-kin contact never leaks across accounts', () async {
    final repo = NextOfKinRepository();
    await repo.save(kin);
    await local.activateAccount('2');
    expect(await repo.load(), isNull);
    await local.activateAccount('1');
    expect((await repo.load())?.phone, kin.phone);
  });

  test(
    'next-of-kin removal prevents download resurrection and survives restart',
    () async {
      final repo = NextOfKinRepository();
      await repo.save(kin);
      await repo.save(null);
      expect(local.pendingItems.single.action, 'delete');
      await repo.merge({
        'id': 'primary',
        'contact': kin.toJson(),
        'client_updated_at': date.toIso8601String(),
      });
      expect(await repo.load(), isNull);
      await (await local.settingsBox()).close();
      expect(await NextOfKinRepository().load(), isNull);
    },
  );

  test('newer remote next-of-kin edit and removal restore correctly', () async {
    final repo = NextOfKinRepository();
    await repo.merge({
      'id': 'primary',
      'contact': kin.toJson(),
      'client_updated_at': date.toIso8601String(),
    });
    expect((await repo.load())?.phone, kin.phone);
    await repo.merge({
      'id': 'primary',
      'contact': null,
      'client_updated_at': date
          .add(const Duration(minutes: 1))
          .toIso8601String(),
    });
    await repo.merge({
      'id': 'primary',
      'contact': kin.toJson(),
      'client_updated_at': date.toIso8601String(),
    });
    expect(await repo.load(), isNull);
  });

  testWidgets(
    'editing a completed safety plan preserves existing contact details',
    (tester) async {
      final people = [
        {
          'name': 'Existing trusted person',
          'phone': '+2348011111111',
          'relation': 'Friend',
        },
      ];
      final professionals = [
        {'name': 'Therapist', 'phone': '+2348022222222', 'role': 'Therapist'},
      ];
      await tester.runAsync(() async {
        await local.saveSafetyPlan(
          SafetyPlan(
            id: 'saved-plan',
            warningSigns: ['Feeling isolated'],
            peopleToCall: people,
            professionals: professionals,
            isComplete: true,
            lastUpdatedAt: date,
          ),
        );
      });
      await tester.pumpWidget(const MaterialApp(home: SafetyPlanScreen()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Feeling isolated'), findsOneWidget);
      await tester.ensureVisible(find.text('Continue'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Continue'));
        for (
          var attempt = 0;
          attempt < 50 && !local.hasPending('safety_plan', 'saved-plan');
          attempt++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(local.getSafetyPlan()?.peopleToCall, people);
      expect(local.getSafetyPlan()?.professionals, professionals);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('fresh device with empty history requests restore', () async {
    expect(await RestoreService.prepare('1'), isTrue);
    expect(await RestoreService.required, isTrue);
  });

  test(
    'encrypted photo cache survives reopening and stays scoped to its account',
    () async {
      final profile = UserProfile(
        id: 'cached-avatar-profile',
        name: 'Person',
        email: 'sample@example.test',
        avatarUrl: 'https://storage.example.test/photo.jpg',
        avatarRevision: 1,
        updatedAt: date,
      );
      await local.saveUserProfile(profile);
      final bytes = Uint8List.fromList([1, 2, 3]);
      await (await local.settingsBox()).put('profile_avatar_bytes', {
        'profile_id': profile.id,
        'revision': 1,
        'bytes': bytes,
      });
      await (await local.settingsBox()).close();
      expect(await AvatarRepository().cachedPhoto(profile), bytes);
      await local.activateAccount('2');
      expect(await AvatarRepository().cachedPhoto(profile), isNull);
      await local.activateAccount('1');
      expect(await AvatarRepository().cachedPhoto(profile), bytes);
    },
  );

  test(
    'new avatar revisions merge independently of pending offline profile edits',
    () async {
      final edited = UserProfile(
        id: 'avatar-profile',
        name: 'Local edited name',
        email: 'sample@example.test',
        avatarUrl: 'asset:open-peeps-01',
        avatarRevision: 1,
        updatedAt: date.add(const Duration(days: 2)),
      );
      await ProfileRepository().saveProfile(edited);
      await UserDataMerge().apply('user_profile', {
        ...edited.toJson(),
        'name': 'Older server name',
        'avatar_url': 'asset:open-peeps-02',
        'avatar_revision': 2,
        'client_updated_at': date.toIso8601String(),
      });
      expect(local.getUserProfile()?.name, 'Local edited name');
      expect(local.getUserProfile()?.avatarUrl, 'asset:open-peeps-02');
      await UserDataMerge().apply('user_profile', {
        ...edited.toJson(),
        'avatar_url': null,
        'avatar_revision': 3,
      });
      expect(local.getUserProfile()?.avatarUrl, isNull);
      expect(local.getUserProfile()?.avatarRevision, 3);
    },
  );

  test(
    'saving a stale profile cannot restore an old avatar after removal',
    () async {
      final stale = UserProfile(
        id: 'avatar-profile',
        name: 'Person',
        email: 'sample@example.test',
        avatarUrl: 'asset:open-peeps-01',
        avatarRevision: 1,
        updatedAt: date,
      );
      await local.saveUserProfile(
        stale.copyWith(clearAvatarUrl: true, avatarRevision: 2),
      );
      await ProfileRepository().saveProfile(stale.copyWith(name: 'New name'));
      expect(local.getUserProfile()?.name, 'New name');
      expect(local.getUserProfile()?.avatarUrl, isNull);
      expect(local.getUserProfile()?.avatarRevision, 2);
    },
  );

  testWidgets(
    'internal simulations are visible and work when phone alerts are denied',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final push = PushNotificationService.instance;
      final previousStatus = push.phonePermission.status;
      final previousRequested = push.phonePermission.requested;
      push.phonePermission.status = PermissionStatus.permanentlyDenied;
      push.phonePermission.requested = true;
      final received = <AppNotification>[];
      final subscription = push.foreground.listen(received.add);
      await tester.runAsync(
        () => local.saveUserProfile(
          UserProfile(
            id: 'profile-1',
            name: 'Sample User',
            email: 'sample@example.test',
            updatedAt: date,
          ),
        ),
      );
      try {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: AppRouter.navigatorKey,
            home: const NotificationPreferencesScreen(),
            builder: _notificationHost,
          ),
        );
        await tester.pump();
        expect(find.text('Phone permission: Denied'), findsOneWidget);
        expect(find.text('Test mood'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('Test mood')).dy,
          lessThan(tester.getTopLeft(find.text('Phone permission: Denied')).dy),
        );
        for (final category in ['mood', 'journal', 'streak', 'affirmation']) {
          await tester.ensureVisible(find.text('Test $category'));
          await tester.pump();
          final routeBefore = ModalRoute.of(
            tester.element(find.byType(NotificationPreferencesScreen)),
          );
          final row = find.ancestor(
            of: find.text('Test $category'),
            matching: find.byType(ListTile),
          );
          await tester.tap(
            find.descendant(of: row, matching: find.text('Simulate')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 450));
          expect(received.last.type, category);
          expect(find.byKey(const Key('app-top-notice')), findsOneWidget);
          expect(
            find.textContaining('Test $category reminder'),
            findsOneWidget,
          );
          expect(
            ModalRoute.of(
              tester.element(find.byType(NotificationPreferencesScreen)),
            ),
            same(routeBefore),
          );
          await tester.tap(
            find.descendant(
              of: find.byKey(const Key('app-top-notice')),
              matching: find.byIcon(Icons.close),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 450));
          expect(find.byKey(const Key('app-top-notice')), findsNothing);
        }
        expect(local.appNotificationBox, isEmpty);
      } finally {
        await tester.runAsync(() => subscription.cancel());
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 6));
        push.phonePermission.status = previousStatus;
        push.phonePermission.requested = previousRequested;
      }
    },
    skip: !PushNotificationService.internalBuild,
  );

  test(
    'background restore coalesces requests and finishes without Continue',
    () async {
      await RestoreService.prepare('1');
      final waiting = Completer<dynamic>();
      final entered = Completer<void>();
      final service = BackgroundRestoreService(
        hasSession: () async => true,
        createController: (owner) => RestoreController(
          userId: owner,
          now: date,
          get: (path, query) {
            if (path == '/user/profile') {
              if (!entered.isCompleted) entered.complete();
              return waiting.future;
            }
            return api.get(path, query);
          },
        ),
      );
      final first = service.start('1');
      await entered.future;
      expect(service.busy, true);
      expect(await RestoreService.required, true);
      final second = service.start('1');
      expect(identical(first, second), true);
      waiting.complete(profile());
      await first;
      expect(service.state, BackgroundRestoreState.complete);
      expect(await RestoreService.required, false);
      expect(local.getUserProfile()?.name, 'Sample User');
      final calls = Map<String, int>.from(api.calls);
      await service.start('1');
      expect(api.calls, calls);
      expect(service.state, BackgroundRestoreState.complete);
      service.dispose();
    },
  );

  test(
    'background partial failure retains completion and retries only failed sections',
    () async {
      await RestoreService.prepare('1');
      api.failures.add('/mood-entries');
      final service = BackgroundRestoreService(
        hasSession: () async => true,
        createController: (owner) =>
            RestoreController(userId: owner, get: api.get, now: date),
      );
      await service.start('1');
      expect(service.state, BackgroundRestoreState.partial);
      expect((await local.settingsBox()).get('restore_incomplete_user'), '1');
      final journals = api.calls['/journal-entries'];
      api.failures.clear();
      await service.retry();
      expect(service.state, BackgroundRestoreState.complete);
      expect(api.calls['/journal-entries'], journals);
      expect(api.calls['/mood-entries'], 2);
      service.dispose();
    },
  );

  test(
    'stopping background work cannot clear the next session or merge its response',
    () async {
      final waiting = Completer<dynamic>();
      final entered = Completer<void>();
      final service = BackgroundRestoreService(
        hasSession: () async => true,
        createController: (owner) => RestoreController(
          userId: owner,
          now: date,
          get: (path, query) {
            if (path == '/user/profile') {
              entered.complete();
              return waiting.future;
            }
            return api.get(path, query);
          },
        ),
      );
      final work = service.start('1');
      await entered.future;
      await local.activateAccount('2');
      await TokenStorage().saveToken('second-session');
      waiting.complete(profile());
      await work;
      expect(local.getUserProfile(), isNull);
      expect(await TokenStorage().getToken(), 'second-session');
      expect(service.state, BackgroundRestoreState.idle);
      service.dispose();
    },
  );

  test(
    'login returns while the background profile download remains pending',
    () async {
      final waiting = Completer<dynamic>();
      final entered = Completer<void>();
      final service = BackgroundRestoreService(
        hasSession: () async => true,
        createController: (owner) => RestoreController(
          userId: owner,
          now: date,
          get: (path, query) {
            if (path == '/user/profile') {
              entered.complete();
              return waiting.future;
            }
            return api.get(path, query);
          },
        ),
      );
      await AuthService(
        apiClient: SuccessfulLoginApi(userId: '77'),
        backgroundRestore: service,
      ).login(
        email: 'test@example.test',
        password: 'test-password',
        stayLoggedIn: true,
      );
      await entered.future;
      expect(service.busy, true);
      expect(await TokenStorage().getToken(), 'test-session');
      final work = service.activeWork;
      service.stop();
      waiting.complete(profile());
      await work;
      service.dispose();
      await local.waitForSyncIdle();
      local.syncPaused = true;
      await local.activateAccount('1', email: 'sample@example.test');
    },
  );
  test(
    'successful server login recovers absent account cache from older reinstall',
    () async {
      SharedPreferences.setMockInitialValues({'install_marker_set': true});
      await EncryptedHive.prepareInstall(markerSet: true, hasLocalFiles: true);
      await local.activateAccount('42', email: 'test@example.test');
      final boxes = [
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
      ];
      await local.activateAccount('1', email: 'sample@example.test');
      for (final box in boxes) {
        final name = box.name;
        await box.close();
        await Hive.deleteBoxFromDisk(name);
      }
      await expectLater(local.activateAccount('42'), throwsStateError);
      await AuthService(apiClient: SuccessfulLoginApi()).login(
        email: 'test@example.test',
        password: 'test-password',
        stayLoggedIn: true,
      );
      expect(await TokenStorage().getToken(), 'test-session');
      expect((await local.settingsBox()).get('device_user_id'), '42');
      expect(local.getUserProfile()!.email, 'test@example.test');
      expect(await RestoreService.required, isTrue);
      await local.waitForSyncIdle();
      local.syncPaused = true;
      await local.activateAccount('1', email: 'sample@example.test');
    },
  );
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
    'an absent optional safety plan does not leave restore partial',
    () async {
      final restore = RestoreController(
        userId: '1',
        now: date,
        get: (path, query) async {
          if (path == '/safety-plan') return {'data': null};
          return await api.get(path, query);
        },
      );
      await restore.run();
      expect(restore.failed, isEmpty);
      await restore.finish();
      expect(
        (await local.settingsBox()).get('restore_incomplete_user'),
        isNull,
      );
      restore.dispose();
    },
  );
  test('bare paginators restore every page', () async {
    final pages = <int>[];
    final restore = RestoreController(
      userId: '1',
      now: date,
      get: (path, query) async {
        if (path != '/mood-entries') return api.get(path, query);
        final current = query['page'] as int;
        pages.add(current);
        return {
          'data': [mood('m$current')],
          'last_page': 2,
        };
      },
    );
    await restore.run();
    expect(restore.failed, isEmpty);
    expect(pages, [1, 2]);
    expect(local.moodBox.keys, containsAll(['m1', 'm2']));
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
