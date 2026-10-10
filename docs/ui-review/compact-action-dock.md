# Floating main action controls

The main screen used a vertical crisis/quick-action button stack on phones at least 700 logical pixels tall. Its 56px buttons, 16px gap and 16px outer padding consumed 160px of vertical space above the navigation bar, leaving a large blank panel and shortening every tab's visible content.

The first correction used a compact 72px dock. The owner clarified that the controls must be overlays with no reserved row or panel. The main body now fills the entire available area up to the navigation bar. Two independently positioned buttons float at the lower right: quick actions 16px above the navigation bar, crisis above it with a 16px gap. Each button remains 56px. There is no container background or invisible dock hit area; the rest of the page remains visible and interactive beneath the controls. Tap, long-press, quick-action sheets, tour targets and keyboard hiding remain wired as before.

Regression tests check all five tabs in light/dark mode at 320×568, 667×375 and 430×932, with large text. They verify zero reserved dock height, full-height tab content, button placement over the page, non-overlapping buttons and navigation spacing.

The supplied iPhone screenshot was inspected. No physical iPhone was connected for a post-change device capture; validation uses Flutter widget rendering.

The same delivery also contains the first Phase 16 batch: paginated saved-content reads, existing cache-merge guards and saved-article account restoration. The backend requires the corresponding authenticated saved-content endpoint. Phase 16 and the broader app audit remain incomplete.
