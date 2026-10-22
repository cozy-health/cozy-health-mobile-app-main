# Approved Home and Feeling implementation

Date: 2026-10-22. Baseline: `992dbb4`. The owner approved the Home and Feeling
concepts, including light/dark/high-contrast treatment, and then requested
implementation. Following review of the rendered corrections, the owner requested
the Home and mood changes be committed on 2026-10-22. Activity and Provider
designs are a separate review phase. Publishing this commit is not part of this step.

## Home

The reference's hierarchy is implemented: profile/notifications, crisis action,
theme-tinted check-in with a three-by-two category grid, yellow daily reminder, seven-day
rhythm, matching theme-tinted suggested reset, journal/assessment pair and the closing message.
The existing bottom navigation, floating shortcuts, routing, feature-tour keys,
notification focus, guest/offline/restore indicators and refresh path remain.

The header wraps the actual full profile name. Original journal/brain artwork is
reused. Affirmations retain their controller, loading/error/retry behaviour,
freshness label and detail destination. The compact Home presentation alone uses
the reminder design. Suggestions retain the existing preference rules and prompt
destinations; additional suggestions expand inline. General breathing content is
clearly labelled when no personalised suggestion exists.

The rhythm covers the last seven local calendar dates ending today. It chooses
the latest entry for each day, displays original category artwork when available,
uses a saved marker for legacy entries without a character, and a dash otherwise.
Local entries can establish that today is recorded before the dashboard flag
refreshes. The seven date cells are read-only status indicators. Detailed entries and
statistics are accessible through existing Log
and Insights destinations. No catalog, API, stored record or schema is changed.

## Feeling

Home and Feeling share one `MoodCategoryGrid` backed by the six original Home
character assets. Home shortcuts open the corresponding category without choosing
a feeling. The detailed screen displays one category's text-only feeling choices
at a time, with an explicit selected checkmark and persistent Continue action.
All 72 bundled feelings remain accessible; server-provided choices within the
existing categories are read from the same live catalog.

Browsing categories changes presentation state only. An existing answer remains
named in the footer until another feeling is chosen. Direct entry without an
answer requests a category; drafts and Review edits open the saved category.
Resuming an Angry draft from a Sad Home shortcut correctly restores Angry.
The underlying controller, five steps, intensity mapping, transactional edits,
draft migration, retry/account guards and saved receipt are unchanged.

This explicitly replaces the earlier decision to preserve the old long Feeling
list; the owner clarified the scope and approved this new selection design.

## Themes and motion

Scoped wellness tokens are accessed through `CozyColors`. Home and Feeling use a
warm light canvas and neutral dark canvas. Check-in, breathing and today's rhythm
marker derive an opaque tint from the live user accent and current surface.
The reminder retains its separate yellow/amber role. All six original vector
characters were re-exported with complete bounds and balanced visible body area,
preserving their native proportions, details, colours and transparent shadows.
Controls use the existing user accent and
readable foreground fallback. High contrast adds stronger opaque boundaries and
explicit selection indicators. Body text on Home's semantic fills uses onSurface.

The shared press feedback is retained. Home's entrance and category transitions
are short (180ms); the category crossfade remains interruptible. Outgoing choices
are excluded from touch and semantics. Reduced motion disables these transitions
and retains immediate feedback. The first size-animation approach was replaced
after a reduced-motion render exposed a layout assertion; the crossfade is tested
under rapid category changes and both motion preferences.

Cards grow with text, category/choice grids reduce columns, feature cards stack,
and the seven rhythm dates wrap when required. Continue remains pinned outside
the scrollable choices. Existing bottom controls have scroll clearance.

## Approved correction pass

The owner approved the additional Home and Feeling correction list before edits.

- Both floating controls are circular with matching elevation and spacing. Crisis idle pulse/glow is removed; tap and long-press actions remain. Review exports enable real shadow rendering and restore the test binding setting afterwards, eliminating the black debug elevation outlines.
- Mood log and insights use equal outlined actions; they stack for large text. The breathing action is centred within its 48px hit area. Feature illustrations have extra top space, headings share a measured row height, and paired card actions align. Bottom clearance derives from floating control dimensions.
- Category selection uses a border and subtle fill without a tick. Faces remain centred in padded canvases. The latest artwork pass re-exports all six original vector characters to matching 384px square canvases. Body area is normalised while preserving aspect ratios; every declared body-shadow filter fits within its crop. Sad's previous crop ended at x157 although its body extends to x159.2069. Both that cut and the uneven Upset padding are corrected.
- Feeling choices reserve the checkmark slot and border space. A footer hint reserves space before selection; selection scrolls into view after layout, including when the summary wraps at large text sizes.
- Navigation measures full labels and scrolls horizontally only when required; changing the selected tab reveals it. Text scaling is preserved. Progress, navigation labels and keyboard focus use contrast-aware foregrounds, and focus paints over opaque controls.
- Shared motion handling includes app preference, Android disableAnimations, accessible navigation, and iOS accessibilityFeatures.reduceMotion.

## Review artifacts and validation

- [Corrected screenshot gallery](../build/mood-selection-review/theme-artwork-index.html)
- [Home, light, full content](../build/mood-selection-review/theme-artwork-final-home-light-blue-standard-full.png)
- [Feeling, light](../build/mood-selection-review/theme-artwork-final-feeling-light-blue-standard.png)
- [Source artwork bounds, normalisation and export hashes](design/mood-artwork-export.json)

These are actual Flutter widget renders using Outfit and synthetic local-date data,
not generated images or physical-device screenshots. The gallery includes all 16
light/dark, four-accent and contrast combinations, plus 320px/200% text captures
of Home top, middle and bottom and Feeling before/after selection.

The correction regression run passed 78 checks, including five-step save/edit flows,
all 72 feelings, draft recovery, accessibility, appearance and feature motion.
A separate keyboard-focus regression passed. The final footer/motion render run passed 20 checks; the subsequent navigation/theme run passed 19 checks. Scoped analysis passed all 15 changed Dart files, with clean follow-up analysis for the final footer, navigation and test edits. Android build results are recorded in the corrected-* logs beside the gallery.

No physical-device/emulator or iOS runtime acceptance was performed. No commit
or push was made. Unrelated work in this shared workspace was preserved.

## Theme and artwork follow-up

The owner requested that check-in and breathing backgrounds follow the selected
accent, with a yellow reminder retained. The shared accentPanel token now derives
from the live ColorScheme, using a subtle opaque tint over the current surface.
All four accents retain readable text in both brightness and contrast modes.
Original face colours stay independent of the selected accent.

The original SVG was sufficient to recover the complete Sad character, so no
generated replacement was needed. tool/export_mood_artwork.cjs exports original
paths/gradients/filters, removes card backgrounds and labels, and normalises body
area on matching square canvases. At 48px Home scale, equivalent body area is
28x28px; the tall Upset and wide Sad retain their natural proportions. Both
character grids share these assets and have no redundant outer image padding.

The follow-up matrix passed 21 checks, including all 16 theme combinations,
320px/200% text layouts, pixel-level clear gutters and balanced body areas, and
actual Home card colours. See theme-artwork-* logs for regression/analysis results.
The previous APK predates this follow-up; these previews are Flutter widget renders.
Changes remain local for visual review.

The follow-up functional run passed 44 checks. The real-font visual comparison
identified changes only inside the mood-character rectangles (0.38-0.69% of
affected screenshots). Ten baselines were updated for the restored artwork; the
two response-sheet baselines stayed identical. All twelve real-font scenes then
passed comparison in light and dark mode. Final theme renders use a fresh
theme-artwork-final prefix so open older image previews do not lock their output
files on Windows.

Final follow-up verification: all seven changed Dart files passed analysis with
no issues. Final rendering passed eighteen theme/large-text cases, and all gallery
image links resolve. No commit or push was performed.

## Home spacing correction

The owner requested a tighter and more balanced Home. Breathing and journal
suggestions are now whole-card actions with unchanged destinations and prompt
arguments. The nested 48px action row is removed; the card itself remains a large
touch target. Card spacing uses 8px label/title, 4px title/body and 12px body/action
gaps with consistent 16px insets. Expanded suggestions keep separate large cards.

Home section gaps are consistently 20px. Eyebrow type matches across check-in,
reminder and reset cards. The profile now has a 48px keyboard/touch target, weekday
cells reserve equal border space, and feature-card body/action gaps are tighter.
The duplicate 24px end spacer is removed; calculated floating-control clearance
remains, and the closing message uses quieter centred body-small type.

See [Home spacing review](../build/mood-selection-review/home-balance-index.html)
for all themes, large-text views and a before/after comparison. The first combined
verification passed 26 checks. Final action and footer-clearance runs are recorded
in home-balance-*-final.log; scoped analysis passed all seven changed Dart files.
No commit or push was performed. The previous APK predates these spacing edits.

Final spacing verification: all 26 initial checks passed, the four action tests
passed separately, and both footer-clearance cases passed with clean teardown.
The isolated fixture cleanup race was resolved by awaiting preferencesBox() in
setup and detaching the live widget tree before closing Hive; no retry or ignored
cleanup error remains. Final fixture analysis passed, and all 72 gallery image
links resolve.
