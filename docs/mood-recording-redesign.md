# Mood recording redesign

The recording flow is Feelings (with an intensity dialog), Causes, Coping,
and Review/save. References are the five PNG/SVG pairs in
`../cozyhealth mobilescreen figma/scren1 refix`.

## Release

Deploy the API changes and run `php artisan migrate --force` in the API release
environment before publishing the mobile build. The new migration adds cause
groups and replaces the active catalog with 6 feeling groups, 72 expressions,
48 causes, and 34 unique coping choices. Retired catalog rows remain stored but
inactive; no saved mood entries are rewritten. Back up the catalog before release
if administrators have customized it. The existing admin form now edits cause groups.

The mobile app bundles the same catalog for offline use and older servers. A
server catalog marked `mood_recording_version: 2` takes precedence, including
archived options. Do not edit the previously released catalog migrations.

## Compatibility

New entries use UUIDs. `mood` contains the group key; `expression_slug` contains
the specific feeling key. Legacy groups remain readable. Historical body, sleep,
energy, notes, and coping-helpfulness values survive editing and draft resumption.
Draft version 2 maps the old nine steps into the new four steps.

The dialog displays 1–5, defaulting to 3. Confirmed choices save as 2/4/6/8/10.
Historical intensity values are unchanged unless the dialog is confirmed.
Existing history and statistics continue to display the stored 1–10 scale.

Chip artwork was cropped from the supplied PNG exports using the matching SVG
icon coordinates. The repeated Talking to a friend option appears once.

## Checks

- Flutter: `flutter test --dart-define=SURFACE_REAL_FONTS=true test/mood_recording_flow_test.dart test/mood_expression_storage_test.dart test/mood_emoji_test.dart test/core/repositories/wellness_repository_test.dart test/core/repositories/mood_repository_test.dart`
- API: `php artisan test --filter="AdminManagementTest|MoodRecordingCatalogTest"`
- Visual captures: `build/mood-recording-review/`. The mood tests use the checked-in
  `test/golden_assets/Outfit.ttf` fixture with the font flag set. Production app
  themes are used for light, dark, and green-accent captures, with 44/34-pixel
  safe areas matching the reference device. System status/navigation indicators
  are intentionally outside the captured app content.
- Reviewed visual baselines live in `test/goldens/mood_recording/`. Run the Flutter
  command above without `--update-goldens` to check them. To propose replacements,
  run `flutter test --dart-define=SURFACE_REAL_FONTS=true --update-goldens test/mood_recording_flow_test.dart`
  and visually review every changed image before accepting it.

The recording screen uses `ColorScheme` for surfaces, text, controls, progress,
slider, and selected accents; `CozyColors.recordingCategoryFills` supplies paired
light/dark category fills. High contrast uses opaque theme colors and stronger
borders. Supplied emojis retain their appearance with transparent dark-mode
crops; line artwork uses alpha masks tinted from the live theme, with a readable
foreground fallback for low-contrast accents. Reference chip rows may wrap for
narrow viewports and accessibility text sizes. Appearance changes preserve state
and update an already-open intensity dialog through `LiveAppearanceTheme`.

Do not interpret the absence of a legacy note-entry screen as removal of saved
notes: they remain readable in entry details and retain the existing crisis check
when saved.
