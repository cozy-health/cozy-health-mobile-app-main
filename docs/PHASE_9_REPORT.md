# Phase 9 — Offline UX and new-device restore

## Result and commit grouping

Both sub-phases are grouped into one mobile commit: `feat(offline): connection restored UX and new-device restore`.
Phase 9 is committed locally and is not pushed. The backend is unchanged. DEFERRED.md was only updated with the three explicitly requested Phase 8 rows before Phase 9 work.

## Phase 8 push and CI

Pushed mobile develop through `f6c74a7` (all four Phase 8 commits).

- Android Debug APK: passed — https://github.com/cozy-health/cozy-health-mobile-app-main/actions/runs/37777289043
- iOS unsigned IPA: failed — https://github.com/cozy-health/cozy-health-mobile-app-main/actions/runs/37777288760
- iOS compiler diagnostic: `Value of type 'SentryBinaryImageCache' has no member 'image'`, in `sentry_flutter-8.14.2/.../SentryFlutterPlugin.swift:265`. This native build failure remains unresolved; Flutter analyzer and widget/unit tests do not validate an Xcode build.

The root tracker `C:/projects/cozyhealth/docs/DEFERRED.md` now includes Sentry DSN, user_settings backend sync, and real-device biometric verification.

## 9.1 — Offline UX

- Persistent 40px cloud-off banner below the status bar, with the requested copy. A 300ms easeOutCubic transition becomes instant under reduce motion/accessibility navigation.
- One reconnect notification after three stable seconds online. Rapid connection flips cancel the pending notification. Reconnect requests an immediate queue retry.
- Optional reconnect sound uses existing just_audio and connectivity_plus. audio_session is now a direct dependency for iOS ambient/Android notification audio policy. It respects the app mute preference, guards missing/invalid/long assets, and avoids changing an existing journal audio session.
- Home shows an account-scoped `N pending` badge. Its sheet lists data types without exposing record IDs, notes or journal/chat contents, and offers Retry sync with an inline loading state.
- Mood, journal and profile save notices read the actual pending queue: `Saved` after acknowledgement, otherwise `Saved locally — will sync when online`.
- Queue results count explicit acknowledgements. Success, partial failure and total failure have separate notices; failed notices offer retry. Malformed responses retain queued changes. Repeated failures no longer delete queued work after ten attempts.
- Home, mood history, journal, notifications, quiz history and saved articles render Hive records immediately and refresh in the background. Offline empty list states provide a retry. Existing API-derived dashboard/insights cache handling is preserved.
- Background downloads use the same conflict merge as restore instead of overwriting pending local edits.

### Sound asset

`assets/sounds/connection_restored.mp3` does not exist. Playback is silent and safe until it is supplied. `assets/sounds/README.md` documents the warm, at-most-two-second sound, Freesound source suggestion and license/attribution requirements. `pubspec.yaml` declares the directory; no synthetic audio or invalid MP3 placeholder was created.

### Files created for 9.1

- `lib/core/models/sync_summary.dart`
- `lib/core/services/network_status.dart`
- `lib/core/services/connection_sound.dart`
- `lib/core/widgets/network_observer.dart`
- `lib/core/widgets/sync_queue_badge.dart`
- `assets/sounds/README.md`
- `test/features/offline/offline_ux_test.dart`

### Files modified for 9.1

- `lib/main.dart` (observer in MaterialApp.builder, with theme and ScaffoldMessenger available)
- `pubspec.yaml`, `pubspec.lock`
- `lib/core/services/local_db_service.dart` (queue summaries, retry retention, pending streams; also shared with 9.2)
- `lib/core/widgets/app_snackbar.dart`, `lib/core/widgets/empty_state.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/mood_check_in/presentation/screens/mood_feeling_screen.dart`
- `lib/features/journal/presentation/screens/journal_screen.dart`
- `lib/features/notifications/presentation/screens/notifications_screen.dart`
- `lib/features/quiz/presentation/screen/quiz_history_screen.dart`
- `lib/features/content/presentation/screens/saved_articles_screen.dart`
- `lib/features/settings/presentation/screens/edit_profile_screen.dart`

## 9.2 — New-device restore

- Email, Google, Apple, biometric and stored-session startup check the current account's local history before Home. Existing local history or a completed per-account restore skips the blocking restore screen. New registration has no older backup to restore.
- The restore screen shows progress, distinct item count, cancellation, failures with Retry, and an option to continue with the successfully restored data. Partial continuation retains an incomplete marker so a later login can retry.
- Fetches follow the requested ten-domain order. Mood and journal history use 50-item pagination and initially download the most recent 90 days. Quiz attempts, notification read state and conversation metadata are also paginated. Conversation messages remain lazy.
- Successful sets survive later failures. Retry fetches failed sets only, including refetching the profile source if preferences parsing previously failed. Repeated pages do not double-count items.
- Unknown totals are not invented when an endpoint fails: the partial UI reports the actual restored count and failed sets, rather than claiming an unverified `45 of 50` total.
- Cancellation clears the session and returns to login. Late responses are rejected after cancellation or account changes; already cached items remain available to resume.
- Offline startup retains cached data. Session expiration signs out without deleting pending local work. The old splash behavior that cleared local data after any validation failure was removed.

### Backend endpoints used

All paths below are relative to `/api/v1`.

| Domain | Endpoint / source | Status |
|---|---|---|
| User profile | GET `/user/profile` | Used |
| User preferences | `preferences` in GET `/user/profile` | Used; no separate endpoint needed |
| Safety plan | GET `/safety-plan` | Used; 404 means no plan |
| Emergency contacts | Safety plan `people` | Embedded contacts restored; standalone GET `/emergency-contacts` is missing |
| Mood entries | GET `/mood-entries?page=N&per_page=50` | Used; initial 90 days |
| Journal entries | GET `/journal-entries?page=N&per_page=50` | Used; initial 90 days |
| Quiz attempts | GET `/quiz-attempts?page=N&per_page=50` | Used |
| Saved articles | Existing mobile path `/content/saved` | Missing from backend routes; reported, not added |
| Notifications | GET `/notifications?page=N&per_page=50` | Used; read state retained |
| Conversation metadata | GET `/conversations?page=N&per_page=50` | Used; messages not downloaded |
| Upload queue | POST `/sync/batch` | Existing endpoint, unchanged |

Missing domains are visibly reported on restore and recorded locally. They are separate from transient fetch failures; existing local bookmarks/contacts are preserved. No full-download backend endpoint or other backend change was added.

### Conflict handling and account isolation

Last-write-wins uses `client_updated_at`, with existing domain/server timestamps as fallbacks. Newer server records replace older local versions and obsolete queued edits. Newer local versions stay local and gain an upload intent if needed. Equal timestamps retain pending local edits. Draft journals and pending delete tombstones are preserved, and entries absent from the download are never removed. Newer onboarding preferences similarly retain/queue their local version.

Profile UUIDs are distinct from auth user IDs. Auth placeholders cannot override canonical server profiles; the current profile is selected by a stored pointer instead of the first historical snapshot in Hive.

Hive data, settings, preferences and queues now use per-account namespaces. Account changes pause sync and wait for the previous batch, preserve each account's files, rebind cache streams and reject downloads for a different owner. Existing unscoped data is copied once to the verified matching account; sources are preserved. Logout uses a separate guest workspace, rather than clearing unsynced personal data.

### Files created for 9.2

- `lib/core/services/restore_service.dart`
- `lib/core/services/user_data_merge.dart`
- `lib/features/auth/presentation/screens/restore_screen.dart`
- `test/features/auth/restore_flow_test.dart`

### Files modified for 9.2

- `lib/core/routing/app_router.dart`
- `lib/core/services/local_db_service.dart` (shared with 9.1)
- `lib/core/services/user_data_fetcher.dart`
- `lib/core/services/install_marker_service.dart`
- `lib/core/repositories/mood_repository.dart`
- `lib/core/repositories/journal_repository.dart`
- `lib/features/settings/data/profile_repository.dart`
- `lib/features/assistant/data/chat_repository.dart`
- `lib/features/insights/presentation/widgets/local_insights.dart`
- `lib/features/auth/data/auth_service.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/widgets/google_auth_button.dart`
- `lib/features/auth/presentation/widgets/apple_auth_button.dart`
- `lib/features/splash/presentation/screens/splash_screen.dart`
- `test/features/auth/google_auth_test.dart`, `test/features/auth/apple_auth_test.dart` (account-scoped cache assertions)

## Verification

- 9.1 targeted offline tests: 14 passed.
- New restore tests: 26, including fresh/existing device decisions, pagination/cutoff, partial continuation/retry, progress, cancellation, account switches, profile placeholders, preference sync IDs, server/local conflicts, drafts and tombstones, and UI navigation.
- Previously failing auth/profile/startup tests: 69 passed after fixes.
- Final `flutter analyze lib`: **zero issues**.
- Final `flutter test`: **220 passed**, all original 180 plus 40 new tests.
- No native device, reconnect sound playback, or live new-device restore test was performed. Those require the missing audio asset/device; the endpoint audit used backend source and restore tests used isolated temporary Hive boxes with deterministic API responses.

## Commit

One combined commit, reported in the accompanying completion message. Phase 9 was not pushed.