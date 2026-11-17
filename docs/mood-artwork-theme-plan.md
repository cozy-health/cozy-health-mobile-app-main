# Mood artwork and theme visibility plan

Status: owner authorized implementation; completed changes and screenshot review
are documented in [theme verification](mood-artwork-theme-verification.md).
The owner reviewed the screenshots and authorized commit/push.
Baseline: `3890bea227c503e5771268980f5785a67f3be437`, pushed to `origin/develop`
on 2026-10-22. The rejected theme-specific revision is absent from this baseline.

## Outcome and design constraints

Keep the complete approved artwork and icon set recognizable and visible across
the user's appearance settings. Preserve the original six Home characters,
expressions, colours, asset mappings and relative visual prominence. Keep the
approved five-step flow and Saved receipt. Feeling selection remains outside
the redesign; include it only as a visual consistency reference.

Use the existing CozyColors/ColorScheme tokens and AppPressable. Apply the
Apple design skill's feedback, clarity and spatial consistency principles within
CozyHealth's own design system. Do not introduce a replacement icon pack.

The proposed default is to preserve cause/coping category colours too. Address
visibility through the surrounding surface, border, spacing or selection marker
first. If this cannot resolve a specific failure, present that example and ask
before changing the artwork or its colour treatment. Do not solve a theme
failure by hiding icons, removing choices or switching all icons to monochrome.

## 1. Capture and inventory before changing styling

- Capture the baseline with deterministic content and real app fonts.
- Inventory each mood character, cause/coping icon, intensity illustration,
  selection marker and Saved confirmation icon: source, mapping, size, tint,
  background, selected state and every screen that uses it.
- Cover Home, Intensity, Causes, Coping and its searchable sheet, Review, Saved,
  history, entry detail, calendar, linked journal mood and Home Insights detail.
- Confirm all six Home characters render. Verify all cause/coping choices and
  their icons against the current catalog, including expanded groups and search.
- Preserve historical labels and the previously approved text-only treatment for
  legacy moods without an original Home character. Missing images for a supported
  category are failures to investigate, not a reason to remove that category.

Deliverable: an inventory and annotated screenshots identifying actual failures,
their causes and affected settings. Distinguish an absent icon, an invisible
icon, clipping and a deliberate legacy text-only entry.

## 2. Check the real appearance combinations

Use production theme construction and persisted settings, not a parallel preview
palette. Check all 16 combinations of light/dark, four selectable brand accents
and high contrast on/off. Also verify System mode follows both device themes,
including a live switch with the check-in or coping sheet open.

Cover selected/unselected and enabled/disabled states. Stress layouts at 320px
and 200% text, a typical phone size, landscape and the sheet's open keyboard.
Verify reduced motion and state preservation when appearance changes. Use a
compact contact sheet for all combinations and full-size images for failures.

## 3. Present fixes for approval

For each confirmed failure, show baseline and proposed appearance side by side,
with the same content, viewport and selection. Include the full icon inventory
so a local improvement cannot conceal a missing option elsewhere.

Show how surface/border/selection changes keep the original artwork readable.
Check text contrast and meaningful control boundaries separately from decorative
illustration colours. Record exceptions rather than recolouring artwork to make
a numeric check pass. Await owner approval of the visual proposal before editing
production styling. Ask if a fix would affect Feeling selection or Home design.

## 4. Implement the approved scope

Make the smallest shared token/widget correction supported by the audit. Keep
category identity distinct from the user's accent for controls. Preserve state,
navigation, stored data, catalogs and the complete choice set. Avoid global theme
changes unless the audit demonstrates a shared problem and the owner approves
their wider visual effect.

## 5. Verify the result and submit for review

- Assert expected asset paths, image loading, icon presence and unchanged choice
  counts. Compare the original Home asset files to the baseline.
- Render the theme matrix and inspect it visually; presence-only assertions do
  not prove an icon is visible. Add focused regression coverage for each failure.
- Compare existing visual baselines before accepting changes. Do not regenerate
  all goldens simply to suppress a failure.
- Run mood flow/data regressions, appearance persistence/live-update checks,
  analysis and an Android build. Exercise a real device/emulator if available;
  otherwise explicitly label widget renders and leave device acceptance open.
- Deliver corrected screenshots, a concise change list and any remaining issues.
  Commit/push the future theme changes only after the owner's review approval.

## Open preference

For cause/coping icons, should category colours remain exactly as approved in
every theme, or may dark/high-contrast modes use lighter shades of the same
colours? Recommended starting point: preserve the approved colours and adjust
their surroundings. Original Home character assets remain unchanged either way.
