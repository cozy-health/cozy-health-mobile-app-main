# Approved popup and journal-sharing UI

Development implementation only. Assistant server functionality and stored records remain intact for future work; no assistant screen is reachable from normal app navigation. The legacy assistant link opens Provider.

## Implemented flows

- Home Actions uses a labelled grid control, descriptive action text and distinct face, book, care-conversation and wind icons. Support and Actions stack with the existing spacing so larger text cannot make them overlap.
- Journal creation offers Write freely, Write with a prompt and Record a voice note. Entry actions use edit, tag, share and delete icons with explanations.
- Add a tag, microphone preparation/permission/error notices, recording-save failures, offline-save notices, provider-connection notices and journal-sharing-off notices are centred. Recording remains a bottom sheet.
- The existing optional tour is a centred introduction. Account creation now uses an explicit centred ready-to-begin confirmation. The identity gate presents its existing authentication form centrally without revealing locked content. Recorder feature information is a centred dialog.
- Breathing retains its real four-cycle timer engine, explicit start, pause/resume, background pause and restart behavior. Remaining time, current cycle and phase countdown are visible; phase text can grow without overflowing its visual container.

## Journal sharing

Only saved written entries can be shared. The app selects one connected provider, checks journal-sharing permission, syncs and compares the server's title/text with the saved local entry, displays a full-page preview, and requires explicit confirmation. Audio is excluded. Later edits are private.

The existing preview, create, read and revoke journal-share endpoints are used. The server revision is opaque; retries retain the same client confirmation ID. Conflicts require a fresh review. No placeholder success or fabricated provider is shown.

Shared copies can be opened online from Provider messages and withdrawn after confirmation. Full text is kept out of conversation caches. Preview and review surfaces close on account changes; written review also closes when the app backgrounds. Shared confirmation dialogs are session-scoped.

The provider dashboard provides explicit online review, discards text on close/blur, refreshes access from the server and clears earlier text if refresh fails or access is withdrawn. It does not save journal text to browser storage.

## Verification

Use Flutter 3.44.6 and the workflow commands: flutter analyze --no-fatal-infos --no-fatal-warnings; flutter test --dart-define=INTERNAL_TEST_BUILD=true. Android and iOS development workflows validate their native artifacts after a develop push.

The new sharing widget tests cover explicit confirmation, recipient selection, no audio payload, idempotent retries, revision conflicts, unsynced text, missing provider/permission notices, large text, withdrawal and account changes. Existing recording, breathing and navigation checks retain their behavioral assertions.

Actual phone installation, TalkBack/VoiceOver interaction and notification delivery remain separate device acceptance work. This document does not certify those checks.
