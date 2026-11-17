# Mood artwork consistency audit

Date: 2026-10-22. The six existing `home_reference_*.png` assets are the approved
mood category characters. This correction does not redesign Home or the existing
feeling-selection UI.

## Inventory and correction

| Display | Source before this correction | Origin | Correction |
| --- | --- | --- | --- |
| Intensity, Causes and Coping summaries | Specific-feeling emoji PNG, with Unicode fallback | New check-in redesign | Shared Home category artwork |
| Review hero and Saved receipt | Same summary renderer | New check-in redesign | Shared Home category artwork |
| Mood history cards | `MoodEntry.emoji` text | Existing UI | Shared Home artwork; legacy labels have no icon slot |
| Mood entry detail | `MoodEntry.emoji` text | Existing UI | Shared Home artwork; legacy labels stay text-only |
| Calendar recent entries | `MoodEntry.emoji` text | Existing UI | Shared Home artwork; legacy entries have no leading icon |
| Journal linked mood | Emoji embedded in summary text | Existing UI | Shared Home artwork alongside unchanged feeling/intensity text |
| Home's Insights detail, “Most common” card | Emoji embedded in “Good” | Existing UI | Original Good character; existing summary value unchanged |
| Home mood selector | Original six Home image assets | Approved existing UI | Unchanged |
| Existing feeling-selection chips | Supplied expression artwork, including dark-mode emoji crops and custom-server fallback | Explicitly excluded from this change | Unchanged |

The search covered Flutter feature screens and shared widgets, direct emoji
getters, literal/escaped mood faces, image paths, asset fallbacks and sentiment
icons. Non-mood artwork such as streak flames, trophies, cause/coping icons and
the intensity preview is outside this correction.

## Shared rendering rule

`lib/core/widgets/mood_artwork.dart` is the presentation resolver and renderer.
It accepts a mood category and display size. Only Angry, Sad, Good, Upset,
Spectacular and Happy resolve, ignoring capitalization and surrounding whitespace.
The renderer has no expression parameter and applies no image tint or recolouring.

Specific feelings remain text labels: Resentful and Irritated both display the
Angry character. Unknown, blank and older categories such as calm, tired, okay,
low, anxious and excited do not acquire a guessed category. Their original label
remains and the artwork slot is omitted. An image-load failure never substitutes
an emoji or another mood.

No model, catalog, stored entry, API, schema, intensity or navigation changes were
made for this correction. Existing model emoji helpers remain for compatibility;
summary widgets no longer consume them.

The protected feeling-selection helper block had the same SHA-256 before and
after this correction:
`dc52b5f5a07104ff77732262e8c4e9a49871dc039b9dcb86dedee97df93d220a`.
The Home selector source and the original image files were not edited.

## Review and tests

- [Corrected screenshot gallery](../build/mood-selection-review/artwork-index.html)
- Check-in visual baselines: `test/goldens/mood_recording/v3/`.
- Shared widget tests cover all six asset paths, normalized category names,
  multiple feelings sharing one character, legacy label-only layout, missing
  image handling and decorative image semantics.
- A source regression check prevents emoji renderers from returning to feature
  summaries, with the protected feeling-selection code explicitly excepted.
- Production history, detail, calendar, journal and Home Insights detail screens
  are rendered in light/dark appearance at normal size and at 320px/200% text.
- Existing Home navigation/selection tests and check-in flow/data tests remain
  part of the regression checks.

Images are Flutter widget renders with synthetic data, not device screenshots.
Journal review captures load the existing Georgia body font from Windows when
available; no system font is copied into or added to the product.

The owner approved committing and pushing this restored baseline on 2026-10-22.
The subsequent theme-specific icon revision was rejected and reverted. Further
theme visibility work requires a separate review while preserving the approved
artwork and complete icon set.

## Verification results

- **61 relevant regression checks passed**, including controller/flow behavior,
  all six Home destinations, legacy storage compatibility, the shared artwork
  tests and real-font visual comparisons without updating baselines.
- **4 additional surface checks passed**, covering the six affected saved-entry
  displays in both themes at normal size and at 320px with 200% text.
- Twelve affected check-in baselines were regenerated and reviewed; updated
  renders and twelve additional saved-surface screenshots are in the gallery.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter build apk --debug --no-pub`: **passed**. The refreshed debug APK is
  `build/app/outputs/flutter-apk/app-debug.apk`.
- `git diff --check`: **passed**. No physical-device or iOS runtime acceptance
  was performed for this correction.

Logs live beside the review images: `artwork-regression-tests.log`,
`artwork-surfaces-tests.log`, `artwork-analyze.log` and
`artwork-android-build.log`.
