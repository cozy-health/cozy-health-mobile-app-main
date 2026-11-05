# Voice recording and provider sharing acceptance

Development-only completion of temporary preview playback, synced-file fallback,
and explicit sharing of saved voice journals with connected providers. No
transcription or external audio export. API contract and storage details live in
the API repository's `docs/voice-recording.md`.

## Automated evidence

- Reproduced temporary preview rejection and HTTP 422 for saved voice sharing
  before the fixes. Logs: workspace `output/voice-preview-baseline.log` and
  `output/voice-sharing-baseline.log`.
- Focused mobile checks: 24 passed, including preview file/session isolation,
  missing-local-file fallback, authorization rechecks, send retry and explicit
  recipient/audio confirmation. `output/voice-mobile-final-focused.log`.
- API audio/sharing regression: 22 passed / 229 assertions.
  `output/voice-api-regression.log`.
- Dashboard: strict typecheck, 59 unit tests and build passed. Real Chromium
  fixtures passed recording/preview/send retry, private byte-range bridging,
  shared voice review at 320px, replay denial after withdrawal, and existing
  written-share review/withdrawal in both themes. Workspace logs:
  `output/voice-dashboard-browser-verified.log`,
  `output/voice-written-sharing-browser.log`.
- Full application checks and exact development commits/CI links are recorded
  in the workspace `docs/HANDOFF.md` when the batch finishes. Focused tests do
  not establish native build or physical-device success.

## iPhone acceptance (owner help)

Use the development build for the recorded commit and development endpoints.
Do not use a production/store release for this checklist.

1. Deny microphone access, retry, then grant it through Settings. Record a short
   journal, stop, play/pause/seek the preview, rerecord and discard once.
2. Record again, save, reopen it, terminate/reopen the app, and play the saved
   journal. Save another recording offline; verify it survives restart and
   syncs after reconnecting without duplicates.
3. Confirm that a synced recording remains playable when its local copy is
   unavailable. Use a development test account/device reset to exercise remote
   download; do not manually delete real user data.
4. Choose a connected provider with journal consent, review the provider name
   and audio, then confirm sharing. Check dashboard playback and a subsequent
   private journal-title edit; the shared copy keeps the original title/audio.
5. Withdraw the copy. Check that refreshing/replaying it in the dashboard is
   denied. Repeat access removal through journal consent and relationship
   revocation using synthetic test accounts.
6. Send voice messages in both directions. Check failed-send retry, background
   stop, account switch/logout, and a recording reaching the five-minute limit.
7. Check controls with enlarged text and VoiceOver. Record the installed build,
   iOS version and failures; do not mark this checklist passed without results.

No deployment or physical-device success is claimed by this document.
