# Next-of-kin support

The heart button opens the user's primary next-of-kin contact. Settings exposes
the same setup and management screen. The old crisis routes remain supported;
the resources hub retains grounding, breathing, safety plans, and professional
help, with a next-of-kin action replacing service-number shortcuts.

## User flow

- Save a name, optional relationship, and international phone number beginning
  with `+` and a country code. No device-contacts permission is requested.
- Prepare a help message, review or edit it, then choose **Open Messages**.
  The user must press Send in their SMS app. Cozy Health cannot confirm sending,
  delivery, or whether anyone responded.
- Calling requires confirmation. Opening the phone app does not confirm a call.
- Canceling does not launch another app. Failed launches retain the message and
  expose retry, copy number, and copy message actions.
- Chat, journal, mood, and assessment prompts never send alerts automatically.
- This flow contacts a trusted person; it does not dispatch emergency assistance.

## Storage and rollout

Contact details use the existing encrypted, per-account Hive settings store.
Only contact changes enter the durable sync queue (`next_of_kin`, record
`primary`); help-message drafts stay in screen memory and are never queued.
Removals retain a timestamped tombstone, so a stale download cannot restore a
removed contact. No sample contact is automatically adopted.

Deploy the backend migration and authenticated `/next-of-kin` endpoints before
releasing the mobile build. Older backends leave contact synchronization pending;
the locally saved contact remains usable. Backend SMS credentials are not needed.
See the API repository's `docs/next-of-kin.md` for the wire contract.

## Verification

`flutter test --no-pub` includes next-of-kin widget, URI encoding, offline
persistence, account isolation, tombstone, and restoration checks. The existing
strict app-wide rendering audit includes the replacement contact screen.

For additional next-of-kin visual artifacts:

```text
flutter test --no-pub test/features/crisis/next_of_kin_test.dart --dart-define=SURFACE_SCREENSHOTS=true
```

Images are written to ignored `build/surface-review/next_of_kin_*.png`.

Before a device release, verify Android and iOS SMS and telephone handoff with a
controlled test contact, including cancellation, no compatible app, and SMS
unavailability. Automated tests mock external launchers and never send messages.

### Implementation verification (2026-10-15)

- Full Flutter suite: 640 passed, two intentionally skipped (opt-in live API
  smoke test and internal-build notification simulation).
- Flutter analysis: no errors or warnings; two pre-existing informational
  brace-style notices remain in unrelated files.
- Backend: 593 tests passed, including five next-of-kin API tests.
- Next-of-kin widget and external-launcher checks: 21 passed; 32 screenshots
  cover contact, message review, editing, and call confirmation across light/dark,
  normal/high-contrast, and portrait/landscape modes at large text sizes.
- Restoration, persistence, safety-plan preservation, and maintenance checks:
  44 passed; one internal-build notification simulation intentionally skipped.
- App-wide rendering: 430 checks passed in each of normal and high-contrast
  runs, with zero collected rendering errors. These use the local Outfit font
  (`--dart-define=SURFACE_REAL_FONTS=true`) to match the app's actual typography.
- Android debug APK compiled. Physical Android/iOS SMS handoff remains untested.
