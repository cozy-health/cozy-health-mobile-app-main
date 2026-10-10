# Compact main action dock

The main screen used a vertical crisis/quick-action button stack on phones at least 700 logical pixels tall. Its 56px buttons, 16px gap and 16px outer padding consumed 160px of vertical space above the navigation bar, leaving a large blank panel and shortening every tab's visible content.

Both controls now share a horizontal row with 8px vertical padding. The dock consumes 72px, returning 88px to tall-phone content. Each button remains 56px with a 16px horizontal gap, outside the content bounds. Tap, long-press, quick-action sheets, tour targets and keyboard hiding remain wired as before.

Regression tests check all five tabs in light/dark mode at 320×568, 667×375 and 430×932, with large text. They verify the 72px reservation, disjoint controls and content, and navigation spacing. The targeted UI suite passed all 73 tests.

The supplied iPhone screenshot was inspected. No physical iPhone was connected for a post-change device capture; validation uses Flutter widget rendering.

The same delivery also contains the first Phase 16 batch: paginated saved-content reads, existing cache-merge guards and saved-article account restoration. The backend requires the corresponding authenticated saved-content endpoint. Phase 16 and the broader app audit remain incomplete.
