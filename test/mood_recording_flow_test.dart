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
          builder: (_, _) => MoodFeelingScreen(entry: legacy()),
        ),
        GoRoute(
          path: '/mood-success',
          builder: (_, _) => const Scaffold(body: Text('Saved fixture')),
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
        270,
      );
      expect(tester.getSize(find.byType(Slider)).width, 222);
      Navigator.of(
        tester.element(
          find.byKey(const ValueKey('recording-intensity-dialog')),
        ),
      ).pop();
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
      final chip = find.byKey(
        const ValueKey('recording-expressions-angry-resentful'),
      );
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(56));
      final before = tester.getSize(chip);
      final semantics = tester.ensureSemantics();
      expect(tester.getSemantics(chip).label, 'Resentful');
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
        await tester.pumpAndSettle();
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
          final dir = Directory('build/mood-recording-review');
          await dir.create(recursive: true);
          await File(
            '${dir.path}/$variant-$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('feelings');
      if (variant == 'light') {
        for (final name in ['Good', 'Upset', 'Spectacular', 'Happy']) {
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
