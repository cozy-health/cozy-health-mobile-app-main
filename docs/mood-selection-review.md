# Mood selection reference correction

The supplied mood strip, feelings, causes, and coping artwork guided this change.
Home now presents Angry, Sad, Good, Upset, Spectacular, and Happy with consistent
faces extracted from the supplied SVG. Existing saved mood keys are unchanged.

Check-in chips use 28px visible surfaces and 22x20px artwork, inside separate
48px interaction rows. Text grows with device accessibility settings; rows wrap
instead of clipping. Per-row gaps adapt between 4 and 10px, preserving the
reference row composition at 375px. Category colors and subtle light-mode card
borders replace the old global-accent illustration tint and heavy outlines.
Selection outlines retain the category identity without covering the artwork.

## Review images

- [Screenshot gallery](../build/mood-selection-review/index.html)
- [Feelings: reference / previous / updated](../build/mood-selection-review/comparison-feelings.png)
- [Causes: reference / previous / updated](../build/mood-selection-review/comparison-causes.png)
- [Coping: reference / previous / updated](../build/mood-selection-review/comparison-coping.png)
- [Complete feelings](../build/mood-selection-review/overview-feelings.png)
- [Complete causes, selected](../build/mood-selection-review/overview-causes.png)
- [Complete coping](../build/mood-selection-review/overview-coping.png)
- [All six Home choices](../build/mood-selection-review/home-full-strip.png)
- [Production Home screen](../build/mood-selection-review/home-screen.png)
- [Intensity](../build/mood-selection-review/light-intensity.png)
- [Review](../build/mood-selection-review/light-review.png)
- [Resumed draft review](../build/mood-selection-review/resumed-draft-review.png)
- [Save success](../build/mood-selection-review/save-success.png)
- [Dark mode](../build/mood-selection-review/dark-feelings.png)
- [320px with 200% text](../build/mood-selection-review/large-text-320.0.png)

Images come from fresh Flutter widget renders with real Outfit fonts. The Home
screen uses demo data. System status indicators are outside captured app content.
The complete overviews crop unused space from tall test viewports, omitting the
bottom action; ordinary device-sized captures retain it. These are test renders,
not physical-device screenshots.

## Verification

Before the October 18 refinement, the full suite recorded **786 passed, 2 skipped**,
with no failures. Full Flutter
analysis reported **No issues found**. The UI integration suite also passed
all 82 tests with real fonts, and the normal-size production Home capture
passed independently after explicitly awaiting image decoding.

The focused mood/Home regression command passed 49 tests, including golden
comparisons without updating the baselines:

```powershell
flutter test --no-pub --dart-define=SURFACE_REAL_FONTS=true test/mood_recording_flow_test.dart test/mood_chips_visibility_test.dart test/mood_intensity_control_test.dart test/mood_expression_storage_test.dart test/mood_emoji_test.dart test/core/repositories/wellness_repository_test.dart test/core/repositories/mood_repository_test.dart test/features/home/home_figma_elements_test.dart
```

Coverage includes all six Home destinations; every reference chip row; normal
visual heights and non-overlapping interaction targets; feeling/intensity
confirmation and cancellation; multiple selections; navigation; draft resumption;
legacy data preservation; save failures; successful saves; 320/375/430px widths;
200% text; light, dark, high-contrast, and custom-accent themes.

All 27 golden images were visually reviewed and regenerated. Three intensity
baselines already differed before this change because the current dialog had
outgrown its old screenshot. The animated intensity dialog and existing flow
navigation are preserved. The repeated Talking to a friend reference item
remains intentionally represented by one catalog option.

No API or database changes are required.

## Design and UX refinement — 2026-10-18

- Kept the supplied artwork, compact chip surfaces, category colors, and reference
  row composition while increasing touch areas to at least 48px.
- Added a check badge and stronger selected outline without changing chip width,
  moving labels, or covering the artwork.
- Home choices clear their transient selection after returning from check-in;
  all six destinations have return-navigation and touch-target regression checks.
- Home shortcuts reveal the corresponding feelings category rather than always
  starting at Angry. Existing draft prompts retain priority; a shortcut does not
  confirm a specific feeling or enable Continue by itself.
- Intensity now has explicit Cancel and Done actions that wrap for enlarged text.
  Cancellation preserves the previously confirmed feeling and intensity.
- Optional causes and coping steps explain that multiple selections or none are
  valid. The bottom action grows with text rather than using a fixed height.
- Progress advances in four equal steps and announces the current step with a
  numeric progress value. The question is a screen-reader heading and saving has
  an accessible announcement.
- Final full suite: **791 passed, 2 skipped, no failures**, with real-font golden
  comparisons enabled and no baseline updates during verification. Flutter
  analysis and the final mood-screen analysis both passed.
- Review captures explicitly await image decoding, so isolated and full-suite
  runs compare complete artwork. All 27 visual baselines were inspected.
- An unrelated voice-recorder test now uses bounded pumps while its live timer
  is running, rather than waiting for an intentionally updating UI to settle.

The screenshot gallery at `build/mood-selection-review/index.html` includes a
six-screen overview, individual screens, all six Home choices, dark/custom-accent
themes, and large-text/high-contrast captures. Widget captures use demo data and
must not be described as physical-device screenshots.

`android-running-app.png` is a separate screenshot of the running Android demo
build on the Pixel 8 emulator. The debug APK built, installed, and launched
successfully; this does not establish physical-device or iOS acceptance.
