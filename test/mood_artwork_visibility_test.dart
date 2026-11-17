import 'dart:io';
import 'package:cozy_health/core/models/mood_entry.dart';

import 'package:cozy_health/core/data/mood_recording_catalog.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/appearance_preferences.dart';
import 'package:cozy_health/core/theme/cozy_colors.dart';
import 'package:cozy_health/core/widgets/mood_artwork.dart';
import 'package:cozy_health/features/mood_check_in/presentation/mood_recording_controller.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_feeling_screen.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_recording_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/local_fonts.dart';
import 'support/mood_recording_fakes.dart';
import 'support/mood_review_capture.dart';

const _baseline = bool.fromEnvironment('MOOD_VISIBILITY_BASELINE');
const _prefix = _baseline ? 'visibility-before' : 'visibility-after';
const _moods = ['angry', 'sad', 'good', 'upset', 'spectacular', 'happy'];
MoodEntry _entry() => MoodEntry(
  id: 'visibility-entry',
  mood: 'angry',
  expressionSlug: 'angry-resentful',
  intensity: 7,
  triggers: ['Deadlines'],
  copingStrategies: ['Journaling'],
  createdAt: DateTime(2026, 10, 22, 12),
  updatedAt: DateTime(2026, 10, 22, 12),
);

const _groups = ['Work', 'School', 'Relationship', 'Sleep', 'Health', 'Life changes'];

List<Map<String, dynamic>> _causeGroup(int index) => _rows('triggers').where((row) => row['group_name'] == _groups[index]).toList();

const _accents = ['blue', 'green', 'orange', 'yellow'];

List<Map<String, dynamic>> _rows(String key) => [
  for (final row in moodRecordingCatalog[key] as List)
    Map<String, dynamic>.from(row as Map),
];

ThemeData _theme(bool dark, int accent, bool contrast) {
  final base = AppTheme.withAccent(
    dark ? AppTheme.dark : AppTheme.light,
    AppColors.brandPalette[accent],
  );
  return contrast ? AppTheme.highContrast(base) : base;
}

double _ratio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
}

void main() {
  setUp(
    () => installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    ),
  );
  tearDown(resetLocalTestFonts);

  Future<void> mount(
    WidgetTester tester,
    Widget child,
    ThemeData theme, {
    bool contrast = false,
    double scale = 1,
    Size size = const Size(375, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: appearanceMediaQuery(
            MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            highContrast: contrast,
            reduceMotion: true,
          ),
          child: LiveAppearanceTheme(
            theme: Theme.of(context),
            child: RepaintBoundary(
              key: const ValueKey('capture'),
              child: child!,
            ),
          ),
        ),
        home: child,
      ),
    );
    await settleMoodReviewImages(tester);
    expect(tester.takeException(), isNull);
  }

  Widget inventory({bool complete = false}) => Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Original Home characters'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final mood in _moods) MoodArtwork(mood: mood, size: 40),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Cause artwork · selected / unselected'),
            for (var group = 0; group < 6; group++) ...[
              const SizedBox(height: 8),
              RecordingChoices(
                options: complete
                    ? _causeGroup(group)
                    : _causeGroup(group).take(2).toList(),
                selected: {_causeGroup(group).first['name'] as String},
                collection: 'triggers',
                category: group,
                onToggle: (_) {},
              ),
            ],
            const SizedBox(height: 20),
            const Text('Coping artwork'),
            const SizedBox(height: 8),
            RecordingChoices(
              options: complete
                  ? _rows('coping')
                  : _rows('coping').take(4).toList(),
              selected: {'Journaling'},
              collection: 'coping',
              onToggle: (_) {},
            ),
            const SizedBox(height: 20),
            RecordingAction(label: 'Continue', onPressed: () {}),
            const SizedBox(height: 8),
            RecordingAction(
              label: 'See past entries',
              outlined: true,
              onPressed: () {},
            ),
          ],
        ),
      ),
    ),
  );

  test('all 82 bundled cause/coping masks exist and are distinct', () {
    expect(_rows('triggers'), hasLength(48));
    expect(_rows('coping'), hasLength(34));
    for (final key in ['triggers', 'coping']) {
      final paths = {
        for (final row in _rows(key))
          'assets/png/recording_mask_${key}_${row['slug']}.png',
      };
      expect(paths, hasLength(_rows(key).length));
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });

  for (final dark in [false, true]) {
    for (var accent = 0; accent < 4; accent++) {
      for (final contrast in [false, true]) {
        final name =
            '${dark ? 'dark' : 'light'}-${_accents[accent]}-${contrast ? 'contrast' : 'standard'}';
        testWidgets('artwork matrix $name', (tester) async {
          final theme = _theme(dark, accent, contrast);
          await mount(tester, inventory(), theme, contrast: contrast);
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          expect(
            images,
            hasLength(22),
          ); // six characters, twelve causes, four coping.
          for (final image in images.take(6)) {
            expect(image.color, isNull);
            expect(
              _moods.map(MoodArtwork.assetFor),
              contains((image.image as AssetImage).assetName),
            );
          }
          if (!_baseline) {
            final inks = theme.extension<CozyColors>()!.recording.categoryInks;
            for (var group = 0; group < 6; group++) {
              for (final image in images.skip(6 + group * 2).take(2)) {
                expect(
                  image.color,
                  inks[group],
                  reason: 'Category $group must retain its colour',
                );
              }
            }
            for (final image in images.skip(18)) {
              expect(image.color, inks[2]);
            }
            for (final choice in tester.widgetList<RecordingChoice>(
              find.byType(RecordingChoice),
            )) {
              final box = tester.widget<Container>(
                find.byKey(
                  ValueKey('recording-${choice.collection}-${choice.slug}'),
                ),
              );
              final decoration = box.decoration! as BoxDecoration;
              if (choice.selected) {
                expect(
                  _ratio(
                    (decoration.border! as Border).top.color,
                    decoration.color!,
                  ),
                  greaterThanOrEqualTo(3),
                );
              }
              if (choice.category == 2) {
                expect(
                  _ratio(inks[2], decoration.color!),
                  greaterThanOrEqualTo(3),
                );
              }
            }
            // Functional secondary labels must remain readable even with yellow accents.
            final label = tester.widget<Text>(find.text('See past entries'));
            expect(
              _ratio(label.style!.color!, theme.colorScheme.surface),
              greaterThanOrEqualTo(4.5),
            );
          }
          await captureMoodReview(tester, '$_prefix-$name-inventory');
          await tester.pumpWidget(const SizedBox.shrink());

          final flow = MoodRecordingController(
            entry: _entry(),
            drafts: MemoryMoodDrafts(),
            repository: MemoryMoodRepository(),
            wellness: MemoryMoodCatalog(),
            accountScope: () => 'visibility',
            accountChanges: const Stream.empty(),
          );
          addTearDown(flow.dispose);
          await mount(
            tester,
            MoodFeelingScreen(controller: flow),
            theme,
            contrast: contrast,
            size: const Size(375, 812),
          );
          for (final stage in ['intensity', 'causes', 'coping', 'review']) {
            flow.next();
            await tester.pumpAndSettle();
            await captureMoodReview(tester, '$_prefix-$name-$stage');
            expect(tester.takeException(), isNull, reason: stage);
            if (!_baseline) {
              for (final text in tester.widgetList<Text>(find.byType(Text))) {
                if (text.data == 'Edit' ||
                    (text.data?.startsWith('See all') ?? false)) {
                  expect(
                    _ratio(text.style!.color!, theme.colorScheme.surface),
                    greaterThanOrEqualTo(4.5),
                  );
                }
              }
            }
            if (stage == 'coping') {
              await tester.tap(find.byKey(const ValueKey('coping-see-all')));
              await tester.pumpAndSettle();
              expect(
                find.descendant(
                  of: find.byType(CopingResponseSheet),
                  matching: find.byType(RecordingChoice),
                ),
                findsNWidgets(34),
              );
              await captureMoodReview(tester, '$_prefix-$name-responses');
              await tester.tap(
                find.byKey(const ValueKey('coping-sheet-close')),
              );
              await tester.pumpAndSettle();
              expect(flow.state.coping, {'Journaling'});
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await mount(
            tester,
            MoodCheckInSuccessScreen(entry: _entry()),
            theme,
            contrast: contrast,
            size: const Size(375, 812),
          );
          await captureMoodReview(tester, '$_prefix-$name-saved');
          expect(find.text('Entry saved.'), findsOneWidget);
        });
      }
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'high contrast check-in and keyboard at 320px / 200% dark=$dark',
      (tester) async {
        final flow = MoodRecordingController(
          entry: _entry(),
          drafts: MemoryMoodDrafts(),
          repository: MemoryMoodRepository(),
          wellness: MemoryMoodCatalog(),
          accountScope: () => 'visibility',
          accountChanges: const Stream.empty(),
        );
        addTearDown(flow.dispose);
        await mount(
          tester,
          MoodFeelingScreen(controller: flow),
          _theme(dark, 3, true),
          contrast: true,
          scale: 2,
          size: const Size(320, 812),
        );
        for (final stage in ['intensity', 'causes', 'coping', 'review']) {
          flow.next();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: stage);
          await captureMoodReview(
            tester,
            '$_prefix-stress-${dark ? 'dark' : 'light'}-$stage',
          );
          if (stage == 'coping') {
            await tester.ensureVisible(
              find.byKey(const ValueKey('coping-see-all')),
            );
            await tester.tap(find.byKey(const ValueKey('coping-see-all')));
            await tester.pumpAndSettle();
            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
            addTearDown(tester.view.resetViewInsets);
            await tester.enterText(
              find.byKey(const ValueKey('coping-search')),
              'water',
            );
            await tester.pumpAndSettle();
            expect(find.text('Drinking water'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await captureMoodReview(
              tester,
              '$_prefix-stress-${dark ? 'dark' : 'light'}-keyboard',
            );
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('coping-sheet-close')));
            await tester.pumpAndSettle();
          }
        }
      },
    );

    testWidgets('complete icon inventory and large text dark=$dark', (
      tester,
    ) async {
      await mount(
        tester,
        inventory(complete: true),
        _theme(dark, 3, true),
        contrast: true,
        size: const Size(375, 4200),
      );
      expect(find.byType(Image), findsNWidgets(88));
      await captureMoodReview(
        tester,
        '$_prefix-${dark ? 'dark' : 'light'}-all-icons',
      );
      await mount(
        tester,
        inventory(complete: true),
        _theme(dark, 3, true),
        contrast: true,
        scale: 2,
        size: const Size(320, 812),
      );
      expect(find.byType(RecordingChoice), findsNWidgets(82));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'System theme and live preferences preserve an open coping search and pending choices',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final preferences = ValueNotifier(false);
      addTearDown(preferences.dispose);
      final flow = MoodRecordingController(
        entry: _entry(),
        drafts: MemoryMoodDrafts(),
        repository: MemoryMoodRepository(),
        wellness: MemoryMoodCatalog(),
        accountScope: () => 'visibility',
        accountChanges: const Stream.empty(),
      );
      addTearDown(flow.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: preferences,
          builder: (context, contrast, _) => MaterialApp(
            theme: _theme(false, contrast ? 3 : 0, contrast),
            darkTheme: _theme(true, contrast ? 3 : 0, contrast),
            themeMode: ThemeMode.system,
            themeAnimationDuration: Duration.zero,
            builder: (context, child) => MediaQuery(
              data: appearanceMediaQuery(
                MediaQuery.of(context),
                highContrast: contrast,
                reduceMotion: contrast,
              ),
              child: LiveAppearanceTheme(
                theme: Theme.of(context),
                child: child!,
              ),
            ),
            home: MoodFeelingScreen(controller: flow),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var step = 0; step < 3; step++) {
        flow.next();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('coping-see-all')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('coping-search')),
        'water',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('recording-hit-coping-drinking-water')),
      );
      await tester.pumpAndSettle();
      for (final dark in [true, false]) {
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        preferences.value = dark;
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(CopingResponseSheet));
        expect(
          Theme.of(context).brightness,
          dark ? Brightness.dark : Brightness.light,
        );
        expect(MediaQuery.highContrastOf(context), dark);
        expect(MediaQuery.disableAnimationsOf(context), dark);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('coping-search')))
              .controller!
              .text,
          'water',
        );
        expect(find.text('2 responses selected'), findsOneWidget);
        expect(flow.state.coping, {'Journaling'});
      }
      await tester.tap(find.byKey(const ValueKey('coping-sheet-apply')));
      await tester.pumpAndSettle();
      expect(flow.state.coping, {'Journaling', 'Drinking water'});
      expect(flow.state.causes, {'Deadlines'});
      expect(flow.state.intensity, 7);
      expect(flow.state.step, MoodRecordingStep.coping);
      expect(tester.takeException(), isNull);
    },
  );
}
