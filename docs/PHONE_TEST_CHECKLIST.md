# Internal sideload: real-phone acceptance checklist

Use this as a result sheet for the reliability repair build. This is test evidence, not a claim that the entire app or release plan is complete. Mark each item PASS, FAIL, or BLOCKED and add a screenshot/video reference.

## 1. Record the build and preserve existing data

- [ ] Record phone model, OS version, app version/build, commit SHA and GitHub Actions run. The artifact includes `build-info.json`; Settings > About shows installed build information.
- [ ] Download the artifact for the intended commit from the mobile repository's Actions page, not an older successful run. Android: `android-debug-apk-…` containing `app-debug.apk`. Standard iOS: `ios-internal-test-ipa-…` containing `Runner-unsigned.ipa`, which requires your sideload signing method. Signed push iOS: manually run **Build Signed iPhone Push Test IPA**, if its signing/Firebase secrets and device provisioning are configured.
- [ ] **Before updating, capture the current pending badge and its detail screen. Do not uninstall, clear app data, or delete queued records to remove the badge.** Those actions can destroy the evidence and unsynced data we need.
- [ ] Install over the existing app with the same application identity/signing where supported. If installation requires uninstalling, stop and report the signing/installation error before removing data.
- [ ] Confirm normal mode: no `COZY_DEMO=true`. Record API environment and whether the matching backend/dashboard revisions are deployed.
- [ ] Backend prerequisites: the four October 18 migrations for affirmation reads, regional prices, achievement awards and reactions must be applied. The API's existing container startup runs migrations; verify its deployment/migration logs. A Git push alone does not prove a healthy deployment.
- [ ] Do not test account deletion, paid purchases, or real crisis contact calls as routine checks. Use disposable test accounts and synthetic entries for new tests.

## 2. Highest priority: identify the original two pending records

- [ ] While signed into the affected account, open the pending badge **before pressing Retry**. Screenshot each operation's label, type/action, operation ID, retries, safe error, creation time and next retry.
- [ ] Tap **Copy sync diagnostics (no saved content)** and save the text with the time and connection state. This is available in debug and `INTERNAL_TEST_BUILD` sideload builds; production release builds hide it.
- [ ] With internet available, press Retry once. Record the result, remaining count and elapsed time. Copy diagnostics again if items remain.
- [ ] Leave the app open for a few minutes, then background/resume it and toggle connectivity once. Check whether counts and retry times change sensibly, without repeated success banners or repeated identical error prompts.
- [ ] Report whether the original two items succeeded, remained queued, or changed to a different count. Include their safe error codes. Do not assume that a new affirmation-read/settings operation is one of the original two.
- [ ] If the badge is already gone, record that fact and the last time it was visible; do not invent a cause. Diagnostics reset when switching accounts, so capture them before logout.

## 3. Logout and owner isolation

- [ ] With the original pending items still present if possible, turn on airplane mode and log out. Record elapsed time. The app should promptly show the logged-out/welcome screen without waiting for upload or server logout.
- [ ] Back navigation must not reveal protected account screens. Force-close and reopen: remain logged out.
- [ ] Sign into test account B: account A's mood/journal/chat, settings, achievements, blocked users and pending records must not appear.
- [ ] Sign back into A: its unsynced records must still be available only to A. Restore internet and retry; count decreases only for successful operations.
- [ ] Repeat logout while a retry is starting on a weak connection. Repeated taps must not hang the app or restore the previous session when a delayed response arrives.
- [ ] Repeat ordinary online logout. No surprise re-login, repeated toast, or request spinner should block exit.

## 4. Create and recover offline changes

- [ ] On a disposable account, create one mood and one journal entry offline. Reopen both, force-close/reopen, and confirm the entries and pending operations remain.
- [ ] Reconnect and retry once. Confirm one durable copy of each entry, no duplicate uploads, correct eventual pending count, and an honest manual-sync result.
- [ ] Retry while offline: preserve entries and show a useful failure, without a fake success. Repeated connectivity changes should not bypass retry backoff automatically.
- [ ] Change reminder/privacy preferences offline, restart and reconnect. Confirm saved values and eventual sync. A pending preference or affirmation-read acknowledgement can legitimately add an operation.

## 5. Affirmation presentation, acknowledgement and notifications

- [ ] Home has a clear affirmation card; tapping it opens the full affirmation. Home/detail agree and there is no invented replacement on refresh.
- [ ] Assignment keeps the existing rolling 24-hour behavior; a calendar midnight alone must not incorrectly force a different assignment.
- [ ] Merely seeing the compact Home card must not mark the full affirmation as read. Open the detail while foregrounded, then check that its read acknowledgement syncs (or remains queued offline).
- [ ] Background/resume the detail: no repeated pending-read duplicates. Verify an acknowledgement cannot be applied to another account after logout.
- [ ] Save reminder time/days and notification preferences, restart, and confirm they persist. Verify allow/deny/re-enable notification permission states; document the phone's timezone and app account timezone.
- [ ] On a day the full affirmation was not read, verify the eligible daily reminder arrives. Read it before the scheduled reminder on another day: that day's reminder should be suppressed once the read reaches the server. Offline unsynced reads cannot suppress a server send immediately.
- [ ] Tap a real affirmation notification in foreground, background and terminated states: open the full affirmation. Test a local-day boundary/timezone change and report duplicates or missed acknowledgements.
- [ ] Respect quiet hours and existing shared notification caps/spacing; use the configured eligible time rather than assuming every scheduled send is immediate. In-app Simulate is navigation testing only, not proof of remote delivery.
- [ ] **Standard unsigned iOS build sets `IOS_PUSH_ENABLED=false`: remote iPhone delivery is BLOCKED on that build.** Use the signed push workflow with valid APNs entitlement, registered provisioning, Firebase/server push configuration and a live scheduler/worker to assess remote delivery. Android also needs valid Firebase/server configuration. Do not interpret missing prerequisites as a completed delivery test.

## 6. Repaired screens and enabled actions

- [ ] Mood: each mood opens the correct feelings; causes, intensity, coping and review retain choices. Back/resume a draft and submit once. Verify no overflow on the actual phone.
- [ ] Monthly report: previous/next changes the real period; future months are disabled; figures match known entries. Copy and share produce the selected month's device summary. Cancel sharing safely. This is text, not a PDF.
- [ ] Profile: actual joined date when available; recent entries opens history. Achievements show first mood/journal and 3/7/30-day progress with earned dates. On a disposable account, earned milestones remain after relevant entry deletion and restart. Journal drafts alone must not earn the journal milestone; long streak tests need genuine history or controlled fixtures.
- [ ] Assistant history: saved conversations remain after restart, correct date sections, opening loads messages, delete remains deleted after retry/restore/relogin. Test export share/cancel, saved preferences and confirmed clear. Device export/clear are not a promise of a complete cloud archive/clear. Normal-mode send/retry must explain unavailable AI and retain the draft; scripted replies must not appear as real AI.
- [ ] Crisis completion: Better returns Home; Same opens follow-up. Verify navigation without making real calls or contacting anyone.
- [ ] Feedback/problem: online text report succeeds and is visible in authorized support storage/admin; offline failure retains draft. Attachments are explicitly unavailable.
- [ ] Email: displays registered identity; resend/code verification uses a real accepted request; invalid code shows an error. Phone/email change and 2FA must not claim completion or generate fake recovery codes.
- [ ] Privacy/language/integrations: values survive restart/account switches; English is the implemented language; no invented connected apps or crash-report consent.
- [ ] Data export/download/status: share a nonempty readable device JSON file, cancel safely, confirm the scope excludes cloud-only records/audio. No fake emailed archive or cloud job status.
- [ ] Legal/About: published terms/privacy show actual configured version/text, drafts/unavailable documents are labelled; licenses open; build identity is correct; rating must not pretend to open an unconfigured store.

## 7. Community (only when launch configuration is enabled)

- [ ] With approved guidelines/release readiness/feature flag enabled, load real feed and pagination. If disabled, expect a truthful unavailable state with safe retry.
- [ ] Publish with actual guidelines acceptance; check anonymous/public behavior, reload persistence and moderation pending state. Failed submission retains the draft; followers-only posting is unavailable.
- [ ] Open comments, send/reply, like/unlike repeatedly, and reopen. Counts and state must match the server. Report a post/comment and verify an actual moderation record; failures must not say received.
- [ ] Open a public author's profile: real non-anonymous public posts only; no sample biography/counts. Anonymous author identity must not be exposed.
- [ ] Block a disposable user; their content disappears. Blocked-users settings shows owned records; unblock persists. Recheck with another account and after restart.
- [ ] List/join/leave real groups and reload. Creation, following, private messages/requests, search, featured curation and image moderation currently explain unavailability; do not count these as implemented services.
- [ ] Patient moderation screen must not show sample reports or allow administrative actions. Authorized moderation remains in the separate administrator workspace.

## 8. Regional pricing and dashboard checks

- [ ] Confirm NG: Free NGN 0/month, Student NGN 5,000/month, Premium NGN 10,000/month. Annual paid totals NGN 48,000 and NGN 96,000 (20% saving), with Student/Premium sharing paid benefits.
- [ ] Confirm an unsupported country: show unavailable prices, not a silent NG fallback. Retry loading and change country without stale response overwriting the latest choice.
- [ ] No fake trial, paid activation, receipt, invoice, purchase restoration or cancellation success. Payments/student verification are deferred.
- [ ] Optional admin browser check: regional country/currency/precision/prices/discount/benefits/availability save correctly; annual preview agrees; audit records exist; concurrent edits reject stale changes. Provider billing is labelled preview and shows no invented charge/invoice. This requires the matching dashboard/API deployment, not only the phone APK/IPA.

## 9. Phone usability and return report

- [ ] Check light/dark mode, larger text, narrow screen, keyboard, scrolling, back gestures and rotation on changed screens. Enabled buttons should have an observable result; unavailable actions should explain why.
- [ ] Send: build SHA/run, phone/OS, API revision if known, test account alias (not credentials), PASS/FAIL/BLOCKED list, exact steps, expected/actual result, time/timezone, connection state, screenshots/video and before/after sync diagnostics.
- [ ] Prioritize these results: original pending operations, offline logout timing, account isolation, same-owner data retention, retry outcome and real affirmation notification behavior. Redact personal health text, tokens, email addresses and other people's data.

Copy for each failure:

```text
Build / phone / OS:
Screen and button:
Account alias / timezone / connection:
Steps:
Expected:
Actual (include elapsed time and pending count):
Evidence / safe error code:
```
