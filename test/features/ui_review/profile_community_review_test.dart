import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/cozy_colors.dart';
import 'package:cozy_health/core/widgets/bottom_navigation_bar.dart';
import 'package:cozy_health/features/crisis/presentation/widgets/crisis_fab.dart';
import 'package:cozy_health/features/settings/presentation/screens/profile_view_screen.dart';
import 'package:cozy_health/features/settings/data/achievements_repository.dart';
import 'package:cozy_health/features/settings/data/wellness_progress.dart';
import 'package:cozy_health/features/community/presentation/screens/community_hub_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/community_search_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/user_profile_screen.dart';
import 'package:cozy_health/features/community/presentation/widgets/post_card.dart';
import 'package:cozy_health/features/community/presentation/widgets/report_sheet.dart';
import 'package:cozy_health/features/community/presentation/widgets/visibility_sheet.dart';
import 'package:cozy_health/features/community/presentation/community_local_state.dart';
import '../../support/local_fonts.dart';
import '../../../tool/design_previews/popup_proposals.dart';

const output = 'docs/design/profile-community-implemented';
const capture = ValueKey('profile-community-review');
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  final now = DateTime.now();
  final moods = [
    for (var i = 0; i < 3; i++)
      MoodEntry(
        id: 'sample-$i',
        mood: 'good',
        intensity: 6,
        createdAt: now.subtract(Duration(days: i)),
        updatedAt: now.subtract(Duration(days: i)),
      ),
  ];
  final profile = UserProfile(
    id: 'sample-user',
    name: 'Sam Taylor',
    email: 'sample@example.invalid',
    username: 'samtaylor',
    avatarUrl: 'asset:open-peeps-01',
    bio: 'Learning to make room for small, steady steps.',
    updatedAt: now,
  );
  final posts = <Map<String, dynamic>>[
    {
      'id': 'sample-post',
      'authorId': 'sample-member',
      'username': 'Sam Taylor',
      'content':
          'I took a short walk before work today. It helped me slow down and notice how I was feeling. Small steps count.',
      'topic': 'Self-care',
      'timeAgo': now.subtract(const Duration(hours: 2)).toIso8601String(),
      'likes': 12,
      'comments': 3,
      'isLiked': false,
    },
    {
      'id': 'sample-anonymous',
      'isAnonymous': true,
      'username': 'Hidden identity',
      'content': 'Making time for a quiet evening. What helps you unwind?',
      'topic': 'Sleep',
      'timeAgo': now.subtract(const Duration(hours: 3)).toIso8601String(),
      'likes': 4,
      'comments': 2,
    },
  ];
  final progress = WellnessProgress(moods: moods, journals: const [], now: now);
  final snapshot = AchievementSnapshot(
    progress: progress,
    awards: progress.derivedAwards,
    localOnly: false,
    remoteUnavailable: false,
  );
  setUpAll(() async {
    await installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    );
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    cache = await Directory.systemTemp.createTemp('cozy_profile_review_');
    Hive.init(cache.path);
    await LocalDbService().settingsBox();
    await LocalDbService().preferencesBox();
    DemoMode.instance.enabled = true;
    CommunityLocalState.instance.groups
      ..clear()
      ..addAll([
        CommunityGroup(
          id: 'sample-anxiety',
          name: 'Anxiety support',
          topic: 'Anxiety',
          description: 'Share small steps and coping strategies with others.',
          members: 128,
        ),
        CommunityGroup(
          id: 'sample-rest',
          name: 'Rest and reset',
          topic: 'Sleep',
          description: 'Make room for rest, one evening at a time.',
          members: 86,
          joined: true,
        ),
        CommunityGroup(
          id: 'sample-kindness',
          name: 'Everyday kindness',
          topic: 'Self-care',
          description:
              'A gentle space to share what helps you care for yourself.',
          members: 204,
        ),
      ]);
    await Directory(output).create(recursive: true);
  });
  tearDownAll(() async {
    DemoMode.instance.enabled = false;
    await Hive.close();
    resetLocalTestFonts();
    await cache.delete(recursive: true);
  });
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final box = await LocalDbService().settingsBox();
    var closed = false;
    box.close().then((_) => closed = true);
    for (var i = 0; i < 100 && !closed; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(closed, true);
    await tester.runAsync(() => LocalDbService().settingsBox());
  }

  Future<void> save(WidgetTester tester, String name) async {
    await settle(tester);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(capture),
    );
    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(boundary);
    await tester.pump();
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      img.dispose();
    });
    debugDisableShadows = previousShadows;
    repaint(boundary);
    await tester.pump();
  }

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    int accent = 0,
    bool dark = false,
    bool contrast = false,
    bool large = false,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(large ? 640 : 750, 1624);
    var theme = AppTheme.withAccent(
      dark ? AppTheme.dark : AppTheme.light,
      AppColors.brandPalette[accent],
    );
    if (contrast) theme = AppTheme.highContrast(theme);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(large ? 2 : 1),
            highContrast: contrast,
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const SizedBox.shrink(),
        initialRoute: '/review',
        routes: {
          '/review': (context) => RepaintBoundary(
            key: capture,
            child: child is CommunityHubScreen
                ? Builder(
                    builder: (context) {
                      final w = context.cozyColors.wellness;
                      return Scaffold(
                        bottomNavigationBar: CustomBottomNavigationBar(
                          currentIndex: 3,
                          onTap: (_) {},
                        ),
                        body: Stack(
                          fit: StackFit.expand,
                          children: [
                            child,
                            Positioned(
                              right: w.floatingInset,
                              bottom:
                                  w.floatingInset +
                                  w.floatingSize +
                                  w.floatingGap,
                              child: const CrisisFab(),
                            ),
                            Positioned(
                              right: w.floatingInset,
                              bottom: w.floatingInset,
                              child: FloatingActionButton(
                                shape: const CircleBorder(),
                                onPressed: () {},
                                tooltip: 'Open quick actions',
                                child: const Icon(Icons.add_rounded),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : child,
          ),
        },
      ),
    );
    await settle(tester);
  }

  Widget screen(String name) => switch (name) {
    'profile' => ProfileViewScreen(
      profileStream: Stream.value(profile),
      moodStream: Stream.value(moods),
    ),
    'achievements' => AchievementsScreen(load: () async => snapshot),
    'member' => UserProfileScreen(
      extra: const {'username': 'Sam Taylor', 'authorId': 'sample-member'},
      loadPosts: (_) async => [
        {
          'id': 'public-post',
          'author': {'id': 'sample-member', 'name': 'Sam Taylor'},
          'body': 'Taking small steps, one day at a time.',
          'mood': 'Self-care',
          'like_count': 8,
          'comment_count': 2,
          'created_at': now.toIso8601String(),
        },
        {
          'id': 'private-identity',
          'is_anonymous': true,
          'body': 'Must never appear on this public profile',
        },
      ],
    ),
    _ => CommunityHubScreen(posts: posts),
  };
  for (final name in [
    'profile',
    'community',
    'groups',
    'member',
    'achievements',
  ]) {
    for (final dark in [false, true]) {
      for (final accent in [0, 1, 2, 3]) {
        testWidgets('implemented $name dark=$dark accent=$accent', (
          tester,
        ) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await pump(
            tester,
            screen(name),
            accent: accent,
            dark: dark,
            contrast: accent == 3,
          );
          if (name == 'groups') {
            await tester.tap(find.byKey(const ValueKey('community-tab-1')));
            await settle(tester);
          }
          expect(tester.takeException(), isNull);
          if (name == 'community') {
            final tag = tester.widget<Text>(find.text('Self-care').last);
            final context = tester.element(find.text('Self-care').last);
            expect(
              context.cozyColors.recording.contrastRatio(
                tag.style!.color!,
                Theme.of(context).colorScheme.surface,
              ),
              greaterThanOrEqualTo(4.5),
            );
          }
          if (name == 'member') {
            expect(
              find.text('Must never appear on this public profile'),
              findsNothing,
            );
          }
          if (name == 'profile') expect(find.text('3 days'), findsOneWidget);
          final file =
              '$name-${dark ? 'dark' : 'light'}-${['blue', 'green', 'orange', 'yellow'][accent]}';
          await save(tester, file);
          if (accent == 0) {
            final scrollable = tester.state<ScrollableState>(
              find.byType(Scrollable).first,
            );
            final height = 812 + scrollable.position.maxScrollExtent;
            tester.view.physicalSize = Size(750, height * 2);
            await settle(tester);
            expect(tester.takeException(), isNull);
            await save(tester, '$file-full');
          }
          await unmount(tester);
        });
      }
    }
    testWidgets('$name 200 percent high contrast narrow', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(
        tester,
        screen(name),
        accent: 3,
        dark: true,
        contrast: true,
        large: true,
      );
      if (name == 'groups') {
        await tester.tap(find.byKey(const ValueKey('community-tab-1')));
        await settle(tester);
      }
      expect(tester.takeException(), isNull);
      await save(tester, '$name-large-contrast');
      await unmount(tester);
    });
  }
  for (final kind in [
    'options',
    'report',
    'visibility',
    'provider',
    'record',
    'confirm',
    'avatar',
    'voice',
  ]) {
    for (final dark in [false, true]) {
      testWidgets('popup proposal $kind dark=$dark', (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pump(
          tester,
          PopupProposal(kind: kind),
          dark: dark,
          accent: dark ? 3 : 0,
        );
        expect(tester.takeException(), isNull);
        await save(tester, 'popup-$kind-${dark ? 'dark' : 'light'}');
        await unmount(tester);
      });
    }
    testWidgets('popup $kind narrow large contrast', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(
        tester,
        PopupProposal(kind: kind),
        dark: true,
        accent: 3,
        contrast: true,
        large: true,
      );
      expect(tester.takeException(), isNull);
      await save(tester, 'popup-$kind-large-contrast');
      await unmount(tester);
    });
  }
  testWidgets('current report and visibility scroll at large text', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(
      tester,
      Scaffold(body: ReportSheet(onSubmit: () {})),
      dark: true,
      contrast: true,
      large: true,
    );
    expect(tester.takeException(), isNull);
    await save(tester, 'current-report-large-contrast');
    await unmount(tester);
    await pump(
      tester,
      Scaffold(
        body: VisibilitySheet(
          currentVisibility: PostVisibility.anonymous,
          onSelect: (_) {},
        ),
      ),
      dark: true,
      contrast: true,
      large: true,
    );
    expect(tester.takeException(), isNull);
    await save(tester, 'current-visibility-large-contrast');
    await unmount(tester);
  });
  testWidgets(
    'anonymous author is static and options have an explicit target',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opens = 0, options = 0;
      await pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: PostCard(
              post: posts[1],
              onTap: () {},
              onAvatarTap: () => opens++,
              onLongPress: () => options++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Anonymous'));
      expect(opens, 0);
      expect(find.text('Hidden identity'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Post options'));
      expect(options, 1);
      await unmount(tester);
    },
  );
  testWidgets(
    'profile honors hidden stats and username without inventing a bio',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hidden = UserProfile(
        id: 'hidden',
        name: 'Your name',
        email: 'sample@example.invalid',
        username: 'privatehandle',
        showUsername: false,
        showStats: false,
        updatedAt: now,
      );
      await pump(
        tester,
        ProfileViewScreen(
          profileStream: Stream.value(hidden),
          moodStream: Stream.value(moods),
        ),
      );
      expect(find.text('@privatehandle'), findsNothing);
      expect(find.text('Current check-in streak'), findsNothing);
      expect(find.textContaining('Trying to be kinder'), findsNothing);
      expect(find.text('Your name'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );
  testWidgets('search filters real loaded post content and group metadata', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DemoMode.instance.posts
      ..clear()
      ..addAll(posts);
    await pump(tester, const CommunitySearchScreen());
    await tester.enterText(find.byType(TextField), 'short walk');
    await settle(tester);
    expect(find.text(posts.first['content'] as String), findsOneWidget);
    expect(find.text(posts.last['content'] as String), findsNothing);
    await tester.enterText(find.byType(TextField), 'rest');
    await tester.tap(find.byKey(const ValueKey('search-tab-1')));
    await settle(tester);
    expect(find.text('Rest and reset'), findsOneWidget);
    expect(find.text('Anxiety support'), findsNothing);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
