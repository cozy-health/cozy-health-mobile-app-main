# Push notifications and iPhone testing

## Current implementation

Firebase's resolved native packages require iOS 15. The project and CocoaPods deployment targets now use 15.0. Both iOS workflows use the macOS 15 runner and Xcode 26.2 to meet the current Firebase toolchain requirement. See [Firebase Apple SDK release notes](https://firebase.google.com/support/release-notes/ios) and [GitHub's runner image inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md).

Settings → Notifications exposes explicit consent, four optional reminder categories, times/weekdays, quiet hours, OS permission and delivery status. The soft prompt enables mood; other categories require selection. Declining waits 14 days before another automatic soft prompt. Phone Settings handles OS denial.

Phone permission is now checked independently of Firebase. In internal builds, use **Enable phone alerts** to request the iPhone notification permission even before Firebase is configured. Status distinguishes Not requested, Allowed, Denied and Permission check unavailable. After denial, the action opens phone Settings. Allowing phone alerts does not mean the installation can receive remote push.

The backend controls the three-per-day allowance, two-hour spacing and quiet-hour deferrals. The app does not schedule duplicate local reminders. Foreground arrivals use the existing banner. Background and terminated taps use the same supported destination map. Journal compose reuses the existing save and crisis-support flow; Home focuses the streak or affirmation card. Unknown types open the inbox.

FCM registration requires an authenticated account, explicit consent and OS permission. Logout cleanup uses securely stored, registration-specific revocation credentials and the API's pinned transport. It does not retain the old account's full login credential. Late registration results from another account session are revoked. Missing Firebase configuration or APNs support never blocks startup.

## Firebase setup

Create separate development and production projects. Register the current identifiers:

- Android: `com.example.cozy_health`
- iOS: `com.example.cozyHealth`

Keep these identifiers consistent with the platform projects; changing them is a separate migration.

Add GitHub repository secret `FIREBASE_OPTIONS_JSON` for the development project:

```json
{
  "android": {
    "apiKey": "FROM_FIREBASE",
    "appId": "ANDROID_FIREBASE_APP_ID",
    "messagingSenderId": "PROJECT_NUMBER",
    "projectId": "PROJECT_ID"
  },
  "ios": {
    "apiKey": "FROM_FIREBASE",
    "appId": "IOS_FIREBASE_APP_ID",
    "messagingSenderId": "PROJECT_NUMBER",
    "projectId": "PROJECT_ID",
    "iosBundleId": "com.example.cozyHealth"
  }
}
```

These are client configuration values, not a service-account private key. Never place backend credentials here. `tool/prepare_push_config.py` prepares Dart defines and the iOS Firebase plist; on macOS it adds the plist to the Xcode resource phase. Programmatic Firebase options initialize Android without requiring a Google Services Gradle plugin.

The existing Android and unsigned iOS workflows consume the secret. Missing configuration produces a usable app with push marked unavailable. For local builds, generate `push-defines.json` from the same environment variable, then pass `--dart-define-from-file=push-defines.json` to Flutter. The generated file and native configuration are ignored by Git.

## Your current iPhone workflow

Use the existing **Build iOS Internal Test IPA** action and sideload its unsigned IPA as before. It explicitly sets `IOS_PUSH_ENABLED=false` and keeps the current sideload entitlements. Firebase permission alone does not mean the build can register with APNs.

Under Settings → Notifications, internal builds expose four simulation rows. Tap a row to show its banner; use **Open** to exercise routing. Simulations never send an external message, write a real inbox record or consume allowance. Production builds omit these controls.

The simulation rows are near the top of the screen and work regardless of phone permission, reminder consent or Firebase setup. Tap the row or its **Simulate** button to show an in-app banner; only tapping the banner opens the destination. Simulations do not appear in the phone's notification centre or lock screen.

Login now opens Home without a restore page. Downloads run through one account-scoped background coordinator, merge into cached records, and stop on logout/account switching. Home shows a small sync status; partial failures remain retryable. Failed sections are persisted and retried on app resume/reconnect, with at most three automatic retries before a manual retry is needed. New-account registration keeps its onboarding flow.

Verify startup, status reporting, banners, destinations, journal saving, quiet-hour controls and persistence. These are app tests, not proof of remote iPhone delivery.

## Later signed push test build

When Apple Developer access is available, enable Push Notifications and the existing Sign in with Apple capability for the App ID. Upload an APNs authentication key to Firebase. Register the iPhone and create an Ad Hoc distribution profile with the push entitlement.

The manual **Build Signed iPhone Push Test IPA** workflow requires:

- `FIREBASE_OPTIONS_JSON`
- `APPLE_TEAM_ID`
- `IOS_CERTIFICATE_P12_BASE64` and `IOS_CERTIFICATE_PASSWORD`
- `IOS_PUSH_PROFILE_BASE64`

The profile must match the current bundle ID, contain the test device, and carry the production APNs entitlement. The workflow validates the profile, builds with `IOS_PUSH_ENABLED=true`, exports a signed IPA and verifies its signature and entitlement. Install that IPA without resigning it through a free-account profile, which could remove push support.

Keep backend `PUSH_IOS_ENABLED=false` until real delivery passes. No local Mac or Xcode is required: the GitHub runner provides both. This workflow has not been run with signing credentials yet.

## Acceptance checklist

Local verification on 2026-10-12: full Flutter suite 552 passed, one skipped; final notification/core regression suite 170 passed, one skipped; Android debug APK built. All three workflow YAML files parsed successfully. No GitHub iOS execution or device delivery is claimed.

- Android: real foreground/background/terminated delivery, permissions, taps, disabled categories and quiet-hour deferrals.
- Current sideloaded iPhone: startup without APNs, honest delivery status, simulations, journal save and settings persistence.
- Later signed iPhone: APNs/FCM tokens, real foreground/background/terminated delivery, taps, permission denial and silent mode.
- Backend configuration and real MySQL concurrency must be verified before broad rollout.
