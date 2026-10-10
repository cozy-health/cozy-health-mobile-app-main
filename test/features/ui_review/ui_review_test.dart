import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/data/placeholder_data.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/core/models/saved_article.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/features/home/presentation/screens/home_screen.dart';
import 'package:cozy_health/features/activity/presentation/screens/activity_screens.dart';
import 'package:cozy_health/features/community/presentation/screens/community_hub_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/post_detail_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/create_post_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/comments_screen.dart';
import 'package:cozy_health/features/journal/presentation/screens/journal_screen.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_feeling_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_selection_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_history_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/content_home_screen.dart';
import 'package:cozy_health/features/content/presentation/screens/article_detail_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/insights_home_screen.dart';
import 'package:cozy_health/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:cozy_health/features/notifications/presentation/screens/notification_detail_screen.dart';
import '../../support/local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await installLocalTestFonts();
    directory = await Directory.systemTemp.createTemp('cozy_ui_review_');
    Hive.init(directory.path);
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(AppNotificationAdapter());
    Hive.registerAdapter(SavedArticleAdapter());
    Hive.registerAdapter(QuizAttemptAdapter());
    await EncryptedHive.openBox<UserProfile>(LocalDbService.userProfileBoxName);
    await EncryptedHive.openBox<MoodEntry>(LocalDbService.moodBoxName);
    await EncryptedHive.openBox<JournalEntry>(LocalDbService.journalBoxName);
    await EncryptedHive.openBox<AppNotification>(
      LocalDbService.appNotificationBoxName,
    );
    await EncryptedHive.openBox<SavedArticle>(
      LocalDbService.savedArticleBoxName,
    );
    await EncryptedHive.openBox<QuizAttempt>(LocalDbService.quizAttemptBoxName);
    await LocalDbService().settingsBox();
  });
  setUp(() => DemoMode.instance.enabled = true);
  tearDown(() => DemoMode.instance.enabled = false);
  tearDownAll(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
    resetLocalTestFonts();
  });

  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    required bool dark,
    Size size = const Size(375, 667),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(path: '/test', builder: (_, _) => screen),
        for (final route in {
          AppRouter.moodFeeling,
          AppRouter.moodHistory,
          AppRouter.moodDetail,
          AppRouter.quizSelection,
          AppRouter.journal,
          AppRouter.insights,
          AppRouter.createPost,
          AppRouter.notifications,
          AppRouter.notificationDetail,
          AppRouter.communityHub,
          AppRouter.contentSearch,
        })
          GoRoute(
            path: route,
            builder: (_, state) =>
                Scaffold(body: Text('destination:${state.uri}')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.6)),
          child: child!,
        ),
        routerConfig: router,
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final screens = <String, Widget Function()>{
    'Home': () => const HomeScreen(),
    'Activity': () => const ActivityScreen(),
    'Community': () => const CommunityHubScreen(),
    'Journal': () => const JournalScreen(),
    'Mood Check-In': () => const MoodFeelingScreen(initialMood: 'calm'),
    'Quiz': () => const QuizSelectionScreen(),
    'Content': () => const ContentHomeScreen(),
    'Insights': () => const InsightsHomeScreen(),
    'Notifications': () => const NotificationsScreen(),
    'Post Detail': () => PostDetailScreen(post: PlaceholderData.posts().first),
    'Create Post': () => const CreatePostScreen(),
    'Comments': () => CommentsScreen(post: PlaceholderData.posts().first),
    'Content Detail': () =>
        ArticleDetailScreen(extra: PlaceholderData.articles().first),
    'Journal Detail': () =>
        JournalEntryDetailScreen(entry: PlaceholderData.journals().first),
    'Notification Detail': () => NotificationDetailScreen(
      notification: PlaceholderData.notifications().first,
    ),
  };
  for (final dark in [false, true]) {
    testWidgets('Quiz History headings have readable contrast, dark=$dark', (
      tester,
    ) async {
      final box = LocalDbService().quizAttemptBox;
      await tester.runAsync(
        () => box.put(
          'history-title-review',
          QuizAttempt(
            id: 'history-title-review',
            quizId: 'legacy',
            quizSlug: 'legacy',
            quizTitle: 'Previous attempt',
            answers: const [],
            score: 0,
            interpretation: '',
            isCrisisFlagged: false,
            completedAt: DateTime(2026, 10, 10),
          ),
        ),
      );
      addTearDown(
        () => tester.runAsync(() => box.delete('history-title-review')),
      );
      await mount(tester, const QuizHistoryScreen(), dark: dark);
      final theme = dark ? AppTheme.dark : AppTheme.light;
      for (final title in ['Quiz History', 'Past attempts']) {
        final text = tester.widget<Text>(find.text(title));
        final luminance = text.style!.color!.computeLuminance();
        final background = theme.scaffoldBackgroundColor.computeLuminance();
        final contrast = luminance > background
            ? (luminance + 0.05) / (background + 0.05)
            : (background + 0.05) / (luminance + 0.05);
        expect(contrast, greaterThanOrEqualTo(4.5), reason: title);
      }
      expect(tester.takeException(), isNull);
    });
    for (final item in screens.entries) {
      testWidgets(
        '${item.key} renders on a small phone with large text, dark=$dark',
        (tester) async {
          await mount(tester, item.value(), dark: dark);
          expect(tester.takeException(), isNull);
          expect(find.byType(Scrollable), findsWidgets);
        },
      );
      testWidgets('${item.key} renders in landscape, dark=$dark', (
        tester,
      ) async {
        await mount(
          tester,
          item.value(),
          dark: dark,
          size: const Size(667, 375),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Home chips scroll to Excited and carry the selected mood', (
    tester,
  ) async {
    await mount(tester, const HomeScreen(), dark: true);
    await tester.ensureVisible(find.text('Excited'));
    await tester.tap(find.text('Excited'));
    await tester.pumpAndSettle();
    expect(
      find.text('destination:${AppRouter.moodFeeling}?mood=excited'),
      findsOneWidget,
    );
  });
  testWidgets('Community header create menu stays accessible', (tester) async {
    await mount(tester, const CommunityHubScreen(), dark: true);
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Create post'), findsOneWidget);
    expect(find.text('Create new group'), findsOneWidget);
    await tester.tap(find.text('Create post'));
    await tester.pumpAndSettle();
    expect(find.text('destination:${AppRouter.createPost}'), findsOneWidget);
  });
  testWidgets(
    'Journal swipe delete can be undone without changing real records',
    (tester) async {
      final count = DemoMode.instance.journals.length;
      final entry = DemoMode.instance.journals.first;
      await mount(tester, const JournalScreen(), dark: true);
      await tester.ensureVisible(find.byKey(ValueKey(entry.id)));
      await tester.drag(find.byKey(ValueKey(entry.id)), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(DemoMode.instance.journals.length, count - 1);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(
        DemoMode.instance.journals.map((row) => row.id),
        contains(entry.id),
      );
    },
  );
  testWidgets('Post Detail like toggles and new comments join its thread', (
    tester,
  ) async {
    final post = PlaceholderData.posts().first;
    final likes = post['likes'] as int;
    await mount(tester, PostDetailScreen(post: post), dark: true);
    final like = find.byIcon(Icons.favorite_border).first;
    await tester.ensureVisible(like);
    await tester.tap(like);
    await tester.pump();
    expect(post['likes'], likes + 1);
    expect(post['isLiked'], true);
    await tester.enterText(find.byType(TextField), 'Thank you for sharing.');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();
    expect(post['comments'], greaterThan(0));
    expect(find.byType(TextField), findsOneWidget);
  });
}
