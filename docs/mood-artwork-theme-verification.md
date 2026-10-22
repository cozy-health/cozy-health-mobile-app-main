# Mood artwork theme visibility verification

Date: 2026-10-22. Baseline: `3890bea`. The owner reviewed the screenshots
and authorized committing and pushing this implementation.

## Findings and corrections

The baseline used the user's primary accent for blue-category cause/coping
illustrations and for every category in high contrast. Yellow therefore replaced
the original artwork colours and was faint on white. Secondary text actions
also used primary accents with insufficient text contrast. Blue icons on the
dark blue category fill had approximately 2.72:1 contrast.

- Illustration inks now always use the existing six category inks. All 48 cause
  and 34 coping masks are retained, with their original shapes and image sizes.
- Category fills remain preferred. Where a category fill makes an illustration
  faint, the existing neutral theme surface is used if it improves contrast.
  For blue in dark mode this increases contrast to approximately 3.13:1 while
  retaining the original blue ink. High contrast uses its existing surface.
- Functional selection borders/checkmarks use a readable foreground separately
  from illustration colour. They target 3:1 contrast against the card surface.
- Secondary text actions keep the user's accent when it meets 4.5:1; otherwise
  they use the theme's existing onSurface foreground. This covers See all, Edit,
  Skip, outlined actions and the Saved screen's past-entries link. Filled primary
  actions retain the selected user accent and its existing onPrimary foreground.
- Under bold-text preferences the redundant selection checkmark uses the existing
  16px token so short selected labels such as Journaling fit in compact cards.
  The separate cause/coping illustration remains 22px.
- Accent construction was moved unchanged from the private app method into
  `AppTheme.withAccent`, used by both the application and verification harness.
  There is no parallel preview palette and no global colour-scheme redesign.

Original Home character files match the baseline byte for byte. The Home selector
source and protected Feeling-selection helper block are unchanged. The Saved
confirmation check artwork is unchanged. No categories, choices, catalog rows,
stored entries, mappings, intensity values or navigation behaviour were removed
or rewritten. Historical moods without an approved Home character retain their
previously approved text-only treatment.

Illustration colours are not forced through the control/text contrast fallback.
These decorative images accompany explicit text labels; their identity is
preserved instead of turning every illustration into a monochrome control.

## Review artifacts

- [Before/after theme gallery](../build/mood-selection-review/visibility-index.html)
- [High-contrast yellow coping screen](../build/mood-selection-review/visibility-after-light-yellow-contrast-coping.png)
- [Dark coping response sheet](../build/mood-selection-review/visibility-after-dark-blue-standard-responses.png)
- [Complete icon inventory and asset hashes](../build/mood-selection-review/visibility-asset-inventory.json)

The gallery contains all 16 light/dark × four accents × high-contrast on/off
combinations. Each includes the icon inventory, Intensity, Causes, Coping,
searchable response sheet, Review and Saved. It also links the complete original
icon set and 320px / 200% text / high-contrast keyboard captures. Before images
were rendered from an isolated copy of the committed baseline using the same
fixture and exact production accent construction. Inventories follow the actual
catalog groups: Work 6, School 6, Relationship 8, Sleep 7, Health 12, Life changes 9.

These are Flutter widget renders with deterministic data and Outfit fonts, not
physical-device screenshots. No AI-generated mockups substitute for the app.

## Checks

- 26 final theme/saved-surface checks passed: complete asset inventory, all theme
  combinations, actual sheet counts, selected-state contrast, original character
  paths/untinted images, high contrast at 320px/200% with keyboard, and production
  history/detail/calendar/journal/Insights surfaces in light/dark and large text.
- System-mode live light/dark switching with the sheet open retained search,
  pending choices and committed answers, while accent, contrast and reduced
  motion updated. High-contrast text/marker refinement: 13 affected checks passed.
- 77 other mood/appearance regression checks passed. Four expected dark visual
  baseline differences were inspected before acceptance. Both visual tests then
  passed without updates, covering all 12 light/dark baseline images. Only
  dark Coping, Responses, Review and Saved baseline files changed.
- Original six Home asset hashes and the protected Feeling helper were checked
  against the committed baseline. All 277 gallery image/inventory links resolve.
- Full Flutter analysis and final scoped analysis reported no issues. The final
  Android debug APK built successfully. Results are recorded in `visibility-final-analyze.log` and
  `visibility-final-android-build.log` beside the review images.

No physical Android device/emulator or iOS runtime acceptance was performed.
Unrelated eligibility, billing, consent and documentation work remains local and
outside this change.
