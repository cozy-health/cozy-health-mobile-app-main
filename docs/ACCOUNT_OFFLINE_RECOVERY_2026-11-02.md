# Account separation and offline recovery ? 2 November 2026

## Scope

Development only. This delivery extends existing EncryptedHive account boxes, LocalDbService, TokenStorage session generations, repositories, UserDataMerge, RestoreController, SafetyPlanStorage and the existing sensitive-screen wrapper. It adds no second storage system, sync queue or authentication method. No API schema, server flags or production configuration changes are required.

## Repairs

- API calls capture their expected session when invoked, before asynchronous dispatch; an old write cannot acquire a newer account's credentials. Existing refresh/retry generation checks remain in use.
- Delayed mood, journal, profile, safety-plan and notification reads cannot return the next account's cache. Assessment-history reads also check their original account.
- Multi-step writes/deletes check account ownership between awaits. Local safety-plan, conversation/message cleanup and queue removal retain the original boxes.
- Clear-local-data captures all original account boxes before its first await; it cannot erase the next person's records or outbox.
- Preference saves retain their original stores and reuse write-first queue compaction instead of deleting the previous intent before creating its replacement.
- Restore merging retains original settings/preferences/queue references. A stale restore cancel cannot sign out a different/newer session.
- Safety-plan timers belong to their original account; cancellation/disposal settles waiting callers.
- Durable audio paths are checked against the account's own directory, including resolved paths. Another account's recording cannot be played, copied into its library or uploaded. Cleanup and cached playback recheck account ownership after filesystem awaits.
- Open playback stops and its controls disappear on logout/account changes. Existing recorder/session cleanup is retained.
- Existing sensitive-screen protection now removes old forms on session/account changes. Provider invitations, support/feedback, password and Student forms reuse it. Next-of-kin fields are cleared and old actions disabled. Public emergency resources remain accessible after logout.

## Verification coverage

Regression tests reproduce failures before repair: delayed cache fallback, stale restore cancellation, foreign recordings, open playback controls, cross-account cleanup, delayed safety-plan writes, pending cancellation, contact-form visibility, API dispatch and private-form visibility. The public emergency hub has a separate logout regression.

The saved-data matrix exercises moods, journals, journal drafts, mood drafts, stored conversations/messages, safety plans, profiles, preferences, assessment attempts, bookmarks, notifications, subscription cache, next-of-kin contact, provider-message cache and pending operations. It logs out, switches accounts, closes/reopens encrypted storage and verifies that the original owner's data/intents survive while the other account sees none of them.

Existing lifecycle, sync-diagnosis, offline-UX, provider-message/invitation, journal-sharing, token-race, consent and screen-capture tests remain part of validation. Failed provider sends retain their draft and retry identifier while the screen is open; provider sending remains online-only. Unsaved/unconfirmed recordings or form text are not promised to survive process termination. No new automatic message sending is introduced.

CI commands: Flutter analyzer with --no-fatal-infos --no-fatal-warnings, full Flutter tests with INTERNAL_TEST_BUILD=true, Android debug build and unsigned iOS release build with the existing development Firebase defines. The conditional API smoke is additionally enabled against api-dev.cozyhealth.org. Exact commit, completed jobs and artifacts must be recorded in the delivery report; a pending native job is not a pass.

## Remaining acceptance

Real Android/iPhone process termination, platform audio interruption, low-storage/keychain failure and legacy APK update continuity still need their final device/signing stages. Broader P01 multi-device/timezone/streak acceptance remains separate. Server backup/disaster recovery, support administration and store payments are not closed by this delivery. No claim of whole-app completion or physical-device verification is made.
