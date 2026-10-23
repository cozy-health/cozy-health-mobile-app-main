import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/network_status.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/cozy_colors.dart';
import 'package:cozy_health/core/widgets/bottom_navigation_bar.dart';
import 'package:cozy_health/features/activity/presentation/screens/activity_screens.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_hub_screen.dart';
import 'package:cozy_health/features/content/data/published_articles_repository.dart';
import 'package:cozy_health/features/crisis/presentation/widgets/crisis_fab.dart';
import '../../support/local_fonts.dart';
import '../settings/provider_hub_test.dart' show MessagingApi;
import '../settings/provider_resources_test.dart' show ResourceService;
import '../../../tool/design_previews/profile_community_proposals.dart';

const reviewOutput = 'docs/design/activity-provider-implemented';
const reviewKey = ValueKey('implemented-review-capture');

class ReviewArticles extends PublishedArticlesRepository {
  ReviewArticles() : super(api: MessagingApi());
  final rows = [
    for (final (i, title) in [
      'Mental Health 101: Understanding Anxiety, Depression, and Stress',
      'Balancing Productivity and Mental Health: How to Avoid Burnout',
      'The Link Between Diet, Exercise, and Mental Health',
      'The Role of Gratitude in Improving Mental Health',
    ].indexed)
      PublishedArticle.fromJson({
        'id': 'article-$i',
        'title': title,
        'body': 'Synthetic article body for a screenshot fixture.',
      }),
  ];
  @override
  Future<PublishedArticlePage> load({int page = 1}) async =>
      PublishedArticlePage(rows, page, 1);
  @override
  Future<PublishedArticle> detail(PublishedArticle article) async => article;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUpAll(() async {
    await installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    );
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    cache = await Directory.systemTemp.createTemp('cozy_implemented_review_');
    Hive.init(cache.path);
    await LocalDbService().settingsBox();
    await LocalDbService().preferencesBox();
    DemoMode.instance.enabled = true;
    networkOffline.value = false;
    final now = DateTime.now();
    DateTime day(int offset) => DateTime(now.year, now.month, now.day + offset);
    DemoMode.instance.moods
      ..clear()
      ..addAll([
        for (final (offset, intensity) in [
          (-6, 6),
          (-5, 8),
          (-3, 6),
          (-2, 4),
          (0, 8),
        ])
          MoodEntry(
            id: 'review-$offset',
            mood: 'good',
            intensity: intensity,
            triggers: ['Work', if (offset % 2 == 0) 'Sleep'],
            createdAt: day(offset),
            updatedAt: day(offset),
          ),
      ]);
    DemoMode.instance.journals
      ..clear()
      ..addAll([
        for (var i = 0; i < 3; i++)
          JournalEntry(
            id: 'review-j$i',
            type: 'free',
            body: 'Screenshot fixture',
            wordCount: 2,
            createdAt: day(-i),
            updatedAt: day(-i),
          ),
      ]);
    await Directory(reviewOutput).create(recursive: true);
  });
  tearDownAll(() async {
    networkOffline.value = null;
    DemoMode.instance.enabled = false;
    await Hive.close();
    resetLocalTestFonts();
    await cache.delete(recursive: true);
  });
  Future<void> pump(
    WidgetTester tester,
    String screen, {
    bool dark = false,
    int accent = 0,
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
    final api = MessagingApi()
      ..messages.addAll([
        {
          'id': 1,
          'sender': 'provider',
          'content':
              'Hello. What would you like to focus on at our next appointment?',
          'records': [],
          'created_at': '2026-10-22T12:00:00Z',
        },
        {
          'id': 2,
          'sender': 'patient',
          'content':
              'I’d like to talk about my sleep and what has helped this week.',
          'records': [],
          'created_at': '2026-10-22T12:03:00Z',
        },
        {
          'id': 3,
          'sender': 'provider',
          'content':
              'Of course. You can share any check-ins you’d like us to discuss.',
          'records': [],
          'created_at': '2026-10-22T12:05:00Z',
        },
      ]);
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
        home: Builder(
          builder: (context) {
            final w = context.cozyColors.wellness,
                activity = screen == 'activity',
                provider = screen == 'provider';
            final child = activity
                ? ActivityScreen(articlesRepository: ReviewArticles())
                : provider
                ? ProviderHubScreen(
                    apiClient: api,
                    settingsService: ResourceService(),
                  )
                : ProfileCommunityProposal(screen: screen);
            return RepaintBoundary(
              key: reviewKey,
              child: Scaffold(
                backgroundColor: w.canvas(theme.brightness, contrast),
                bottomNavigationBar: screen == 'profile' || screen == 'member'
                    ? null
                    : CustomBottomNavigationBar(
                        currentIndex: activity
                            ? 1
                            : provider
                            ? 2
                            : 3,
                        onTap: (_) {},
                      ),
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    child,
                    if (activity) ...[
                      Positioned(
                        right: w.floatingInset,
                        bottom:
                            w.floatingInset + w.floatingSize + w.floatingGap,
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    if (screen == 'activity') {
      await tester.runAsync(
        () => Future.wait([
          for (final name in ['anxiety', 'burnout', 'wellbeing', 'gratitude'])
            precacheImage(
              AssetImage('assets/png/recommended_$name.png'),
              tester.element(find.byKey(reviewKey)),
            ),
        ]),
      );
    }
    await tester.pump();
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
    expect(
      closed,
      isTrue,
      reason: 'Finish account-cache writes before ending the render fixture.',
    );
    await tester.runAsync(() => LocalDbService().settingsBox());
  }

  Future<void> save(WidgetTester tester, String file) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump();
    }
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(reviewKey),
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
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError(file);
      await File(
        '$reviewOutput/$file.png',
      ).writeAsBytes(data.buffer.asUint8List());
      img.dispose();
    });
    debugDisableShadows = previousShadows;
    repaint(boundary);
    await tester.pump();
  }

  for (final dark in [false, true]) {
    for (final accent in [0, 1, 2, 3]) {
      for (final contrast in [false, true]) {
        for (final screen in ['activity', 'provider']) {
          testWidgets(
            'implemented $screen dark=$dark accent=$accent contrast=$contrast',
            (tester) async {
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              await pump(
                tester,
                screen,
                dark: dark,
                accent: accent,
                contrast: contrast,
              );
              final name =
                  '$screen-${dark ? 'dark' : 'light'}-${['blue', 'green', 'orange', 'yellow'][accent]}${contrast ? '-contrast' : ''}';
              await save(tester, name);
              if (screen == 'activity' && accent == 0 && !contrast) {
                tester.view.physicalSize = const Size(750, 6000);
                await tester.pumpAndSettle();
                final bottom = tester
                    .getRect(find.text('View all articles'))
                    .bottom;
                tester.view.physicalSize = Size(750, (bottom + 224) * 2);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                await save(tester, '$name-full');
                tester.view.physicalSize = const Size(750, 1624);
                await tester.pumpAndSettle();
                await tester.scrollUntilVisible(
                  find.text('Recommended for you'),
                  350,
                  scrollable: find
                      .descendant(
                        of: find.byType(ActivityScreen),
                        matching: find.byType(Scrollable),
                      )
                      .first,
                );
                await tester.pumpAndSettle();
                await save(tester, '$name-articles');
              }
              if (screen == 'provider' && accent == 0 && !contrast) {
                await tester.tap(find.byKey(const ValueKey('provider-tab-1')));
                await tester.pumpAndSettle();
                await save(
                  tester,
                  'provider-history-${dark ? 'dark' : 'light'}',
                );
                await tester.tap(find.byKey(const ValueKey('provider-tab-2')));
                for (var i = 0; i < 12; i++) {
                  await tester.runAsync(
                    () =>
                        Future<void>.delayed(const Duration(milliseconds: 40)),
                  );
                  await tester.pump();
                }
                await tester.pump();
                expect(find.byType(CircularProgressIndicator), findsNothing);
                expect(tester.takeException(), isNull);
                await save(
                  tester,
                  'provider-resources-${dark ? 'dark' : 'light'}',
                );
              }
              await unmount(tester);
            },
          );
        }
      }
    }
  }
  for (final screen in ['profile', 'community', 'groups', 'member']) {
    for (final dark in [false, true]) {
      testWidgets('proposal $screen dark=$dark', (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pump(tester, screen, dark: dark, accent: dark ? 3 : 0);
        await save(tester, 'proposal-$screen-${dark ? 'dark' : 'light'}');
        tester.view.physicalSize = const Size(750, 5000);
        await tester.pumpAndSettle();
        final height =
            tester
                .getSize(
                  find.byKey(const ValueKey('profile-community-content')),
                )
                .height +
            40 +
            (screen == 'profile' || screen == 'member' ? 0 : 72);
        tester.view.physicalSize = Size(750, height * 2);
        await tester.pumpAndSettle();
        // Full content is rendered by the tall viewport, including bottom actions.
        await save(tester, 'proposal-$screen-${dark ? 'dark' : 'light'}-full');
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });
    }
  }
  for (final screen in [
    'activity',
    'provider',
    'profile',
    'community',
    'groups',
    'member',
  ]) {
    testWidgets('large type $screen', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(
        tester,
        screen,
        dark: true,
        accent: 3,
        contrast: true,
        large: true,
      );
      await save(tester, '$screen-large-contrast');
      if (screen == 'provider') {
        tester.view.physicalSize = const Size(1334, 750);
        tester.view.viewInsets = const FakeViewPadding(bottom: 360);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await save(tester, 'provider-landscape-keyboard');
      }
      await unmount(tester);
    });
  }
}
