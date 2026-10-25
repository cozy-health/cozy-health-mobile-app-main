import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/data/placeholder_data.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/widgets/mood_artwork.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/core/models/saved_article.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';
import 'package:cozy_health/core/models/chat_message.dart';
import 'package:cozy_health/core/models/chat_conversation.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/widgets/mood_category_grid.dart';
import 'package:cozy_health/core/theme/cozy_colors.dart';
import 'package:cozy_health/features/home/presentation/widgets/home_design_widgets.dart';
import 'package:cozy_health/features/mood_check_in/presentation/mood_recording_controller.dart';
import '../../support/mood_recording_fakes.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/features/home/presentation/screens/home_screen.dart';
import 'package:cozy_health/features/home/presentation/widgets/cozy_calendar.dart';
import 'package:cozy_health/features/home/presentation/screens/main_screen.dart';
import 'package:cozy_health/core/widgets/bottom_navigation_bar.dart';
import 'package:cozy_health/features/crisis/presentation/widgets/crisis_fab.dart';
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
import 'package:cozy_health/features/notifications/presentation/widgets/notification_permission_sheet.dart';
import '../../support/local_fonts.dart';
import '../../support/surface_capture.dart';
import '../../support/mood_review_capture.dart';
import 'package:cozy_health/features/settings/presentation/screens/settings_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_hub_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    );
    // The journal intentionally uses Georgia for its body. Load the installed
    // face for Windows review captures rather than rendering test-font blocks.
    if (Platform.isWindows) {
      final font = File('${Platform.environment['WINDIR']}/Fonts/georgia.ttf');
      if (font.existsSync()) {
        await (FontLoader('Georgia')..addFont(
              Future.value(ByteData.sublistView(font.readAsBytesSync())),
            ))
            .load();
      }
    }
    directory = await Directory.systemTemp.createTemp('cozy_ui_review_');
    Hive.init(directory.path);
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(AppNotificationAdapter());
    Hive.registerAdapter(SavedArticleAdapter());
    Hive.registerAdapter(QuizAttemptAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(ChatConversationAdapter());
    await EncryptedHive.openBox<ChatMessage>(LocalDbService.chatMessageBoxName);
    await EncryptedHive.openBox<ChatConversation>(
      LocalDbService.chatConversationBoxName,
    );
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
    await LocalDbService().preferencesBox();
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
    double textScale = 1.6,
    bool contrast = false,
    int accent = 0,
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
          AppRouter.crisisHub,
          AppRouter.crisisContact,
          AppRouter.breathing,
          AppRouter.grounding,
        })
          GoRoute(
            path: route,
            builder: (_, state) =>
                Scaffold(body: Text('destination:${state.uri}')),
          ),
      ],
    );
    addTearDown(router.dispose);
    var theme = AppTheme.withAccent(
      dark ? AppTheme.dark : AppTheme.light,
      AppColors.brandPalette[accent],
    );
    if (contrast) theme = AppTheme.highContrast(theme);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            highContrast: contrast,
            boldText: contrast,
            disableAnimations: true,
          ),
          child: RepaintBoundary(key: surfaceCaptureKey, child: child!),
        ),
        routerConfig: router,
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await captureSurface(
      tester,
      '${screen.runtimeType}_${dark ? 'dark' : 'light'}_${size.width.toInt()}x${size.height.toInt()}',
    );
  }

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'mood artwork across saved surfaces dark=$dark scale=$scale',
        (tester) async {
          final originalMoods = List<MoodEntry>.of(DemoMode.instance.moods);
          addTearDown(() {
            DemoMode.instance.moods
              ..clear()
              ..addAll(originalMoods);
          });
          final date = DateTime(2026, 10, 22, 12);
          final entries = [
            MoodEntry(
              id: 'artwork-current',
              mood: 'angry',
              expressionSlug: 'angry-resentful',
              intensity: 7,
              triggers: ['Deadlines'],
              createdAt: date,
              updatedAt: date,
            ),
            MoodEntry(
              id: 'artwork-legacy',
              mood: 'calm',
              intensity: 5,
              createdAt: date,
              updatedAt: date,
            ),
          ];
          DemoMode.instance.moods
            ..clear()
            ..addAll(entries);
          final journal = JournalEntry(
            id: 'artwork-journal',
            type: 'free',
            body: 'I took a quiet moment after a busy day.',
            linkedMoodEntryId: entries.first.id,
            wordCount: 10,
            createdAt: date,
            updatedAt: date,
          );
          final surfaces = <String, Widget>{
            'history': const MoodHistoryScreen(),
            'detail': MoodDetailViewScreen(entry: entries.first),
            'legacy-detail': MoodDetailViewScreen(entry: entries.last),
            'calendar': Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: CozyCalendar(
                    entries: entries,
                    recentEntries: entries,
                    streak: 1,
                    weeklyCount: 2,
                    weeklyIntensityTotal: 12,
                    hasMoodToday: true,
                    onStreak: () {},
                    now: date,
                  ),
                ),
              ),
            ),
            'journal': JournalEntryDetailScreen(entry: journal),
            'home-insights': const InsightsScreen(),
          };
          for (final surface in surfaces.entries) {
            await mount(
              tester,
              surface.value,
              dark: dark,
              size: Size(scale == 1 ? 375 : 320, 812),
              textScale: scale,
            );
            if (surface.key == 'home-insights') {
              await tester.ensureVisible(find.text('Most common'));
            }
            await settleMoodReviewImages(tester, captureKey: surfaceCaptureKey);
            final artwork = tester
                .widgetList<MoodArtwork>(find.byType(MoodArtwork))
                .toList();
            final paths = tester
                .widgetList<Image>(find.byType(Image))
                .map((image) => (image.image as AssetImage).assetName)
                .toList();
            if (surface.key == 'legacy-detail') {
              expect(paths, isEmpty);
              expect(find.text('Calm'), findsOneWidget);
            } else {
              expect(artwork, isNotEmpty);
              expect(
                paths,
                contains(
                  MoodArtwork.assetFor(
                    surface.key == 'home-insights' ? 'good' : 'angry',
                  ),
                ),
              );
            }
            if (surface.key == 'history' || surface.key == 'calendar') {
              expect(paths, hasLength(1));
              expect(find.text('Calm'), findsOneWidget);
              expect(find.text('Resentful'), findsOneWidget);
            }
            if (surface.key == 'journal') {
              expect(find.text('Resentful | Intensity 7/10'), findsOneWidget);
            }
            if (scale == 1) {
              await captureMoodReview(
                tester,
                'artwork-${dark ? 'dark' : 'light'}-${surface.key}',
                captureKey: surfaceCaptureKey,
              );
            }
            expect(tester.takeException(), isNull, reason: surface.key);
            await tester.pumpWidget(const SizedBox.shrink());
          }
        },
      );
    }
  }

  for (final size in [
    const Size(320, 568),
    const Size(667, 375),
    const Size(430, 932),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('Main controls overlay full-height tabs: $size dark=$dark', (
        tester,
      ) async {
        final settings = await LocalDbService().settingsBox();
        await tester.runAsync(() => settings.put('has_seen_tour', true));
        await mount(tester, const MainScreen(), dark: dark, size: size);
        final nav = tester.widget<CustomBottomNavigationBar>(
          find.byType(CustomBottomNavigationBar),
        );
        for (final index in [0, 1, 2, 3, 4]) {
          nav.onTap(index);
          await tester.pump(const Duration(milliseconds: 500));
          final buttons = find.byType(FloatingActionButton);
          if (index == 2) {
            expect(find.byType(ProviderHubScreen), findsOneWidget);
            expect(
              buttons,
              findsNothing,
              reason: 'Provider composer must remain clear of overlays',
            );
            expect(
              find.byKey(const ValueKey('quick-actions-control')),
              findsNothing,
            );
            final page = tester.getRect(
              find.byKey(const ValueKey('main-tab-content')),
            );
            final navigation = tester.getRect(
              find.byType(CustomBottomNavigationBar),
            );
            expect(page.bottom, closeTo(navigation.top, 0.01));
            expect(tester.takeException(), isNull, reason: 'Provider tab');
            continue;
          }
          expect(buttons, findsOneWidget);
          expect(
            find.byKey(const ValueKey('quick-actions-control')),
            findsOneWidget,
          );
          final crisis = tester.getRect(find.byType(CrisisFab));
          final quick = tester.getRect(
            find.byKey(const ValueKey('quick-actions-control')),
          );
          final page = tester.getRect(
            find.byKey(const ValueKey('main-tab-content')),
          );
          final navigation = tester.getRect(
            find.byType(CustomBottomNavigationBar),
          );
          expect(crisis.size, const Size(56, 56));
          expect(quick.height, greaterThanOrEqualTo(48));
          expect(find.text('Actions').hitTestable(), findsOneWidget);
          expect(
            quick.contains(tester.getRect(find.text('Actions')).topLeft),
            isTrue,
          );
          expect(
            quick.contains(tester.getRect(find.text('Actions')).bottomRight),
            isTrue,
          );
          expect(quick.top - crisis.bottom, 16);
          expect(quick.width, greaterThan(quick.height));
          expect(page.contains(crisis.center), isTrue);
          expect(page.contains(quick.center), isTrue);
          expect(crisis.overlaps(quick), isFalse);
          expect(crisis.right, quick.right);
          expect(crisis.bottom, lessThan(quick.top));
          // Overlay controls must reserve no panel or dock in the page layout.
          expect(page.bottom, closeTo(navigation.top, 0.01));
          expect(quick.bottom, lessThan(navigation.top));
          expect(tester.takeException(), isNull, reason: 'Tab $index');
        }
        await tester.tap(find.byKey(const ValueKey('quick-actions-control')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('What would you like to do?'), findsOneWidget);
        await tester.ensureVisible(find.text('Open your journal'));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text('Open your journal'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('destination:${AppRouter.journal}'), findsOneWidget);
        expect(tester.takeException(), isNull);
        GoRouter.of(
          tester.element(find.text('destination:${AppRouter.journal}')),
        ).pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.longPress(
          find.byKey(const ValueKey('quick-actions-control')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.text('destination:${AppRouter.crisisContact}'),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('Crisis tap and long press restore support and calm routes', (
    tester,
  ) async {
    await mount(
      tester,
      const Scaffold(body: Center(child: CrisisFab())),
      dark: false,
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('destination:${AppRouter.crisisContact}'), findsOneWidget);
    GoRouter.of(
      tester.element(find.text('destination:${AppRouter.crisisContact}')),
    ).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.longPress(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('I need a moment.'), findsOneWidget);
    await tester.tap(find.text('Ground'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('destination:${AppRouter.grounding}'), findsOneWidget);
    expect(find.text('I need a moment.'), findsNothing);
  });

  final screens = <String, Widget Function()>{
    'Settings': () => const SettingsScreen(),
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
    testWidgets('Reminder permission choices remain usable, dark=$dark', (
      tester,
    ) async {
      await mount(
        tester,
        const Scaffold(body: NotificationPermissionSheet()),
        dark: dark,
        size: const Size(375, 812),
        textScale: 1,
      );
      await captureSurface(
        tester,
        'reminder_permission_${dark ? 'dark' : 'light'}',
      );
      final choice = find.widgetWithText(CheckboxListTile, 'Affirmations');
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(choice).value, isTrue);
      expect(tester.takeException(), isNull);
    });
    testWidgets('Community groups have a separate readable view, dark=$dark', (
      tester,
    ) async {
      await mount(tester, const CommunityHubScreen(), dark: dark, textScale: 1);
      await tester.tap(find.text('Groups'));
      await tester.pumpAndSettle();
      expect(find.text('Discover groups'), findsOneWidget);
      expect(find.text('Latest posts'), findsNothing);
      expect(find.text('Create a post'), findsNothing);
      expect(find.text('Create new group'), findsNothing);
      await captureSurface(
        tester,
        'community_groups_${dark ? 'dark' : 'light'}',
      );
      await tester.tap(find.text('Posts'));
      await tester.pumpAndSettle();
      expect(find.text('Latest posts'), findsOneWidget);
      expect(find.text('Create a post'), findsOneWidget);
      expect(find.text('Discover groups'), findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets('Home cards remain defined after scrolling, dark=$dark', (
      tester,
    ) async {
      await mount(
        tester,
        const HomeScreen(),
        dark: dark,
        size: const Size(390, 844),
      );
      await tester.ensureVisible(find.text('Your journal'));
      await tester.pump(const Duration(milliseconds: 300));
      final cards = find.descendant(
        of: find.byType(HomeFeatureCards),
        matching: find.byType(HomeDesignCard),
      );
      expect(cards, findsNWidgets(2));
      for (final element in cards.evaluate()) {
        final card = find.byWidget(element.widget);
        final container = tester.widget<Container>(
          find.descendant(of: card, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.border, isNotNull);
        expect(decoration.color, Theme.of(element).colorScheme.surface);
        expect(decoration.borderRadius, isNotNull);
      }
      await tester.ensureVisible(find.text('Well-being check'));
      expect(find.text('Start journaling →'), findsOneWidget);
      expect(find.text('Take a quiz →'), findsOneWidget);
      await captureSurface(
        tester,
        'home_${dark ? 'dark' : 'light'}_lower_cards',
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'Settings group borders survive child rows and scrolling, dark=$dark',
      (tester) async {
        await mount(
          tester,
          const SettingsScreen(),
          dark: dark,
          size: const Size(390, 844),
        );
        final theme = dark ? AppTheme.dark : AppTheme.light;
        for (final label in [
          'Next of kin',
          'Digital Wellbeing',
          'Change Password',
          'Connected Apps',
          'Cozy Challenges',
          'Delete Account',
        ]) {
          final row = find.text(label);
          await tester.ensureVisible(row);
          await tester.pump(const Duration(milliseconds: 300));
          final materials = tester
              .widgetList<Material>(
                find.ancestor(of: row, matching: find.byType(Material)),
              )
              .toList();
          expect(materials.first.color, Colors.transparent);
          final group = materials.firstWhere(
            (m) => m.shape is RoundedRectangleBorder,
          );
          expect(group.clipBehavior, Clip.antiAlias);
          expect(group.borderOnForeground, isTrue);
          expect(
            (group.shape! as RoundedRectangleBorder).side.color,
            theme.colorScheme.outline,
          );
          await captureSurface(
            tester,
            'settings_${dark ? 'dark' : 'light'}_$label',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
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
      for (final title in ['Assessment History', 'Past attempts']) {
        final text = tester.widget<Text>(find.text(title));
        final style = DefaultTextStyle.of(
          tester.element(find.text(title)),
        ).style.merge(text.style);
        final luminance = style.color!.computeLuminance();
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

  for (final dark in [false, true]) {
    for (var accent = 0; accent < 4; accent++) {
      for (final contrast in [false, true]) {
        final name =
            '${dark ? 'dark' : 'light'}-${['blue', 'green', 'orange', 'yellow'][accent]}-${contrast ? 'contrast' : 'standard'}';
        testWidgets('approved Home and Feeling design $name', (tester) async {
          final now = DateTime.now();
          final original = List<MoodEntry>.of(DemoMode.instance.moods);
          addTearDown(() {
            DemoMode.instance.moods
              ..clear()
              ..addAll(original);
          });
          DemoMode.instance.moods
            ..clear()
            ..addAll([
              for (var i = 0; i < 7; i++)
                if (i != 3)
                  MoodEntry(
                    id: 'design-$i',
                    mood: MoodCategoryGrid.moods[i % 6],
                    intensity: 6,
                    createdAt: DateTime(now.year, now.month, now.day - i, 12),
                    updatedAt: now,
                  ),
            ]);
          await tester.runAsync(() async {
            await LocalDbService().userProfileBox.put(
              'design-review',
              UserProfile(
                id: 'design-review',
                name: 'Amara Okafor',
                email: 'preview@example.invalid',
                updatedAt: now,
              ),
            );
          });
          addTearDown(() async {
            await LocalDbService().userProfileBox.delete('design-review');
          });
          for (final height in [812.0, 1900.0]) {
            await mount(
              tester,
              const MainScreen(),
              dark: dark,
              accent: accent,
              contrast: contrast,
              size: Size(375, height),
              textScale: 1,
            );
            expect(find.byType(MoodCategoryGrid), findsOneWidget);
            expect(find.text('How are you feeling today?'), findsOneWidget);
            expect(find.text('Your check-in rhythm'), findsOneWidget);
            expect(find.text('A little more you-time'), findsOneWidget);
            final homeContext = tester.element(find.byType(MoodCategoryGrid));
            final expectedFill = homeContext.cozyColors.wellness.accentPanel(
              Theme.of(homeContext).colorScheme,
            );
            for (final heading in [
              'How are you feeling today?',
              'Take a breathing break',
            ]) {
              final card = tester.widget<HomeDesignCard>(
                find
                    .ancestor(
                      of: find.text(heading),
                      matching: find.byType(HomeDesignCard),
                    )
                    .first,
              );
              expect(card.color, expectedFill);
            }
            expect(tester.takeException(), isNull);
            await captureMoodReview(
              tester,
              'home-balance-review-home-$name-${height == 812 ? 'viewport' : 'full'}',
              captureKey: surfaceCaptureKey,
            );
            await tester.pumpWidget(const SizedBox.shrink());
          }
          final flow = MoodRecordingController(
            initialMood: 'angry',
            drafts: MemoryMoodDrafts(),
            repository: MemoryMoodRepository(),
            wellness: MemoryMoodCatalog(),
            accountScope: () => 'design',
            accountChanges: const Stream.empty(),
          );
          addTearDown(flow.dispose);
          await mount(
            tester,
            MoodFeelingScreen(controller: flow, initialMood: 'angry'),
            dark: dark,
            accent: accent,
            contrast: contrast,
            size: const Size(375, 812),
            textScale: 1,
          );
          await tester.tap(
            find.byKey(
              const ValueKey('recording-hit-expressions-angry-resentful'),
            ),
          );
          await tester.pumpAndSettle();
          expect(flow.state.expression, 'angry-resentful');
          expect(find.text('12 feelings'), findsOneWidget);
          expect(
            tester
                .widgetList<Image>(find.byType(Image))
                .every((i) => i.color == null),
            isTrue,
          );
          await captureMoodReview(
            tester,
            'home-balance-review-feeling-$name',
            captureKey: surfaceCaptureKey,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
    testWidgets('approved Home and Feeling large text dark=$dark', (
      tester,
    ) async {
      await tester.runAsync(
        () => LocalDbService().userProfileBox.put(
          'long-design-name',
          UserProfile(
            id: 'long-design-name',
            name: 'Oluwafunmilayomorenikeji Okafor',
            email: 'preview@example.invalid',
            updatedAt: DateTime.now(),
          ),
        ),
      );
      addTearDown(
        () => LocalDbService().userProfileBox.delete('long-design-name'),
      );
      await mount(
        tester,
        const MainScreen(),
        dark: dark,
        contrast: true,
        accent: 3,
        size: const Size(320, 812),
        textScale: 2,
      );
      await captureMoodReview(
        tester,
        'home-balance-review-home-large-${dark ? 'dark' : 'light'}-top',
        captureKey: surfaceCaptureKey,
      );
      var captureIndex = 0;
      for (final label in [
        'Happy',
        'Your check-in rhythm',
        'Take a quiz →',
        'Small steps. Your pace. Your cozy space.',
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await captureMoodReview(
          tester,
          'home-balance-review-home-large-${dark ? 'dark' : 'light'}-${['moods', 'middle', 'features', 'bottom'][captureIndex++]}',
          captureKey: surfaceCaptureKey,
        );
      }
      await captureMoodReview(
        tester,
        'home-balance-review-home-large-${dark ? 'dark' : 'light'}',
        captureKey: surfaceCaptureKey,
      );
      final homeScroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(HomeScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      homeScroll.position.jumpTo(homeScroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(
        tester
            .getRect(find.text('Small steps. Your pace. Your cozy space.'))
            .bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(CrisisFab)).top),
      );
      await captureMoodReview(
        tester,
        [
          'home-balance-review-footer-clearance',
          dark ? 'dark' : 'light',
        ].join('-'),
        captureKey: surfaceCaptureKey,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      final flow = MoodRecordingController(
        initialMood: 'angry',
        drafts: MemoryMoodDrafts(),
        repository: MemoryMoodRepository(),
        wellness: MemoryMoodCatalog(),
        accountScope: () => 'design',
        accountChanges: const Stream.empty(),
      );
      addTearDown(flow.dispose);
      await mount(
        tester,
        MoodFeelingScreen(controller: flow),
        dark: dark,
        contrast: true,
        accent: 3,
        size: const Size(320, 812),
        textScale: 2,
      );
      await captureMoodReview(
        tester,
        'home-balance-review-feeling-large-${dark ? 'dark' : 'light'}-top',
        captureKey: surfaceCaptureKey,
      );
      await tester.ensureVisible(
        find.byKey(
          const ValueKey('recording-hit-expressions-angry-aggressive'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('recording-hit-expressions-angry-aggressive'),
        ),
      );
      await tester.pumpAndSettle();
      expect(flow.state.expression, 'angry-aggressive');
      final selectedRect = tester.getRect(
        find.byKey(
          const ValueKey('recording-hit-expressions-angry-aggressive'),
        ),
      );
      final footerRect = tester.getRect(
        find.byKey(const ValueKey('feeling-selection-summary')),
      );
      expect(selectedRect.bottom, lessThanOrEqualTo(footerRect.top));
      await captureMoodReview(
        tester,
        'home-balance-review-feeling-large-${dark ? 'dark' : 'light'}',
        captureKey: surfaceCaptureKey,
      );
      expect(tester.takeException(), isNull);
      // Detach live profile/preferences consumers before closing the fixture DB.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('capture production Home with the reference mood selector', (
    tester,
  ) async {
    await mount(
      tester,
      const HomeScreen(),
      dark: false,
      size: const Size(375, 812),
      textScale: 1,
    );
    // A single-screen run must await decoding instead of relying on image
    // caches warmed by earlier UI tests.
    final imageProviders = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .toList();
    final screenContext = tester.element(find.byType(HomeScreen));
    await tester.runAsync(
      () => Future.wait([
        for (final provider in imageProviders)
          precacheImage(provider, screenContext),
      ]),
    );
    await captureMoodReview(
      tester,
      'home-screen',
      captureKey: surfaceCaptureKey,
    );
  });

  testWidgets('Home chips scroll to Happy and carry the selected mood', (
    tester,
  ) async {
    await mount(tester, const HomeScreen(), dark: true);
    await tester.ensureVisible(find.text('Happy'));
    await tester.tap(find.text('Happy'));
    await tester.pumpAndSettle();
    expect(
      find.text('destination:${AppRouter.moodFeeling}?mood=happy'),
      findsOneWidget,
    );
  });
  testWidgets('Community header create menu stays accessible', (tester) async {
    await mount(tester, const CommunityHubScreen(), dark: true);
    expect(find.text('Create new group'), findsNothing);
    await tester.ensureVisible(find.text('Create a post'));
    await tester.tap(find.text('Create a post'));
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
