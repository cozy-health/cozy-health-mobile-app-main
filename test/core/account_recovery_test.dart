import 'package:cozy_health/features/crisis/presentation/screens/crisis_screens.dart';
import 'package:cozy_health/features/settings/presentation/screens/report_problem_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/change_password_screen.dart';
import 'package:cozy_health/core/widgets/security_blur.dart';
import 'package:flutter/material.dart';
import 'package:cozy_health/core/models/safety_plan.dart';
import 'package:cozy_health/features/crisis/services/safety_plan_storage.dart';
import 'package:cozy_health/features/crisis/presentation/widgets/next_of_kin_panel.dart';
import '../support/local_fonts.dart';
import 'package:cozy_health/core/models/chat_message.dart';
import 'package:cozy_health/core/models/subscription_status.dart';
import 'package:cozy_health/core/models/user_preferences.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/repositories/mood_repository.dart';
import 'package:cozy_health/core/repositories/journal_repository.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/mood_draft_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/settings/data/profile_repository.dart';
import 'package:cozy_health/core/services/user_data_merge.dart';
import 'package:cozy_health/features/auth/data/auth_service.dart';
import 'package:cozy_health/features/crisis/data/next_of_kin_repository.dart';
import 'package:cozy_health/core/models/next_of_kin_contact.dart';
import 'package:hive/hive.dart';
import '../support/repository_fixture.dart';
import '../support/mobile_sync_contract.dart';

class OfflineContactRepository extends NextOfKinRepository {
  @override
  Future<void> refresh() async {}
}

class TrackingTransport implements HttpClientAdapter {
  int sent = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    sent++;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class DelayedFailure implements HttpClientAdapter {
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    entered.complete();
    await release.future;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  final fixture = RepositoryFixture<MoodEntry>(
    LocalDbService.moodBoxName,
    MoodEntryAdapter(),
  );
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await fixture.open();
    await installLocalTestFonts();
    registerSyncAdapters();
  });
  setUp(() async {
    local.syncPaused = true;
    for (final id in ['A', 'B']) {
      await local.activateAccount(id);
      await local.clearAllUserData();
    }
    await local.activateAccount('A');
    await TokenStorage().saveToken('account-A');
  });
  tearDownAll(() async {
    resetLocalTestFonts();
    await fixture.close();
  });

  for (final domain in ['mood', 'journal', 'profile']) {
    test(
      'a delayed $domain failure cannot return the next account cache',
      () async {
        final transport = DelayedFailure();
        ApiClient().transportForTesting = transport;
        final Future<dynamic> request = switch (domain) {
          'mood' => MoodRepository().fetchMoodEntries(),
          'journal' => JournalRepository().fetchJournalEntries(),
          _ => ProfileRepository().fetchProfile(),
        };
        await transport.entered.future;
        await local.activateAccount('B');
        await TokenStorage().saveToken('account-B');
        final now = DateTime.now();
        await local.saveMoodEntry(
          MoodEntry(
            id: 'B-mood',
            mood: 'calm',
            intensity: 5,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await local.saveJournalEntry(
          JournalEntry(
            id: 'B-journal',
            type: 'free',
            body: 'B private',
            wordCount: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await local.saveUserProfile(
          UserProfile(
            id: 'B-profile',
            name: 'B private',
            email: 'b@example.test',
            updatedAt: now,
          ),
        );
        transport.release.complete();
        expect(await request, domain == 'profile' ? isNull : isEmpty);
      },
    );
  }

  test(
    'a mood draft is restored only for its owner after reopening storage',
    () async {
      final draft = MoodDraftService();
      await draft.save({'note': 'A private unfinished mood'});
      final box = await local.settingsBox();
      await box.flush();
      await box.close();
      await local.settingsBox();
      expect((await draft.loadToday())?['note'], 'A private unfinished mood');
      await local.activateAccount('B');
      expect(await MoodDraftService().loadToday(), isNull);
      await expectLater(draft.save({'note': 'stale A form'}), throwsStateError);
      await local.activateAccount('A');
      expect(
        (await MoodDraftService().loadToday())?['note'],
        'A private unfinished mood',
      );
    },
  );
  test(
    'all saved domains and queued changes survive logout and disk reopening without crossing accounts',
    () async {
      final operations = mobileSyncOperations();
      for (final op in operations) {
        final row = Map<String, dynamic>.from(op['data'] as Map);
        switch (op['type']) {
          case 'chat_message':
            await local.saveChatMessage(ChatMessage.fromJson(row));
          case 'subscription':
            await local.saveSubscriptionStatus(
              SubscriptionStatus.fromJson(row),
            );
          case 'user_preferences':
            await local.saveUserPreferences(UserPreferences.fromJson(row));
          default:
            await UserDataMerge().apply(op['type'] as String, row);
        }
        await local.enqueueSync(
          type: op['type'] as String,
          action: 'upsert',
          recordId: row['id'] as String,
          payload: row,
        );
      }
      final journal = JournalEntry.fromJson(
        Map<String, dynamic>.from(operations[1]['data'] as Map),
      );
      await local.saveJournalDraft(
        JournalEntry.fromJson({
          ...journal.toJson(),
          'id': 'unfinished-journal',
          'is_draft': true,
        }),
      );
      await MoodDraftService().save({'note': 'unfinished mood'});
      await NextOfKinRepository().save(
        const NextOfKinContact(
          name: 'A contact',
          phone: '+2348031234567',
          relationship: 'Sibling',
        ),
      );
      await (await local.settingsBox()).put('provider_conversations_v1', {
        'threads': [
          {'id': 1, 'content': 'A provider message'},
        ],
      });
      final queue = local.pendingItems.map((i) => i.toJson()).toList();
      await AuthService().logout();
      expect(local.pendingItems, isEmpty);
      await local.activateAccount('B');
      expect(local.getAllMoodEntries(), isEmpty);
      expect(local.getAllJournalEntries(), isEmpty);
      expect(local.getJournalDraft('unfinished-journal'), isNull);
      expect(await MoodDraftService().loadToday(), isNull);
      expect(local.getAllChatConversations(), isEmpty);
      expect(local.chatMessageBox.values, isEmpty);
      expect(local.getSafetyPlan(), isNull);
      expect(local.getUserProfile(), isNull);
      expect(local.getAllQuizAttempts(), isEmpty);
      expect(local.getAllSavedArticles(), isEmpty);
      expect(local.getAllAppNotifications(), isEmpty);
      expect(local.getSubscriptionStatus(), isNull);
      expect(await local.getUserPreferences(), isNull);
      expect(await NextOfKinRepository().load(), isNull);
      expect(
        (await local.settingsBox()).get('provider_conversations_v1'),
        isNull,
      );
      expect(local.pendingItems, isEmpty);
      await Hive.close();
      await local.activateAccount('A');
      expect(local.getAllMoodEntries(), hasLength(1));
      expect(local.getAllJournalEntries(), hasLength(1));
      expect(local.getJournalDraft('unfinished-journal')?.isDraft, isTrue);
      expect(
        (await MoodDraftService().loadToday())?['note'],
        'unfinished mood',
      );
      expect(local.getAllChatConversations(), hasLength(1));
      expect(local.chatMessageBox.values, hasLength(1));
      expect(local.getSafetyPlan(), isNotNull);
      expect(local.getUserProfile()?.name, 'Synthetic user');
      expect(local.getAllQuizAttempts(), hasLength(1));
      expect(local.getAllSavedArticles(), hasLength(1));
      expect(local.getAllAppNotifications(), hasLength(1));
      expect(local.getSubscriptionStatus(), isNotNull);
      expect((await local.getUserPreferences())?.focusAreas, ['Sleep']);
      expect((await NextOfKinRepository().load())?.name, 'A contact');
      expect(
        (await local.settingsBox()).get('provider_conversations_v1'),
        isNotNull,
      );
      expect(local.pendingItems.map((i) => i.toJson()).toList(), queue);
    },
  );
  test(
    'a debounced safety-plan save cannot run under the next account',
    () async {
      final storage = SafetyPlanStorage();
      final plan = SafetyPlan(
        id: 'A-plan',
        warningSigns: ['A private warning'],
        isComplete: false,
        lastUpdatedAt: DateTime.now(),
      );
      final save = storage.save(plan, debounce: true);
      await local.activateAccount('B');
      await save.timeout(const Duration(seconds: 2));
      expect(local.getSafetyPlan(), isNull);
      expect(local.pendingItems, isEmpty);
      storage.dispose();
    },
  );

  test('disposing a pending safety-plan save settles its caller', () async {
    final storage = SafetyPlanStorage();
    final save = storage.save(SafetyPlan.empty(), debounce: true);
    storage.dispose();
    await save.timeout(const Duration(seconds: 2));
    expect(local.pendingItems, isEmpty);
  });

  test(
    'account cleanup cannot erase data from a concurrently activated account',
    () async {
      final now = DateTime.now();
      for (final id in ['B', 'A']) {
        await local.activateAccount(id);
        await local.saveMoodEntry(
          MoodEntry(
            id: 'same-id',
            mood: 'calm',
            intensity: 5,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await local.saveJournalEntry(
          JournalEntry(
            id: 'same-id',
            type: 'free',
            body: '$id private',
            wordCount: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await local.enqueueSync(
          type: 'journal_entry',
          action: 'upsert',
          recordId: 'same-id',
          payload: {'id': 'same-id', 'body': '$id private'},
        );
      }
      final cleanup = local.clearAllUserData();
      await local.activateAccount('B');
      await cleanup;
      expect(local.getAllMoodEntries(), hasLength(1));
      expect(local.getAllJournalEntries().single.body, 'B private');
      expect(local.pendingItems, hasLength(1));
    },
  );

  testWidgets(
    'an open next-of-kin form hides its old account details on switching',
    (tester) async {
      await tester.runAsync(
        () => NextOfKinRepository().save(
          const NextOfKinContact(
            name: 'A private contact',
            phone: '+2348031234567',
            relationship: 'Sibling',
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: NextOfKinPanel(repository: OfflineContactRepository()),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(find.text('A private contact'), findsOneWidget);
      await tester.runAsync(() => local.activateAccount('B'));
      await tester.pump();
      expect(find.text('A private contact'), findsNothing);
      expect(find.text('+2348031234567'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'an API write is bound to the session at the instant it is called',
    () async {
      final transport = TrackingTransport();
      ApiClient().transportForTesting = transport;
      final request = ApiClient().post(
        '/support/reports',
        data: {'message': 'A private report'},
      );
      final checked = expectLater(request, throwsA(isA<Exception>()));
      await TokenStorage().saveToken('new-account-session');
      await checked;
      expect(transport.sent, 0);
    },
  );

  testWidgets(
    'the existing sensitive-screen wrapper removes unfinished form text after account switching',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SecurityBlur(child: TextField())),
        ),
      );
      await tester.enterText(
        find.byType(TextField),
        'A private unfinished form',
      );
      await tester.runAsync(() => local.activateAccount('B'));
      await tester.pump();
      expect(find.text('A private unfinished form'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final entry in <String, Widget>{
    'support report': const ReportProblemScreen(),
    'password': const ChangePasswordScreen(),
  }.entries) {
    testWidgets(
      '${entry.key} form removes unfinished account input on switching',
      (tester) async {
        await tester.pumpWidget(MaterialApp(home: entry.value));
        await tester.enterText(
          find.byType(TextField).first,
          'A private unfinished input',
        );
        await tester.runAsync(() => local.activateAccount('B'));
        await tester.pump();
        expect(find.byType(TextField), findsNothing);
        expect(find.text('A private unfinished input'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('public emergency resources stay available after logout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CrisisResourcesHubScreen()),
    );
    expect(find.text("You're not\nalone."), findsOneWidget);
    await tester.runAsync(() => TokenStorage().clearToken());
    await tester.pump();
    expect(find.text("You're not\nalone."), findsOneWidget);
    expect(find.text('Contact next of kin'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
