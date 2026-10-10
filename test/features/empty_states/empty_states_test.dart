import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cozy_health/core/widgets/skeleton_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/widgets/empty_state.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/core/models/saved_article.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';
import 'package:cozy_health/core/models/safety_plan.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/features/home/presentation/screens/home_screen.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_feeling_screen.dart';
import 'package:cozy_health/features/journal/presentation/screens/journal_screen.dart';
import 'package:cozy_health/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/insights_home_screen.dart';
import 'package:cozy_health/features/insights/presentation/widgets/insights_feed.dart';
import 'package:cozy_health/features/assistant/presentation/widgets/conversation_list_view.dart';
import 'package:cozy_health/features/assistant/models/chat.dart';
import 'package:cozy_health/features/crisis/presentation/screens/crisis_screens.dart';
import 'package:cozy_health/features/community/presentation/screens/community_hub_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/community_search_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/content_home_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/category_detail_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/saved_articles_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_selection_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_history_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/blocked_users_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final local = LocalDbService();

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    directory = await Directory.systemTemp.createTemp('cozy_empty_states_');
    Hive.init(directory.path);
    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(AppNotificationAdapter());
    Hive.registerAdapter(SavedArticleAdapter());
    Hive.registerAdapter(QuizAttemptAdapter());
    Hive.registerAdapter(SafetyPlanAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    await EncryptedHive.openBox<MoodEntry>(LocalDbService.moodBoxName);
    await EncryptedHive.openBox<JournalEntry>(LocalDbService.journalBoxName);
    await EncryptedHive.openBox<AppNotification>(
      LocalDbService.appNotificationBoxName,
    );
    await EncryptedHive.openBox<SavedArticle>(
      LocalDbService.savedArticleBoxName,
    );
    await EncryptedHive.openBox<QuizAttempt>(LocalDbService.quizAttemptBoxName);
    await EncryptedHive.openBox<SafetyPlan>(LocalDbService.safetyPlanBoxName);
    await EncryptedHive.openBox<UserProfile>(LocalDbService.userProfileBoxName);
  });
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await local.moodBox.clear();
    await local.journalBox.clear();
    await EncryptedHive.box<AppNotification>(
      LocalDbService.appNotificationBoxName,
    ).clear();
    await EncryptedHive.box<SavedArticle>(
      LocalDbService.savedArticleBoxName,
    ).clear();
    await EncryptedHive.box<QuizAttempt>(
      LocalDbService.quizAttemptBoxName,
    ).clear();
    await EncryptedHive.box<SafetyPlan>(
      LocalDbService.safetyPlanBoxName,
    ).clear();
  });
  tearDownAll(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  Future<GoRouter> mount(WidgetTester tester, Widget screen) async {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(path: '/test', builder: (_, _) => screen),
        for (final route in [
          AppRouter.moodFeeling,
          AppRouter.safetyPlan,
          AppRouter.contentHome,
          AppRouter.quizSelection,
          AppRouter.createPost,
        ])
          GoRoute(
            path: route,
            builder: (_, _) => Scaffold(body: Text('destination:$route')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    if (screen is HomeScreen) {
      // Home has an existing continuously pulsing hero when moods exist.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    } else {
      await tester.pumpAndSettle();
    }
    return router;
  }

  Future<void> tapCta(WidgetTester tester, String label, String route) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    expect(find.text('destination:$route'), findsOneWidget);
  }

  testWidgets('Home first check-in and affirmation fallback', (tester) async {
    await mount(tester, const HomeScreen());
    expect(find.text('How are you feeling today?'), findsOneWidget);
    expect(find.text('Your first check-in starts here.'), findsNothing);
    expect(find.text('Cozy Calendar'), findsOneWidget);
    expect(find.text('Journaling'), findsOneWidget);
    await tapCta(tester, 'Start your streak', AppRouter.moodFeeling);
  });

  testWidgets('Home partial data keeps trend invitation', (tester) async {
    final now = DateTime.now();
    await tester.runAsync(
      () => local.saveMoodEntry(
        MoodEntry(
          id: 'one',
          mood: 'calm',
          intensity: 5,
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );
    await mount(tester, const HomeScreen());
    expect(find.text('Your first check-in starts here.'), findsNothing);
    expect(find.text('Log 3 moods to see trends'), findsOneWidget);
  });

  testWidgets('Mood history loads then invites logging', (tester) async {
    await mount(tester, const MoodHistoryScreen());
    expect(find.text('Your moods will appear here.'), findsOneWidget);
    await tapCta(tester, 'Log a mood', AppRouter.moodFeeling);
  });

  testWidgets('Mood history empty state disappears when a mood arrives', (
    tester,
  ) async {
    await mount(tester, const MoodHistoryScreen());
    final now = DateTime.now();
    await tester.runAsync(
      () => local.saveMoodEntry(
        MoodEntry(
          id: 'new',
          mood: 'calm',
          intensity: 4,
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your moods will appear here.'), findsNothing);
    expect(find.byType(EmptyState), findsNothing);
  });

  testWidgets('Journal invitation opens editor', (tester) async {
    await mount(tester, const JournalScreen());
    expect(find.text('A private space for your thoughts.'), findsOneWidget);
    await tester.tap(find.text('Write your first entry'));
    await tester.pumpAndSettle();
    expect(find.byType(JournalEditorScreen), findsOneWidget);
  });

  testWidgets('Journal search includes query and clears it', (tester) async {
    await mount(tester, JournalSearchScreen(entries: const [], onOpen: (_) {}));
    await tester.enterText(find.byType(TextField), 'sleep');
    await tester.pumpAndSettle();
    expect(find.text("No entries match 'sleep'."), findsOneWidget);
    await tester.ensureVisible(find.text('Clear search'));
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.byType(EmptyState), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('Notifications empty has no CTA', (tester) async {
    await mount(tester, const NotificationsScreen());
    expect(
      find.text("No new notifications for now. Check back later"),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
  });

  for (final count in [0, 1, 2]) {
    testWidgets('Insights invites logging with $count moods', (tester) async {
      final now = DateTime.now();
      await tester.runAsync(() async {
        for (var i = 0; i < count; i++) {
          await local.saveMoodEntry(
            MoodEntry(
              id: '$i',
              mood: 'calm',
              intensity: 5,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      });
      await mount(tester, const InsightsHomeScreen());
      expect(find.text('Log a few moods to see patterns.'), findsOneWidget);
      await tapCta(tester, 'Log a mood', AppRouter.moodFeeling);
    });
  }

  testWidgets(
    'Insights status loading and failure do not show empty invitation',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InsightsStatus(loading: true, failed: false, empty: true),
        ),
      );
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(SkeletonLoader), findsOneWidget);
      await tester.pumpWidget(
        const MaterialApp(
          home: InsightsStatus(loading: false, failed: true, empty: true),
        ),
      );
      expect(find.byType(EmptyState), findsNothing);
    },
  );

  testWidgets('Insights invitation disappears when third mood arrives', (
    tester,
  ) async {
    await mount(tester, const InsightsHomeScreen());
    final now = DateTime.now();
    await tester.runAsync(() async {
      for (var i = 0; i < 3; i++) {
        await local.saveMoodEntry(
          MoodEntry(
            id: 'arriving-$i',
            mood: 'calm',
            intensity: 5,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Log a few moods to see patterns.'), findsNothing);
    expect(find.text('This week'), findsOneWidget);
  });

  testWidgets('Journal invitation disappears when entry arrives', (
    tester,
  ) async {
    await mount(tester, const JournalScreen());
    final now = DateTime.now();
    await tester.runAsync(
      () => local.saveJournalEntry(
        JournalEntry(
          id: 'entry',
          type: 'free',
          title: 'A quiet evening',
          body: 'Resting today.',
          wordCount: 2,
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A private space for your thoughts.'), findsNothing);
    expect(find.text('Resting today.'), findsOneWidget);
  });

  testWidgets('Journal explicit loading does not show invitation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: JournalScreen(viewState: JournalViewState.loading),
      ),
    );
    expect(find.byType(EmptyState), findsNothing);
  });

  testWidgets(
    'Journal toolbar retains filters and composer without legacy rows',
    (tester) async {
      final now = DateTime.now();
      await tester.runAsync(() async {
        for (final type in ['free', 'voice']) {
          await local.saveJournalEntry(
            JournalEntry(
              id: type,
              type: type,
              title: '$type entry',
              body: '$type notes',
              wordCount: 2,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      });
      await mount(tester, const JournalScreen());
      expect(find.text('free notes'), findsOneWidget);
      expect(find.text('🎤 Voice note'), findsOneWidget);
      expect(find.text("What's on your mind?"), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      await tester.tap(find.byTooltip('Filter journal entries'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<String>, 'Voice'),
      );
      await tester.pumpAndSettle();
      expect(find.text('free notes'), findsNothing);
      expect(find.text('🎤 Voice note'), findsOneWidget);
      await tester.tap(find.byTooltip('New journal entry'));
      await tester.pumpAndSettle();
      expect(find.text('Free write'), findsOneWidget);
    },
  );

  testWidgets('Home initial loading does not show invitation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(find.text('Your first check-in starts here.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Default content and quiz catalogs keep populated layout', (
    tester,
  ) async {
    await mount(tester, const ContentHomeScreen());
    expect(find.text('The Voice in Your Head'), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
    await mount(tester, const QuizSelectionScreen());
    expect(find.text('PHQ-9 Depression Screening'), findsOneWidget);
    expect(find.text('GAD-7 Anxiety Assessment'), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
  });

  testWidgets('Chat history CTA returns a new conversation', (tester) async {
    Conversation? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.push<Conversation>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ConversationHistoryScreen(conversations: []),
                  ),
                );
              },
              child: const Text('Open history'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open history'));
    await tester.pumpAndSettle();
    expect(find.text('Start your first conversation.'), findsOneWidget);
    expect(find.text('+ New conversation'), findsNothing);
    await tester.tap(find.text('Say hi'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.messages, isEmpty);
  });

  testWidgets('Professional directory CTA focuses search', (tester) async {
    await mount(tester, const ProfessionalHelpScreen());
    expect(find.text('Search for providers near you.'), findsOneWidget);
    await tester.ensureVisible(find.text('Search providers'));
    await tester.tap(find.text('Search providers'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
  });

  testWidgets('Missing safety plan invites creation', (tester) async {
    await mount(tester, const PersistedSafetyPlanViewScreen());
    expect(
      find.text("Create a safety plan that's just for you."),
      findsOneWidget,
    );
    await tapCta(tester, 'Create my plan', AppRouter.safetyPlan);
  });

  testWidgets('Community empty topic invites sharing', (tester) async {
    await mount(tester, const CommunityHubScreen());
    final sleepFilter = find.descendant(of: find.byType(ListView).first, matching: find.text('Sleep'));
    await tester.ensureVisible(sleepFilter);
    await tester.tap(sleepFilter);
    await tester.pumpAndSettle();
    expect(find.text('No posts yet. Be the first to share.'), findsOneWidget);
    await tapCta(tester, 'Create Post', AppRouter.createPost);
  });

  testWidgets('Community empty feed invites sharing', (tester) async {
    await mount(tester, const CommunityHubScreen(posts: []));
    expect(find.text('No posts yet. Be the first to share.'), findsOneWidget);
    await tapCta(tester, 'Create Post', AppRouter.createPost);
  });

  testWidgets('Notifications invitation disappears when notification arrives', (
    tester,
  ) async {
    await mount(tester, const NotificationsScreen());
    await tester.runAsync(
      () =>
          EncryptedHive.box<AppNotification>(
            LocalDbService.appNotificationBoxName,
          ).put(
            'notice',
            AppNotification(
              id: 'notice',
              title: 'A new reminder',
              body: 'Take a moment.',
              type: 'reminder',
              read: false,
              createdAt: DateTime.now(),
            ),
          ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text("No new notifications for now. Check back later"),
      findsNothing,
    );
    expect(find.text('A new reminder'), findsOneWidget);
  });

  testWidgets('Bookmarks invitation disappears when article arrives', (
    tester,
  ) async {
    await mount(tester, const SavedArticlesScreen());
    await tester.runAsync(
      () => EncryptedHive.box<SavedArticle>(LocalDbService.savedArticleBoxName)
          .put(
            'saved',
            SavedArticle(
              id: 'saved',
              articleId: 'article',
              title: 'A gentle read',
              excerpt: '',
              imageUrl: '',
              savedAt: DateTime.now(),
            ),
          ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save articles to read later.'), findsNothing);
    expect(find.text('A gentle read'), findsOneWidget);
  });

  testWidgets('Community search reports query and clears it', (tester) async {
    await mount(tester, const CommunitySearchScreen());
    await tester.enterText(find.byType(TextField), 'rest');
    await tester.pumpAndSettle();
    expect(find.text("No posts match 'rest'."), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Type to search public posts.'), findsOneWidget);
  });

  testWidgets('Content feed has an empty featured state', (tester) async {
    await mount(tester, const ContentHomeScreen(featuredArticles: []));
    expect(find.text('New articles coming soon.'), findsOneWidget);
  });

  testWidgets('Empty category uses same article invitation', (tester) async {
    await mount(
      tester,
      const CategoryDetailScreen(extra: {'id': 'mindfulness'}),
    );
    expect(find.text('New articles coming soon.'), findsOneWidget);
  });

  testWidgets('Bookmarks invites exploring articles', (tester) async {
    await mount(tester, const SavedArticlesScreen());
    expect(find.text('Save articles to read later.'), findsOneWidget);
    await tapCta(tester, 'Explore articles', AppRouter.contentHome);
  });

  testWidgets('Quiz list handles an empty catalog', (tester) async {
    await mount(tester, const QuizSelectionScreen(availableQuizIds: {}));
    expect(find.text('Assessments coming soon.'), findsOneWidget);
  });

  testWidgets('Quiz history invites exploring assessments', (tester) async {
    await mount(tester, const QuizHistoryScreen());
    expect(find.text('Your results will appear here.'), findsOneWidget);
    await tapCta(tester, 'Explore assessments', AppRouter.quizSelection);
  });

  testWidgets('Blocked users empty has no CTA', (tester) async {
    await mount(tester, const BlockedUsersScreen(blockedUsers: []));
    expect(find.text("You haven't blocked anyone."), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('EmptyState scrolls at large text sizes on small screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(
              height: 180,
              child: EmptyState(
                title: 'Your first check-in starts here.',
                subtitle: 'A little room for your feelings.',
                primaryCtaLabel: 'Log your mood',
                onPrimaryCta: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Log your mood'));
    expect(tester.takeException(), isNull);
  });
}
