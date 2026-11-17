import 'package:cozy_health/core/data/mood_recording_catalog.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/appearance_preferences.dart';
import 'package:cozy_health/features/mood_check_in/presentation/mood_recording_controller.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_feeling_screen.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_recording_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'support/local_fonts.dart';
import 'support/mood_recording_fakes.dart';
import 'support/mood_review_capture.dart';

void main() {
  setUp(
    () => installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    ),
  );
  tearDown(resetLocalTestFonts);
  late MoodRecordingController flow;
  late MemoryMoodRepository repository;
  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(375, 812),
    double textScale = 1,
    Brightness brightness = Brightness.light,
    bool historical = false,
    String? initialMood,
    bool contrast = false,
    bool safeAreas = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (safeAreas) {
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.resetPadding);
    }
    repository = MemoryMoodRepository();
    flow = MoodRecordingController(
      entry: historical ? historicalMood() : null,
      initialMood: initialMood,
      repository: repository,
      drafts: MemoryMoodDrafts(),
      wellness: MemoryMoodCatalog(),
      accountScope: () => 'test-account',
      accountChanges: const Stream.empty(),
    );
    addTearDown(flow.dispose);
    final router = GoRouter(
      initialLocation: '/mood-feeling',
      routes: [
        GoRoute(
          path: '/mood-feeling',
          builder: (_, _) =>
              MoodFeelingScreen(controller: flow, initialMood: initialMood),
        ),
        GoRoute(
          path: '/mood-success',
          builder: (_, state) =>
              MoodCheckInSuccessScreen(entry: state.extra as MoodEntry?),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/mood-history',
          builder: (_, _) => const Scaffold(body: Text('History')),
        ),
      ],
    );
    addTearDown(router.dispose);
    var theme = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
    if (contrast) theme = AppTheme.highContrast(theme);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            highContrast: contrast,
          ),
          child: RepaintBoundary(
            key: const ValueKey('capture'),
            child: LiveAppearanceTheme(theme: Theme.of(context), child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('recording-continue')));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester) async {
    if (find
        .byKey(const ValueKey('recording-hit-expressions-angry-resentful'))
        .evaluate()
        .isEmpty) {
      await tester.tap(find.byKey(const ValueKey('mood-category-angry')));
      await tester.pumpAndSettle();
    }
    await tester.tap(
      find.byKey(const ValueKey('recording-hit-expressions-angry-resentful')),
    );
    await tester.pumpAndSettle();
  }

  for (final mood in [
    'angry',
    'sad',
    'good',
    'upset',
    'spectacular',
    'happy',
  ]) {
    testWidgets(
      'Home $mood reveals the existing feeling group without enabling Continue',
      (tester) async {
        await open(tester, initialMood: mood);
        final rect = tester.getRect(
          find.byKey(ValueKey('mood-category-$mood')),
        );
        final viewport = tester.getRect(find.byType(SingleChildScrollView));
        expect(rect.top, greaterThanOrEqualTo(viewport.top));
        expect(rect.bottom, lessThanOrEqualTo(viewport.bottom));
        expect(
          tester
              .widget<RecordingAction>(
                find.byKey(const ValueKey('recording-continue')),
              )
              .onPressed,
          isNull,
        );
        expect(find.text('How are you feeling?'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Feeling opens one category and keeps all 72 choices accessible',
    (tester) async {
      await open(tester);
      expect(
        find.text('Choose a category to see its feelings.'),
        findsOneWidget,
      );
      final expressions = <String>{};
      for (final mood in moodRecordingCatalog['moods'] as List) {
        await tester.ensureVisible(
          find.byKey(ValueKey('mood-category-${mood['slug']}')),
        );
        await tester.tap(find.byKey(ValueKey('mood-category-${mood['slug']}')));
        await tester.pumpAndSettle();
        final rows = (moodRecordingCatalog['expressions'] as List).where(
          (row) => row['feeling_id'] == mood['id'],
        );
        for (final row in rows) {
          final target = find.byKey(
            ValueKey('recording-hit-expressions-${row['slug']}'),
          );
          expect(target, findsOneWidget);
          expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
          expressions.add(row['slug'] as String);
        }
        expect(find.text('12 feelings'), findsOneWidget);
      }
      expect(expressions, hasLength(72));
      expect(flow.state.expression, isNull);
      await choose(tester);
      expect(flow.state.expression, 'angry-resentful');
      await tester.tap(find.byKey(const ValueKey('mood-category-sad')));
      await tester.pumpAndSettle();
      expect(flow.state.expression, 'angry-resentful');
      expect(
        find.byKey(const ValueKey('feeling-selection-summary')),
        findsOneWidget,
      );
      await next(tester);
      expect(flow.state.step, MoodRecordingStep.intensity);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all five stages persist selections and save the actual receipt',
    (tester) async {
      await open(tester);
      await choose(tester);
      expect(find.byType(Dialog), findsNothing);
      await next(tester);
      expect(find.text('2 of 5'), findsOneWidget);
      await tester.tapAt(
        Offset(
          tester.getRect(find.byType(Slider)).right - 25,
          tester.getRect(find.byType(Slider)).center.dy,
        ),
      );
      await tester.pumpAndSettle();
      expect(flow.state.intensity, 10);
      await next(tester);
      expect(find.text('3 of 5'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('recording-hit-triggers-work-deadlines')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Skip for now'), findsNothing);
      expect(find.text('1 cause selected'), findsOneWidget);
      await next(tester);
      expect(find.text('4 of 5'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('recording-hit-coping-deep-breathing')),
      );
      await tester.pumpAndSettle();
      await next(tester);
      expect(find.text('5 of 5'), findsOneWidget);
      for (final section in ['feeling', 'intensity', 'causes', 'coping']) {
        expect(find.byKey(ValueKey('recording-edit-$section')), findsOneWidget);
      }
      await next(tester);
      expect(find.text('Entry saved.'), findsOneWidget);
      expect(find.text('Deadlines'), findsOneWidget);
      expect(find.text('Deep breathing'), findsOneWidget);
      expect(repository.entries.values.single.intensity, 10);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('Entry saved.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Review Back cancels changes; Continue applies and returns directly',
    (tester) async {
      await open(tester, historical: true);
      for (var i = 0; i < 4; i++) {
        await next(tester);
      }
      await tester.tap(find.byKey(const ValueKey('recording-edit-intensity')));
      await tester.pumpAndSettle();
      tester.widget<Slider>(find.byType(Slider)).onChanged!(1);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(flow.state.intensity, 7);
      expect(flow.state.step, MoodRecordingStep.review);
      await tester.tap(find.byKey(const ValueKey('recording-edit-intensity')));
      await tester.pumpAndSettle();
      tester.widget<Slider>(find.byType(Slider)).onChanged!(5);
      await tester.pumpAndSettle();
      await next(tester);
      expect(flow.state.intensity, 10);
      expect(find.text('5 of 5'), findsOneWidget);
    },
  );

  testWidgets(
    'coping search filters without losing choices, cancel and apply differ',
    (tester) async {
      await open(tester);
      await choose(tester);
      for (var i = 0; i < 3; i++) {
        await next(tester);
      }
      await tester.tap(find.byKey(const ValueKey('coping-see-all')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('coping-search')),
        '  READING  ',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('recording-hit-coping-reading')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('coping-search')),
        'no matching response',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No responses found. Try a different search.'),
        findsOneWidget,
      );
      expect(find.text('1 response selected'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('coping-sheet-close')));
      await tester.pumpAndSettle();
      expect(flow.state.coping, isEmpty);
      await tester.tap(find.byKey(const ValueKey('coping-see-all')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('coping-search')),
        'Reading',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('recording-hit-coping-reading')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('coping-sheet-apply')));
      await tester.pumpAndSettle();
      expect(flow.state.coping, {'Reading'});
      expect(flow.state.step, MoodRecordingStep.coping);
      expect(
        find.byKey(const ValueKey('recording-hit-coping-reading')),
        findsOneWidget,
      );
    },
  );

  for (final size in [
    const Size(320, 812),
    const Size(430, 932),
    const Size(812, 375),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('all scoped screens adapt at $size, 200% text, $brightness', (
        tester,
      ) async {
        await open(
          tester,
          size: size,
          textScale: 2,
          brightness: brightness,
          historical: true,
        );
        for (var i = 0; i < 4; i++) {
          await next(tester);
          expect(tester.takeException(), isNull);
          if (flow.state.step == MoodRecordingStep.coping) {
            await tester.ensureVisible(
              find.byKey(const ValueKey('coping-see-all')),
            );
            await tester.tap(find.byKey(const ValueKey('coping-see-all')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.tap(find.byKey(const ValueKey('coping-sheet-close')));
            await tester.pumpAndSettle();
          }
        }
      });
    }
  }

  testWidgets('sheet remains usable with a landscape keyboard and large text', (
    tester,
  ) async {
    await open(
      tester,
      size: const Size(812, 375),
      textScale: 2,
      historical: true,
    );
    for (var i = 0; i < 3; i++) {
      await next(tester);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('coping-see-all')));
    await tester.tap(find.byKey(const ValueKey('coping-see-all')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('coping-search')),
      'Reading',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey('recording-hit-coping-reading')),
    );
    await tester.tap(
      find.byKey(const ValueKey('recording-hit-coping-reading')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('coping-sheet-apply')));
    await tester.pumpAndSettle();
    expect(flow.state.coping, {'Old response', 'Reading'});
    expect(tester.takeException(), isNull);
  });

  for (final dismissal in ['barrier', 'back', 'drag']) {
    testWidgets(
      'sheet $dismissal cancels pending selections inside Review editing',
      (tester) async {
        await open(tester, historical: true);
        for (var i = 0; i < 4; i++) {
          await next(tester);
        }
        await tester.tap(find.byKey(const ValueKey('recording-edit-coping')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('coping-see-all')),
        );
        await tester.tap(find.byKey(const ValueKey('coping-see-all')));
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .byKey(const ValueKey('recording-hit-coping-deep-breathing'))
              .last,
        );
        await tester.pumpAndSettle();
        switch (dismissal) {
          case 'barrier':
            await tester.tapAt(const Offset(4, 4));
          case 'back':
            await tester.binding.handlePopRoute();
          case 'drag':
            await tester.dragFrom(
              tester.getTopLeft(find.byType(CopingResponseSheet)) +
                  const Offset(170, -8),
              const Offset(0, 700),
            );
        }
        await tester.pumpAndSettle();
        expect(find.byType(CopingResponseSheet), findsNothing);
        expect(flow.state.coping, {'Old response'});
        expect(flow.editingReview, isTrue);
        await tester.tap(find.bySemanticsLabel('Back'));
        await tester.pumpAndSettle();
        expect(flow.state.step, MoodRecordingStep.review);
        expect(flow.state.coping, {'Old response'});
      },
    );
  }

  testWidgets('retired causes can be removed and failed saves retain Review', (
    tester,
  ) async {
    await open(tester, historical: true);
    await next(tester);
    await next(tester);
    final retired = find.byKey(
      const ValueKey('recording-hit-triggers-historical-Retired cause'),
    );
    await tester.ensureVisible(retired);
    await tester.tap(retired);
    await tester.pumpAndSettle();
    expect(flow.state.causes, isEmpty);
    await next(tester);
    await next(tester);
    repository.fail = true;
    await next(tester);
    expect(find.text('Review your check-in'), findsOneWidget);
    expect(
      find.text("We couldn't save your check-in. Your draft is still here."),
      findsOneWidget,
    );
    expect(repository.entries, isEmpty);
    repository.fail = false;
    await next(tester);
    expect(find.text('Entry saved.'), findsOneWidget);
    expect(repository.entries, hasLength(1));
  });

  testWidgets('new controls have accessible labels and touch targets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await open(tester, historical: true, contrast: true);
      await next(tester);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Resentful intensity'))
            .getSemanticsData()
            .label,
        'Resentful intensity',
      );
      await next(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets('v3 visual captures $brightness', (tester) async {
      await open(tester, brightness: brightness, safeAreas: true);
      await choose(tester);
      await next(tester);
      flow.setIntensity(4);
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        await settleMoodReviewImages(tester);
        if (const bool.fromEnvironment('SURFACE_REAL_FONTS')) {
          await expectLater(
            find.byKey(const ValueKey('capture')),
            matchesGoldenFile(
              'goldens/mood_recording/v3/${brightness.name}-$name.png',
            ),
          );
        }
        await captureMoodReview(tester, 'v3-${brightness.name}-$name');
      }

      await capture('intensity');
      await next(tester);
      await tester.tap(
        find.byKey(const ValueKey('recording-hit-triggers-work-deadlines')),
      );
      await tester.tap(
        find.byKey(const ValueKey('recording-hit-triggers-work-workload')),
      );
      await capture('causes');
      await next(tester);
      await tester.tap(
        find.byKey(const ValueKey('recording-hit-coping-deep-breathing')),
      );
      await tester.tap(
        find.byKey(const ValueKey('recording-hit-coping-listening-to-music')),
      );
      await capture('coping');
      await tester.ensureVisible(find.byKey(const ValueKey('coping-see-all')));
      await tester.tap(find.byKey(const ValueKey('coping-see-all')));
      await capture('responses');
      await tester.tap(find.byKey(const ValueKey('coping-sheet-close')));
      await tester.pumpAndSettle();
      await next(tester);
      await capture('review');
      await next(tester);
      await capture('saved');
      expect(tester.takeException(), isNull);
    });
  }

  test('catalog still retains all original choices and intensity mapping', () {
    expect(moodRecordingCatalog['expressions'], hasLength(72));
    expect(moodRecordingCatalog['triggers'], hasLength(48));
    expect(moodRecordingCatalog['coping'], hasLength(34));
    expect(
      [for (var i = 1; i <= 5; i++) moodIntensityToStorage(i)],
      [2, 4, 6, 8, 10],
    );
    expect(AppColors.primary, const Color(0xFF0460D8));
  });
}
