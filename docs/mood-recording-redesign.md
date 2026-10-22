# Mood recording redesign

> The [five-step implementation](mood-recording-five-step-implementation.md)
> supersedes the four-step/dialog behavior below. The remaining notes document
> the earlier catalog and artwork implementation.

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
- Visual captures: `build/mood-selection-review/`. The mood tests use the checked-in
  `test/golden_assets/Outfit.ttf` fixture with the font flag set. Production app
  themes are used for light, dark, and green-accent captures, with 44/34-pixel
  safe areas matching the reference device. System status/navigation indicators
  are intentionally outside the captured app content.
- Reviewed visual baselines live in `test/goldens/mood_recording/`. Run the Flutter
  command above without `--update-goldens` to check them. To propose replacements,
  run `flutter test --dart-define=SURFACE_REAL_FONTS=true --update-goldens test/mood_recording_flow_test.dart`
  and visually review every changed image before accepting it.

The recording screen uses `ColorScheme` for surfaces, controls, progress, and
slider. Reference category colors identify chip selections and illustrations;
`CozyColors.recordingCategoryFills` supplies paired light/dark fills. Default
light-mode labels and faint card borders follow the supplied artwork. High
contrast uses opaque theme colors and stronger borders. Supplied emojis retain
their appearance with transparent dark-mode crops; light-mode line artwork uses
the original category-colored assets, and dark-mode masks use lighter category
inks. Reference chip rows fit at 375px with adaptive gaps of 4-10px and may wrap
for narrow viewports and accessibility text sizes. Chips have a 28px visible
height inside separate 48px interaction areas; enlarged text expands both.
Appearance changes preserve state and update an already-open intensity dialog
through `LiveAppearanceTheme`.

Home uses the same six groups as the recording catalog: Angry, Sad, Good, Upset,
Spectacular, and Happy. Its transparent face assets were extracted at 3x from
the supplied `Frame 1000004108 (1).svg`. Home chips have a minimum 48px height
for reliable touch interaction.
Historical mood keys remain readable; no saved entries are rewritten.

The review folder includes an `index.html` gallery, three-column reference /
previous / updated comparison images, complete content overviews, per-category
captures, the production Home screen, intensity, review, and save success.
Content overviews crop unused space from tall Flutter test viewports and omit
the bottom navigation action. Ordinary viewport captures retain the action.
The duplicate Talking to a friend remains intentionally deduplicated.

Run visual regression checks with real fonts enabled; ordinary test runs alone
do not compare golden files. The mood layout test separately verifies every
reference row fits at 375px and checks the compact visual and interaction sizes.

Do not interpret the absence of a legacy note-entry screen as removal of saved
notes: they remain readable in entry details and retain the existing crisis check
when saved.
