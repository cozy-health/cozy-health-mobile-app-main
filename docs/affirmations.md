# Shared rolling affirmations

Home and /daily-affirmation use one account-scoped AffirmationController and the
same AffirmationPanel. The Home card opens the detail screen; copying uses the
exact displayed text, and related articles retain their self-compassion route.
The three-entry hardcoded carousel and midnight timer have been removed.

The API assigns one catalog entry for 24 hours from assignment. When a user returns
after expiry, the server advances once and starts a fresh window. Its existing
30-entry catalog is unchanged. Backend migration and deployment MUST precede this
mobile release; see the API repository's docs/affirmations.md for the wire contract,
concurrency fixture, legacy compatibility, and release checks.

The new encrypted session-scoped cache key is affirmation_assignment_v1 and stores
id, body, assigned_at, and expires_at. Old date-keyed values are ignored. A valid
cache survives midnight/restart. Expired data remains available offline with the
label Last saved affirmation. No cache or a guest session shows General
encouragement, never an invented assigned selection. No active catalog entry is a
retryable empty state, not a 24-hour negative cache.

Visible Home/detail panels coalesce loads. Expiry and resume refresh the shared
state; failures and empty results retry every five minutes while a panel is active.
Inactive routes and backgrounding stop timers. Session clearing removes content
immediately; account activation waits for the completed token-change signal before
reading the new session cache. Late responses cannot cross that boundary. Internal
phone-notification simulations only read unexpired cached assignments; production
reminder schedules remain unchanged.

## Local verification

Run the affirmation_repository_test.dart and affirmation_flow_test.dart suites
under test/features/home, plus notification tests. They exercise a fake transport
against real encrypted cache, exact expiry, malformed responses, late HTTP replies,
shared-state expiry/retry/lifecycle, actual Home-to-detail navigation, clipboard
text, related articles, session transitions, and large-text light/dark layouts.
Optional SURFACE_SCREENSHOTS=true writes affirmation captures under ignored
build/surface-review. Full app tests, analysis, and an Android build are release
checks too.

## Device and release acceptance

After the backend is deployed, use a signed-in test account and record the mobile
build/commit and server assigned_at/expires_at. Home and detail must agree, including
after reopening, login, timezone changes, and viewing on a second device. A Friday
14:30 assignment is unchanged Saturday 14:29 and advances on the first request at
or after 14:30. Returning Monday advances only once, with a fresh 24-hour window.
Use a controlled staging clock/expired test fixture for the boundary check rather
than changing a production user's data or relying on a device clock change.

Verify valid/expired offline display, retry after reconnecting, clipboard contents,
related-article navigation, background/resume, guest mode, account switching during
a request, and large text on an actual iPhone. Windows widget tests do not establish
an iOS archive or physical-device pass. No production migration, deployment, commit,
or push is implied by this implementation.

## Verification results (2026-10-16)

- Full Flutter suite: 715 passed; one opt-in live API test skipped.
- Final targeted affirmation/notification suite after lifecycle and visibility
  cleanup: 39 passed, including all eight theme/contrast/orientation combinations.
- Sixteen readable layout captures regenerated and representative portrait and
  landscape images inspected with the production font/theme configuration.
- Android debug APK rebuilt successfully with the final implementation.
- Backend full suite: 630 passed, 4,463 assertions; affirmation subset: 17 passed,
  208 assertions. PHP syntax/Pint and concurrency-workflow YAML checks passed.
- MySQL concurrency execution remains pending: Docker Desktop's local daemon is
  unavailable. The disposable-database guard was exercised and refused an ordinary
  environment. SQLite results are not presented as proof of MySQL row locking.
- No iOS archive, physical-iPhone pass, live catalog check or production rollout
  was performed here.

Final targeted static analysis of all ten changed source/test files: no issues.
Full analysis had no errors or warnings; existing style notices outside this
change remain in hive_files_io.dart and repository_fixture.dart.
