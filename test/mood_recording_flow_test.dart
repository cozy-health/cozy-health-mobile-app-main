import 'dart:io';
import 'dart:ui' as ui;
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/data/mood_recording_catalog.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/appearance_preferences.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_feeling_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/local_fonts.dart';
import 'support/mood_review_capture.dart';
import 'package:cozy_health/core/services/mood_draft_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_recording_layout.dart';

ThemeData themeFor(
  Brightness brightness,
  Color accent, [
  bool contrast = false,
]) {
  final base = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
  final onAccent = accent.computeLuminance() > .179
      ? Colors.black
      : Colors.white;
  final theme = base.copyWith(
    primaryColor: accent,
    colorScheme: base.colorScheme.copyWith(
      primary: accent,
      onPrimary: onAccent,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accent),
    ),
  );
  return contrast ? AppTheme.highContrast(theme) : theme;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    ),
  );
  tearDown(resetLocalTestFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DemoMode.instance.enabled = true;
  });
  tearDown(() => DemoMode.instance.enabled = false);

  MoodEntry legacy() => MoodEntry(
    id: 'legacy-record',
    mood: 'angry',
    intensity: 7,
    expressionSlug: 'angry-resentful',
    bodySensations: ['Chest'],
    sleepQuality: 2,
    energyLevel: 4,
    note: 'A long day',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(375, 812),
    double textScale = 1,
    Brightness brightness = Brightness.light,
    Color accent = AppColors.primary,
    bool highContrast = false,
    bool safeAreas = false,
    bool freshEntry = false,
    String? initialMood,
    ValueNotifier<ThemeData>? appearance,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    if (safeAreas) {
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.resetPadding);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/mood',
      routes: [
        GoRoute(
          path: '/mood',
          builder: (_, _) => MoodFeelingScreen(
            entry: freshEntry ? null : legacy(),
            initialMood: initialMood,
          ),
        ),
        GoRoute(
          path: '/mood-success',
          builder: (_, _) => const MoodCheckInSuccessScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    final themeState =
        appearance ?? ValueNotifier(themeFor(brightness, accent, highContrast));
    if (appearance == null) addTearDown(themeState.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<ThemeData>(
        valueListenable: themeState,
        builder: (_, theme, _) => MaterialApp.router(
          routerConfig: router,
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              highContrast: highContrast,
            ),
            child: RepaintBoundary(
              key: const ValueKey('capture'),
              child: LiveAppearanceTheme(
                theme: Theme.of(context),
                child: child!,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
  }

  for (final mood in ['sad', 'good', 'upset', 'spectacular', 'happy']) {
    testWidgets('Home $mood reveals the matching feelings category', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({});
      late Directory directory;
      await tester.runAsync(() async {
        directory = await Directory.systemTemp.createTemp(
          'cozy_mood_shortcut_',
        );
        Hive.init(directory.path);
        await MoodDraftService().clear();
      });
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          await Hive.close();
          await directory.delete(recursive: true);
        });
      });
      await open(tester, freshEntry: true, initialMood: mood);
      final title = '${mood[0].toUpperCase()}${mood.substring(1)}';
      final heading = tester.getRect(find.text(title));
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      expect(heading.top, greaterThanOrEqualTo(viewport.top));
      expect(heading.bottom, lessThanOrEqualTo(viewport.bottom));
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNull,
        reason: 'A category shortcut must still require a confirmed feeling.',
      );
      expect(tester.takeException(), isNull);
    });
  }

  test('legacy drafts map every old step while preserving hidden values', () {
    const expected = [0, 0, 0, 1, 1, 1, 1, 2, 3];
    for (var step = 1; step <= 9; step++) {
      final migrated = migrateMoodRecordingDraft({
        'step': step,
        'intensity': 7,
        'note': 'Keep me',
        'sleep': 2,
        'body': ['Chest'],
      });
      expect(migrated['step'], expected[step - 1]);
      expect(migrated['intensity'], 7);
      expect(migrated['note'], 'Keep me');
      expect(migrated['sleep'], 2);
      expect(migrated['body'], ['Chest']);
      expect(migrateMoodRecordingDraft(migrated), migrated);
    }
  });

  test(
    'reference catalog has unique feeling keys and compatible intensity mapping',
    () {
      final expressions = moodRecordingCatalog['expressions'] as List;
      expect(expressions, hasLength(72));
      expect(expressions.map((r) => r['slug']).toSet(), hasLength(72));
      expect(
        (moodRecordingCatalog['coping'] as List).where(
          (r) => r['name'] == 'Talking to a friend',
        ),
        hasLength(1),
      );
      expect(
        [for (var i = 1; i <= 5; i++) moodIntensityToStorage(i)],
        [2, 4, 6, 8, 10],
      );
      expect(moodIntensityToDisplay(7), 4);
    },
  );

  testWidgets(
    'popup cancellation preserves feeling; confirmation replaces it',
    (tester) async {
      await open(tester);
      await tester.tap(find.text('Displaced'));
      await tester.pumpAndSettle();
      expect(find.text('How intense is this feeling?'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('recording-intensity-body')))
            .width,
        inInclusiveRange(270, 360),
      );
      expect(tester.getSize(find.byType(Slider)).width, greaterThan(222));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester);
      await next(tester);
      expect(find.textContaining('Resentful (angry)'), findsOneWidget);
      await tester.tap(find.byTooltip('Edit Feeling'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Displaced'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester);
      await next(tester);
      expect(find.textContaining('Displaced (angry)'), findsOneWidget);
      expect(find.textContaining('Intensity: 3/5'), findsOneWidget);
    },
  );

  testWidgets(
    'confirmed intensity reopens and cancelled changes are discarded',
    (tester) async {
      await open(tester);
      await tester.tap(find.text('Resentful'));
      await tester.pumpAndSettle();
      expect(find.text('Strong · 4/5'), findsOneWidget);
      tester.widget<Slider>(find.byType(Slider)).onChanged!(5);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resentful'));
      await tester.pumpAndSettle();
      expect(find.text('Very strong · 5/5'), findsOneWidget);
      tester.widget<Slider>(find.byType(Slider)).onChanged!(1);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resentful'));
      await tester.pumpAndSettle();
      expect(find.text('Very strong · 5/5'), findsOneWidget);
    },
  );

  testWidgets('multiple causes and coping selections survive back and review', (
    tester,
  ) async {
    await open(tester);
    await next(tester);
    await tester.tap(find.text('Deadlines'));
    await tester.tap(find.text('Conflict'));
    await next(tester);
    await tester.tap(find.text('Deep breathing'));
    await tester.tap(find.text('Meditation'));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    await next(tester);
    await next(tester);
    expect(find.text('Deadlines, Conflict'), findsOneWidget);
    expect(find.text('Deep breathing, Meditation'), findsOneWidget);
  });

  testWidgets('save preserves historical intensity and hidden fields', (
    tester,
  ) async {
    final before = DemoMode.instance.moods
        .where((r) => r.id == 'legacy-record')
        .firstOrNull;
    addTearDown(() {
      DemoMode.instance.moods.removeWhere((r) => r.id == 'legacy-record');
      if (before != null) DemoMode.instance.upsertMood(before);
    });
    await open(tester);
    await next(tester);
    await next(tester);
    await next(tester);
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    final saved = DemoMode.instance.moods.singleWhere(
      (r) => r.id == 'legacy-record',
    );
    expect(saved.intensity, 7);
    expect(saved.bodySensations, ['Chest']);
    expect(saved.note, 'A long day');
    expect(saved.sleepQuality, 2);
    expect(saved.energyLevel, 4);
    await captureMoodReview(tester, 'save-success');
    // The production success screen schedules a saved reminder after 5 seconds.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  for (final brightness in Brightness.values) {
    testWidgets('narrow layout and enlarged text work in $brightness', (
      tester,
    ) async {
      await open(
        tester,
        size: const Size(320, 812),
        textScale: 2,
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      await next(tester);
      expect(tester.takeException(), isNull);
      await next(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a failed local save keeps the entry available for retry', (
    tester,
  ) async {
    await open(tester);
    await next(tester);
    await next(tester);
    await next(tester);
    // This isolated fixture has no real Hive boxes, so a real local save fails.
    DemoMode.instance.enabled = false;
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    expect(
      find.text("We couldn't save your check-in. Your draft is still here."),
      findsOneWidget,
    );
    expect(find.text('Review your check-in'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save entry'))
          .onPressed,
      isNotNull,
    );
  });

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('mood controls remain readable and reachable at $width', (
      tester,
    ) async {
      await open(tester, size: Size(width, 812), textScale: 2);
      await captureMoodReview(tester, 'large-text-$width');
      final chip = find.byKey(
        const ValueKey('recording-expressions-angry-resentful'),
      );
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
      final before = tester.getSize(chip);
      final semantics = tester.ensureSemantics();
      expect(
        tester
            .getSemantics(
              find.byKey(
                const ValueKey('recording-hit-expressions-angry-resentful'),
              ),
            )
            .label,
        'Resentful',
      );
      semantics.dispose();
      await tester.ensureVisible(find.text('Over the moon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Over the moon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(tester.getSize(chip), before);
      expect(tester.takeException(), isNull);
      await next(tester);
      await next(tester);
      await tester.ensureVisible(
        find.text('Isolation from friends and family'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Isolation from friends and family'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'accent and dark mode update an open dialog without losing choices',
    (tester) async {
      final appearance = ValueNotifier(
        themeFor(Brightness.light, AppColors.primary),
      );
      addTearDown(appearance.dispose);
      await open(tester, appearance: appearance);
      await tester.ensureVisible(find.text('Resentful'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resentful'));
      await tester.pumpAndSettle();
      tester.widget<Slider>(find.byType(Slider)).onChanged!(5);
      await tester.pumpAndSettle();
      appearance.value = themeFor(Brightness.dark, AppColors.warmGreen);
      await tester.pumpAndSettle();
      final sliderTheme = tester
          .widget<SliderTheme>(
            find
                .ancestor(
                  of: find.byType(Slider),
                  matching: find.byType(SliderTheme),
                )
                .first,
          )
          .data;
      expect(sliderTheme.activeTrackColor, AppColors.warmGreen);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 5);
      expect(
        tester
            .widget<Dialog>(
              find.byKey(const ValueKey('recording-intensity-dialog')),
            )
            .backgroundColor,
        appearance.value.dialogTheme.backgroundColor,
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .color,
        AppColors.warmGreen,
      );
      await next(tester);
      await next(tester);
      await next(tester);
      expect(find.textContaining('Intensity: 5/5'), findsOneWidget);
      appearance.value = themeFor(Brightness.light, AppColors.warmYellow);
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save entry'),
      );
      expect(button.style!.backgroundColor!.resolve({}), AppColors.warmYellow);
      expect(button.style!.foregroundColor!.resolve({}), Colors.black);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('high contrast and large text remain usable in $brightness', (
      tester,
    ) async {
      await open(
        tester,
        brightness: brightness,
        accent: AppColors.warmYellow,
        highContrast: true,
        size: const Size(320, 812),
        textScale: 2,
      );
      final selected = tester.widget<Material>(
        find.byKey(const ValueKey('recording-expressions-angry-resentful')),
      );
      expect(selected.color, AppColors.warmYellow);
      final shape = selected.shape! as RoundedRectangleBorder;
      expect(shape.side.width, 2);
      await captureMoodReview(tester, 'high-contrast-${brightness.name}');
      await tester.tap(find.text('Resentful'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'reference rows fit at 375px with compact non-overlapping targets',
    (tester) async {
      await open(tester);
      for (final collection in ['expressions', 'triggers', 'coping']) {
        for (final row in moodRecordingReferenceRows[collection]!) {
          final rects = [
            for (final slug in row)
              tester.getRect(
                find.byKey(ValueKey('recording-$collection-$slug')),
              ),
          ];
          final hits = [
            for (final slug in row)
              tester.getRect(
                find.byKey(ValueKey('recording-hit-$collection-$slug')),
              ),
          ];
          for (var i = 0; i < rects.length; i++) {
            expect(
              rects[i].height,
              closeTo(28, .1),
              reason: '$collection: ${row[i]}',
            );
            expect(
              rects[i].top,
              closeTo(rects.first.top, .1),
              reason: 'Reference row must fit: $row',
            );
            expect(hits[i].height, greaterThanOrEqualTo(48));
            if (i > 0) {
              expect(hits[i].left, greaterThanOrEqualTo(hits[i - 1].right));
            }
          }
        }
        if (collection != 'coping') await next(tester);
      }
    },
  );

  testWidgets('full page reference review captures', (tester) async {
    await open(tester, size: const Size(375, 2300), safeAreas: true);
    await captureMoodReview(tester, 'full-feelings');
    await next(tester);
    await tester.tap(find.text('Deadlines'));
    await tester.tap(find.text('Family tension'));
    await captureMoodReview(tester, 'full-causes-selected');
    await next(tester);
    await captureMoodReview(tester, 'full-coping');
  });

  testWidgets('today draft resumes its selections and review', (tester) async {
    late Directory directory;
    FlutterSecureStorage.setMockInitialValues({});
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('cozy_mood_review_');
      Hive.init(directory.path);
      await MoodDraftService().save({
        'version': 2,
        'step': 3,
        'mood': 'sad',
        'expression_slug': 'sad-gloomy',
        'intensity': 8,
        'triggers': ['Deadlines', 'Family tension'],
        'coping': ['Meditation'],
      });
    });
    try {
      await open(tester, freshEntry: true);
      expect(
        find.text('You have an unsaved check-in. Resume?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(find.text('Review your check-in'), findsOneWidget);
      expect(find.textContaining('Gloomy (sad)'), findsOneWidget);
      expect(find.text('Deadlines, Family tension'), findsOneWidget);
      expect(find.text('Meditation'), findsOneWidget);
      await captureMoodReview(tester, 'resumed-draft-review');
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });
    }
  });

  for (final variant in ['light', 'dark', 'green']) {
    testWidgets('review production-theme golden captures $variant', (
      tester,
    ) async {
      await open(
        tester,
        brightness: variant == 'dark' ? Brightness.dark : Brightness.light,
        safeAreas: true,
        accent: variant == 'green' ? AppColors.warmGreen : AppColors.primary,
      );
      Future<void> capture(String name) async {
        await settleMoodReviewImages(tester);
        final finder = find.byKey(const ValueKey('capture'));
        if (const bool.fromEnvironment('SURFACE_REAL_FONTS')) {
          await expectLater(
            finder,
            matchesGoldenFile('goldens/mood_recording/$variant-$name.png'),
          );
        }
        final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('build/mood-selection-review');
          await dir.create(recursive: true);
          await File(
            '${dir.path}/$variant-$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('feelings');
      if (variant == 'light') {
        for (final name in ['Sad', 'Good', 'Upset', 'Spectacular', 'Happy']) {
          await tester.ensureVisible(find.text(name));
          await capture('feelings-${name.toLowerCase()}');
        }
        await tester.ensureVisible(find.text('Resentful'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Resentful'));
      await tester.pumpAndSettle();
      await capture('intensity');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await next(tester);
      await capture('causes');
      if (variant == 'light') {
        await tester.tap(find.text('Deadlines'));
        await capture('causes-selected');
        for (final name in [
          'School',
          'Relationship',
          'Sleep',
          'Health',
          'Life changes',
        ]) {
          await tester.ensureVisible(find.text(name));
          await capture('causes-${name.toLowerCase().replaceAll(' ', '-')}');
        }
      }
      await next(tester);
      await capture('coping');
      if (variant == 'light') {
        await tester.ensureVisible(
          find.text('Isolation from friends and family'),
        );
        await capture('coping-bottom');
      }
      await next(tester);
      await capture('review');
    });
  }
}
