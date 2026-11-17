# UI verification guide

Run commands from `cozy-health-mobile-app-main-main`. Follow `AGENTS.md`: Flutter and Dart commands use the installed SDK outside the sandbox.

## Automated checks

```powershell
flutter analyze
flutter analyze lib/features/home
flutter test
flutter build apk --debug
```

On macOS with Xcode:

```sh
flutter build ios --debug --no-codesign
```

The Home card regression tests use 375 x 667, 412 x 892, and 667 x 375 logical viewports in both themes with 1.6x text. These simulate layout constraints; they do not replace testing on iPhone SE and Pixel 7 Pro hardware.

`test/features/ui_review` checks the ten primary screens and their serving detail views in portrait and landscape, both themes, and enlarged text. Separate tests cover offline recovery/dismissal, demo isolation, journal swipe/undo, and Community navigation/reactions/comments. Existing clinical quiz tests cover submissions, scoring, cancellation, results, retake, and consent.

## Review data

```powershell
flutter run --dart-define=COZY_DEMO=true
```

Demo mode provides eight Community posts, five journals, fourteen mood entries, six notifications, six articles, and sample Activity metrics. Changes to those records stay in memory. Restarting the app resets the sample data. The build flag defaults off in normal builds. Authentication and existing quiz behavior remain in place.

Settings and its Privacy screen were excluded from this task, so there is no new Settings toggle. Do not label sample data as real account activity.

## Physical-device checks

Use iPhone SE and Pixel 7 Pro, normal and enlarged text, portrait and landscape. Toggle the operating system theme while the app is open and while navigating. Capture a screenshot and record device/OS/build for every failure.

| Screen | Check |
|---|---|
| Home | Scroll to the last footer above the Crisis/Quick Action row. Check all calendar sections, three recent entries, View Log, Start Writing, footer and page dots. All eight mood chips must be reachable and preselect the matching mood. |
| Home connectivity | Disconnect: one warning appears. Retry works. Dismiss hides it for this session. Reconnect: warning hides and queued changes retain the existing sync behavior. |
| Activity | Week/Month/3 Months/Year controls remain readable and tappable. Check current/previous chart legend, check-in dots, writing dots, trigger percentages/impact, and recommendation navigation. |
| Community | Header Create opens the existing post/group menu. Search and all topic chips work. Verify six-line previews, Read more, anonymous author, likes/comments, long-press Copy/Report/Block, empty feed, detail and comments navigation. |
| Journal | Check entry preview/date/tags, new entry, detail, linked mood/intensity when available, Edit, confirmed Delete, swipe deletion and Undo. Keep existing voice/guided/security behavior. |
| Mood Check-In | Verify Home mood preselection, all existing steps, added Sad/Tired/Excited choices, intensity, notes, cancel/save/success, and existing crisis handling. The original Low choice remains available. |
| Quiz | Verify questions, progress, answers, Next/Back, scoring/results/retake, support and consent. Verify clinical interpretation rather than replacing it with generic category scores. |
| Content | Category filtering/search, six demo cards with image/title/category/read time/preview, empty state, detail body, save and copy-to-share, related navigation. |
| Insights | Weekly/Monthly selection, summary, mood chart, common triggers, recommended journal/breathing actions and View full report. Check cached/offline/error states in normal mode. |
| Splash | Centered logo/tagline/loading indicator, readable themes, approximately two-second brand animation, existing session-aware destination. |
| Notifications | Title/body/time/icon/unread marker, detail navigation, Mark all as read, individual read state, dismissal and empty state. |
| Shared layout | Existing bottom navigation and Fix 1 button row remain accessible, including Community Create. Check keyboard visibility, safe areas and landscape. |

Community interactions still use the existing session-only preview store where no backend endpoint exists. Copy/share actions copy content to the clipboard; they do not claim remote publication or invoke a native share sheet.

For this push, the user waived the local iOS and physical-device gates. Commit/push requires analysis with 0 errors, passing full tests, and a successful Android debug APK build. iOS verification is delegated to GitHub CI on the macOS runner and CI is the source of truth. The user will perform physical-device checks after push. Automated viewport tests are accepted for this push but do not replace physical-device evidence. Community actions are accepted as session-local (no backend persistence). Demo Mode remains CLI-only; Settings sub-screens remain out of scope.
