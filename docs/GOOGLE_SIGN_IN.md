# Google Sign-In configuration (Phase 4c)

The login and create-account screens use google_sign_in 7.2.0, then POST the
ID token to `/api/v1/auth/google`. Successful sign-in saves the Sanctum token,
exits guest mode, caches/fetches the profile and starts the existing data sync.
Login respects Stay logged in; create-account persists the session. Navigation
uses the existing personalization completion check.

OAuth identifiers are public configuration, not secrets. Supply them at build time:

```powershell
flutter run --dart-define=GOOGLE_CLIENT_ID=<web-client-id> --dart-define=GOOGLE_IOS_CLIENT_ID=<ios-client-id> --dart-define=GOOGLE_ANDROID_CLIENT_ID=<android-client-id>
```

`GOOGLE_CLIENT_ID` is the web/server OAuth client ID for backend ID-token
authentication on both platforms. The Android OAuth client must be registered
with the app's package name and signing certificate SHA; its client ID is kept
in config for reference, but must **not** be passed as `serverClientId`.

For iOS, set `GOOGLE_REVERSED_CLIENT_ID` in `ios/Flutter/Google.xcconfig` to
the reversed **iOS** client ID (for example, `com.googleusercontent.apps.…`).
Info.plist uses this setting for the required callback URL scheme.
Debug, Release and Profile all include the setting. Set it together with the
Dart client IDs before device testing; IDs alone do not complete iOS setup.
The Apple capability and Apple SDK are unchanged in this commit.

With empty configuration, the button reports “Google Sign-In is not configured”
without invoking native sign-in. Cancellation is silent; SDK errors are
sanitized; backend errors are shown in a SnackBar. Google request bodies are
redacted from logs. No Google access token or refresh token is requested/stored.

Credential/device checks still required: registered package/bundle identifiers,
debug/release Android signing SHA, iOS callback scheme, server audience in
Railway GOOGLE_CLIENT_ID, successful login on both platforms, cancellation,
disabled account, and session persistence after restart.

Sources: [Google SDK](https://pub.dev/packages/google_sign_in),
[Android setup](https://pub.dev/packages/google_sign_in_android),
[iOS setup](https://pub.dev/packages/google_sign_in_ios).
