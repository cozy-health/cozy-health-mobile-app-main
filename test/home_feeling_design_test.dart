import 'dart:ui' as ui;
import 'package:cozy_health/core/widgets/mood_artwork.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/cozy_colors.dart';
import 'package:cozy_health/core/widgets/app_pressable.dart';
import 'package:cozy_health/core/widgets/bottom_navigation_bar.dart';
import 'package:cozy_health/core/utils/motion.dart';
import 'package:cozy_health/core/theme/appearance_preferences.dart';
import 'package:cozy_health/core/widgets/mood_category_grid.dart';
import 'package:cozy_health/features/home/presentation/widgets/home_design_widgets.dart';
import 'package:cozy_health/features/mood_check_in/presentation/mood_recording_controller.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_feeling_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/local_fonts.dart';
import 'support/mood_recording_fakes.dart';

void main() {
  setUp(
    () => installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    ),
  );
  tearDown(resetLocalTestFonts);

  test(
    'semantic Home fills retain readable foregrounds for every production theme',
    () {
      for (final dark in [false, true]) {
        for (final accent in AppColors.brandPalette) {
          for (final contrast in [false, true]) {
            var theme = AppTheme.withAccent(
              dark ? AppTheme.dark : AppTheme.light,
              accent,
            );
            if (contrast) theme = AppTheme.highContrast(theme);
            final colors = theme.extension<CozyColors>()!;
            final t = colors.wellness;
            for (final fill in [
              t.canvas(theme.brightness, contrast),
              t.accentPanel(theme.colorScheme),
              t.reminder(theme.brightness),
              theme.colorScheme.surface,
            ]) {
              expect(
                colors.recording.contrastRatio(
                  theme.colorScheme.onSurface,
                  fill,
                ),
                greaterThanOrEqualTo(4.5),
              );
              final action = colors.recording.controlColor(
                accent,
                fill,
                theme.colorScheme.onSurface,
              );
              expect(
                colors.recording.contrastRatio(action, fill),
                greaterThanOrEqualTo(4.5),
              );
            }
          }
        }
      }
    },
  );

  for (final reduced in [false, true]) {
    testWidgets(
      'category changes are interruptible and respect reduced motion=$reduced',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final drafts = MemoryMoodDrafts();
        final flow = MoodRecordingController(
          initialMood: 'angry',
          drafts: drafts,
          repository: MemoryMoodRepository(),
          wellness: MemoryMoodCatalog(),
          accountScope: () => 'motion',
          accountChanges: const Stream.empty(),
        );
        addTearDown(flow.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!,
            ),
            home: MoodFeelingScreen(controller: flow),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Choose a feeling to continue.'), findsOneWidget);
        expect(find.textContaining('Selected:'), findsNothing);
        final switcher = tester.widget<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        );
        expect(
          switcher.duration,
          reduced ? Duration.zero : const Duration(milliseconds: 180),
        );
        final choice = find.byKey(
          const ValueKey('recording-hit-expressions-angry-resentful'),
        );
        final before = tester.getRect(choice);
        await tester.tap(
          find.byKey(
            const ValueKey('recording-hit-expressions-angry-resentful'),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(choice), before);
        for (final category in ['sad', 'good', 'happy']) {
          await tester.tap(find.byKey(ValueKey('mood-category-$category')));
          await tester.pump(const Duration(milliseconds: 30));
        }
        await tester.pumpAndSettle();
        expect(flow.state.expression, 'angry-resentful');
        expect(find.text('12 feelings'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('feeling-selection-summary')),
          findsOneWidget,
        );
        final grid = tester.element(find.byType(MoodCategoryGrid));
        expect(MediaQuery.disableAnimationsOf(grid), reduced);
        final tile = tester.widget<AnimatedContainer>(
          find.descendant(
            of: find.byKey(const ValueKey('mood-category-happy')),
            matching: find.byType(AnimatedContainer),
          ),
        );
        expect(
          tile.duration,
          reduced ? Duration.zero : const Duration(milliseconds: 180),
        );
        await tester.tap(find.byKey(const ValueKey('mood-category-angry')));
        await tester.pumpAndSettle();
        final semantics = tester.ensureSemantics();
        expect(
          tester.getSemantics(
            find.byKey(
              const ValueKey('recording-hit-expressions-angry-resentful'),
            ),
          ),
          matchesSemantics(
            label: 'Resentful',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: true,
          ),
        );
        semantics.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'rhythm uses last seven local dates, latest daily entry and a legacy saved marker',
    (tester) async {
      final now = DateTime(2026, 10, 22, 18);
      MoodEntry entry(String id, String mood, DateTime date) => MoodEntry(
        id: id,
        mood: mood,
        intensity: 6,
        createdAt: date,
        updatedAt: date,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeRhythmCard(
                entries: [
                  entry('old', 'angry', DateTime(2026, 10, 22, 9)),
                  entry('latest', 'happy', DateTime(2026, 10, 22, 17)),
                  entry('legacy', 'calm', DateTime(2026, 10, 21)),
                ],
                streak: 2,
                hasMoodToday: false,
                onStreak: () {},
                now: now,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final days = tester
          .widgetList<Semantics>(
            find.byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('rhythm-day-'),
            ),
          )
          .toList();
      expect(days, hasLength(7));
      expect(days.every((day) => day.properties.onTap == null), isTrue);
      expect(days.first.properties.label, contains('16/10'));
      expect(days.last.properties.label, contains('Happy'));
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      final paths = tester
          .widgetList<Image>(find.byType(Image))
          .map((i) => (i.image as AssetImage).assetName);
      expect(paths, contains('assets/png/home_reference_happy.png'));
      expect(paths, isNot(contains('assets/png/home_reference_angry.png')));
      expect(find.text('Your check-in is saved for today.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'resuming an Angry draft from the Sad Home shortcut opens the saved category',
    (tester) async {
      final drafts = MemoryMoodDrafts()
        ..data = {
          'version': 3,
          'step': 0,
          'mood': 'angry',
          'expression_slug': 'angry-resentful',
          'intensity': 7,
        };
      final flow = MoodRecordingController(
        initialMood: 'sad',
        drafts: drafts,
        repository: MemoryMoodRepository(),
        wellness: MemoryMoodCatalog(),
        accountScope: () => 'resume',
        accountChanges: const Stream.empty(),
      );
      addTearDown(flow.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MoodFeelingScreen(controller: flow, initialMood: 'sad'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MoodCategoryGrid>(find.byType(MoodCategoryGrid)).selected,
        'angry',
      );
      expect(
        find.byKey(const ValueKey('recording-hit-expressions-angry-resentful')),
        findsOneWidget,
      );
      expect(flow.state.expression, 'angry-resentful');
      expect(flow.state.intensity, 7);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'iOS Reduce Motion reaches root preferences and custom controls',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final media = appearanceMediaQuery(const MediaQueryData());
      expect(media.disableAnimations, isTrue);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                expect(shouldReduceMotion(context), isTrue);
                return MoodCategoryGrid(onSelected: (_) {});
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tile = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const ValueKey('mood-category-angry')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(tile.duration, Duration.zero);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large text navigation keeps full labels and reveals selected destination',
    (tester) async {
      tester.view.physicalSize = const Size(320, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme = AppTheme.withAccent(
        AppTheme.light,
        AppColors.brandPalette[3],
      );
      var selected = 0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Scaffold(
                bottomNavigationBar: CustomBottomNavigationBar(
                  currentIndex: selected,
                  onTap: (index) => setState(() => selected = index),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final foreground = tester.widget<Text>(find.text('Home')).style!.color!;
      expect(
        theme.extension<CozyColors>()!.recording.contrastRatio(
          foreground,
          theme.bottomNavigationBarTheme.backgroundColor!,
        ),
        greaterThanOrEqualTo(4.5),
      );
      for (final label in [
        'Home',
        'Activity',
        'Provider',
        'Community',
        'Settings',
      ]) {
        final text = tester.widget<Text>(find.text(label));
        expect(text.overflow, isNot(TextOverflow.ellipsis));
      }
      update(() => selected = 4);
      await tester.pumpAndSettle();
      final settings = tester.getRect(find.text('Settings'));
      expect(settings.left, greaterThanOrEqualTo(0));
      expect(settings.right, lessThanOrEqualTo(320));
      await tester.tap(find.text('Settings'));
      expect(selected, 4);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('yellow keyboard focus remains visible above an opaque control', (
    tester,
  ) async {
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy = previousStrategy,
    );
    final theme = AppTheme.withAccent(
      AppTheme.light,
      AppColors.brandPalette[3],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: AppPressable(
            label: 'Focus target',
            onPressed: () {},
            child: Container(
              color: theme.colorScheme.surface,
              child: const Text('Focus target'),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final ring = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(AppPressable),
            matching: find.byType(DecoratedBox),
          ),
        )
        .where(
          (box) =>
              box.decoration is BoxDecoration &&
              (box.decoration as BoxDecoration).border != null,
        )
        .single;
    expect(ring.position, DecorationPosition.foreground);
    final color =
        ((ring.decoration as BoxDecoration).border as Border).top.color;
    expect(
      theme.extension<CozyColors>()!.recording.contrastRatio(
        color,
        theme.colorScheme.surface,
      ),
      greaterThanOrEqualTo(3),
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'card fill changes with each accent while the reminder stays distinct',
    () {
      for (final base in [AppTheme.light, AppTheme.dark]) {
        final fills = <Color>{};
        final reminders = <Color>{};
        for (final accent in AppColors.brandPalette) {
          final theme = AppTheme.withAccent(base, accent);
          final tokens = theme.extension<CozyColors>()!.wellness;
          final fill = tokens.accentPanel(theme.colorScheme);
          fills.add(fill);
          reminders.add(tokens.reminder(theme.brightness));
          expect(fill, isNot(tokens.reminder(theme.brightness)));
          expect(fill.a, 1);
        }
        expect(fills, hasLength(4));
        expect(reminders, hasLength(1));
      }
    },
  );

  testWidgets(
    'original characters have clear gutters and balanced visible body area',
    (tester) async {
      final areas = <int>[];
      for (final mood in MoodCategoryGrid.moods) {
        final data = await rootBundle.load(MoodArtwork.assetFor(mood)!);
        await tester.runAsync(() async {
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final frame = await codec.getNextFrame();
          final image = frame.image;
          expect(image.width, 384, reason: mood);
          expect(image.height, 384, reason: mood);
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (bytes == null) {
            throw StateError('Cannot inspect character pixels');
          }
          var left = image.width, top = image.height, right = -1, bottom = -1;
          for (var y = 0; y < image.height; y++) {
            for (var x = 0; x < image.width; x++) {
              final alpha = bytes.getUint8((y * image.width + x) * 4 + 3);
              if (x == 0 ||
                  y == 0 ||
                  x == image.width - 1 ||
                  y == image.height - 1) {
                expect(
                  alpha,
                  lessThanOrEqualTo(1),
                  reason: '$mood shadow edge',
                );
              }
              if (alpha >= 250) {
                if (x < left) left = x;
                if (y < top) top = y;
                if (x > right) right = x;
                if (y > bottom) bottom = y;
              }
            }
          }
          expect(right, greaterThan(left), reason: mood);
          areas.add((right - left + 1) * (bottom - top + 1));
          expect((left + right) / 2, closeTo(191.5, 4), reason: mood);
          expect((top + bottom) / 2, closeTo(191.5, 4), reason: mood);
          image.dispose();
          codec.dispose();
        });
      }
      areas.sort();
      expect(areas.last / areas.first, lessThan(1.12));
    },
  );
}
