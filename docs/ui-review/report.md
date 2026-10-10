# Cozy Health UI fixes

## Home overflow

Real paths:

- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/home/presentation/widgets/cozy_calendar.dart` (new extraction)
- `lib/features/home/presentation/widgets/journaling_card.dart` (new extraction)

Both cards determine their height from content. No fixed-height wrapper or maximum-height constraint remains around either card. SizedBox heights in Cozy Calendar are spacing, and the journaling illustration remains 80 x 80. The existing footer carousel remains content-sized.

Home scroll content has top padding 16 and bottom padding 140 plus the device safe inset. Padding belongs to the scrollable content so the viewport remains usable. Existing bottom navigation and the Fix 1 dedicated button row are retained.

Calendar shows title, subtitle, Monday-Sunday check-in dots, live streak/average, Recent entries, up to three entry rows, and View Log. Empty data has an invitation rather than fabricated average intensity. Dots, streak, recent entries, and View Log are wired to existing destinations.

Journaling shows the SVG illustration, title/description, Start Writing, existing affirmation footer and three page dots. It uses the existing paired sage colors through the theme extension.

## Themes and screen polish

Theme: `lib/core/theme/app_theme.dart`; new extension: `lib/core/theme/cozy_colors.dart`. Existing light/dark palettes and profile/system theme selection remain in place. Existing main app system-bar styling remains in place. Surface, text and chart colors were adapted where visibility required it. Colored artwork, transparent backgrounds, and appropriate white foregrounds on colored actions remain intentionally explicit.

Home mood chips scroll and preselect check-in moods. Good/Sad/Angry use existing mood SVGs; the other moods retain emoji. Home name/initial/avatar come from the existing profile repository. Assistant/Settings were excluded, so no new identity code was added there.

The shared connectivity observer renders one dismissible/animated offline banner, with Retry and session dismissal. Recovery and queue/sound behavior retain existing tests. There is no duplicate Home warning.

Community retains header Create and the existing post/group menu. Its topics scroll, post previews expand through Read more/detail, likes/comments work in the existing session preview, and long-press actions copy or hide/report/block locally. Anonymous cards use `?`. Real-mode empty feeds remain empty; fixtures appear only in demo mode.

Activity recommendation cards, chart labels, period controls, Insights labels/chart, Content cards/actions and Community composer/comments were adjusted for enlarged text and landscape. Journal swipe delete offers Undo. Journal Detail shows linked mood/intensity when present and exposes the existing edit/delete flow.

## Serving screens

Existing screens were reused rather than duplicated:

| Requested screen | Actual implementation |
|---|---|
| Create Post | `lib/features/community/presentation/screens/create_post_screen.dart` |
| Post Detail | `lib/features/community/presentation/screens/post_detail_screen.dart` |
| Comments | New `lib/features/community/presentation/screens/comments_screen.dart`, sharing the existing post thread |
| Content Detail | `lib/features/content/presentation/screens/article_detail_screen.dart` |
| Journal Detail | Existing `JournalEntryDetailScreen` inside `journal_screen.dart` |
| Notification Detail | `lib/features/notifications/presentation/screens/notification_detail_screen.dart` |
| Quiz Results | Existing `quiz_result_screen.dart` / `quiz_result_content.dart`; clinical results/scoring preserved |

Parents reach these through existing routes or the shared Comments destination. Static/local details keep appropriate unavailable/empty states; existing repository screens retain their loading/error states. No fake remote loading or successful remote Community publication is implied.

## SVG audit

See [complete SVG inventory](svg-inventory.md): 162 source SVGs were found across the workspace, excluding generated output/dependencies.

| Reference | Purpose and use |
|---|---|
| `assets/svg/journaling.svg`, 132 x 131 | Existing illustration rendered at 80 x 80 in JournalingCard |
| `assets/svg/good.svg`, `sad.svg`, `angry.svg` | Existing mood faces used in Home chips |
| `assets/svg/home.svg`, 24 x 24 | Navigation icon, not a full Home design |
| `cozyhealth mobilescreen figma/Home.svg`, `Home-1.svg`, 375 x 812 | Full Home mockups; sections rebuilt with native interactive widgets, existing Outfit typography and spacing |
| `cozyhealth mobilescreen figma/cozy calendar*.svg`, 375 x 1357 | Detailed calendar/activity screen references, not a single reusable Home card |

No separate dark Home/calendar design or standalone named flame SVG was found. Native widgets use theme variants. Existing flutter_svg dependency and asset declarations already cover the used assets; no dependency changes were necessary. No exact pixel-match claim is made for full-screen mockups.

## Demo data

New `lib/core/data/placeholder_data.dart` and `demo_mode.dart` provide 8 posts, 5 journals, 14 mood entries, 6 notifications, 6 articles and sample Activity metrics. Demo records and edits stay in memory and never enter account storage or the sync queue. Repository flags can override demo selection; normal builds default to real data.

Enable a review build with `--dart-define=COZY_DEMO=true`. A Privacy toggle was not added because Settings sub-screens are explicitly excluded. The existing Low mood remains available alongside the eight requested Home moods; existing check-in and crisis features were preserved.

## Arrangement checklist

The checks below describe implementation and automated evidence; physical-device visual verification remains pending.

| Screen | Arrangement |
|---|---|
| Home | ✅ single offline warning; ✅ profile greeting; ✅ crisis link; ✅ mood heading/chips; ✅ quiz card; ✅ full calendar; ✅ full journaling/footer; ✅ existing navigation/button row |
| Activity | ✅ title/calendar action; ✅ all period tabs; ✅ mood chart/legend; ✅ trend/streak; ✅ General insights; ✅ check-in calendar/View log; ✅ Writing dots; ✅ trigger bars/impact; ✅ recommendations; ✅ existing navigation/button row |
| Community | ✅ search; ✅ scrolling filters; ✅ General Posts; ✅ header Create; ✅ feed/empty state; ✅ Crisis access and no global quick-action button |
| Journal | ✅ title/new entry; ✅ entry list/empty state; ✅ detail; ✅ swipe delete/Undo |
| Mood Check-In | ✅ requested Home moods preselect; ✅ existing intensity/note/save/cancel/success; ✅ existing extended flow retained |
| Quiz | ✅ existing question/progress/answers/Next/Back/results/retake tests; ✅ Quiz History headings use the existing theme-aware headlineMedium style |
| Content | ✅ category/search; ✅ populated cards/details; ✅ empty states; ✅ save/copy-to-share |
| Insights | ✅ Weekly/Monthly selection; ✅ summary/chart; ✅ common triggers; ✅ recommended actions; ✅ View full report |
| Splash | ✅ centered logo/tagline/loading; ✅ existing destination; ✅ approximately two-second brand animation; ✅ both-theme layout tests |
| Notifications | ✅ rows/unread marker; ✅ Mark all as read; ✅ detail/read actions; ✅ empty state |

## Verification and waived gates

- Full analysis: **0 errors**, 11 existing warnings/infos outside this task. These comprise experimental/protected test APIs, three Auth test braces, two unnecessary test imports, a third-party const, and two relative imports plus print in the existing verification tool.
- Home-only analysis: **No issues found**.
- Full tests: **476 passed** (474 existing plus two Quiz History contrast checks).
- Dedicated layout/offline/interaction checks: **85 passed** (83 existing plus two heading contrast checks).
- Home layout tests: six cases covering 375 x 667, 412 x 892, and landscape in both themes, enlarged text, scroll reachability and button-row clearance.
- Android debug APK: final rebuild succeeded, exit 0. APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- iOS: local build gate waived by the user for this push. No iOS build attempted in this final step. Verification is delegated to `.github/workflows/build-ios.yml` on its macOS runner; GitHub CI is the source of truth for iOS.
- Physical-device verification: waived by the user for this push; the user will verify after push. Automated viewport tests are not a substitute for physical-device evidence, but are accepted for this push.
- Automated evidence covers both themes, enlarged text, portrait/landscape, Splash navigation, journal delete/undo, and Community actions.
- Quiz History: approved title-only change from `AppTextStyles.heading2` (black, `#FF000000`) to `Theme.of(context).textTheme.headlineMedium` (`#FF374151` light / `#FFF5F0E8` dark). Existing 20px / w600 Outfit typography is preserved. Quiz scoring, questions, navigation, results logic, and clinical interpretation are unchanged by this final patch.
- Existing quiz tests: **42 passed**. Two additional heading contrast checks require at least 4.5:1 in both themes.
- Commit/push authorized after required local checks pass; iOS and device waivers apply to this push.

Community remote publishing/moderation persistence remains an existing backend limitation. The clipboard share action does not open a native share sheet. See [testing guide](testing-guide.md) and [bug report template](bug-report-template.md).

Complete [files changed](files-changed.md) and [verification results](verification-results.md).
