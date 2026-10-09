# Phase 12.1 — screen capture and logging protection

## Implementation

SecurityBlur registers sensitive content with ScreenCaptureService. Reference
counting keeps native protection active until the last protected screen leaves.
The root SecurityCaptureOverlay also covers navigator dialogs and bottom sheets.
The overlay keeps the subtree mounted so unsaved input survives capture changes.
It applies blur and an opaque cover while capture is active or native protection
has not initialized, excluding hidden text from semantics. Pointer interaction
is preserved; there is no logout or navigation block.

- iOS uses window screen `isCaptured` and capturedDidChangeNotification through
  `cozy_health/screen_capture`; it also rechecks when the app resumes. This covers
  active recording/mirroring, not prevention of a one-off screenshot. See
  [Apple capture notifications](https://developer.apple.com/documentation/uikit/uiscreen/captureddidchangenotification).
- Android sets FLAG_SECURE on the activity window for protected screens and
  clears it after the last screen leaves. The user continues seeing the screen;
  Android protects screenshots/recording output. It does not detect recording
  and blur the physical display. See
  [Android secure activities](https://developer.android.com/security/fraud-prevention/activities).
- Native channel failures keep sensitive content obscured on Android/iOS.
  Desktop/web previews have no equivalent native capture guarantee.

## Coverage

- Crisis hub and detection overlay.
- Safety-plan editor, preview and persisted view.
- Journal detail and editor.
- Mood detail.
- Provider access log.

Protection remains active while an underlying protected route is mounted, so a
sheet or pushed child does not temporarily clear the secure window flag.
This is intentionally conservative and may protect more than the topmost route.

## Storage/log audit

TokenStorage already uses flutter_secure_storage and supports memory-only
sessions. No token in Hive/SharedPreferences was found; no migration is needed.
API logs now omit URL, query strings, headers, bodies and error messages. Fixed
repository/UI messages omit exceptions/stacks. Token-presence and home mood
count messages were removed. Existing Sentry redaction drops breadcrumbs and
request/user data; crisis/private-overlay error events remain disabled.

## Changed files

Native: `android/app/src/main/kotlin/com/example/cozy_health/MainActivity.kt`,
`ios/Runner/AppDelegate.swift`.

Core: `lib/core/services/screen_capture_service.dart`,
`lib/core/widgets/security_blur.dart`, `lib/core/api/api_interceptors.dart`,
`lib/core/repositories/mood_repository.dart`, `lib/core/storage/token_storage.dart`,
`lib/main.dart`.

Features: auth service/login; content repository; crisis safety-plan repository,
storage and screens; journal screens; mood screens; notification repository;
settings profile/subscription repositories, settings and provider-access-log
screens; splash service/screen; home screen. These logging edits remove values
without changing the original error handling.

Tests: `test/core/screen_capture_test.dart`,
`test/core/sensitive_logging_test.dart`; this report.

## Required device verification

On iOS: begin recording before and during each protected screen, stop recording,
mirror via AirPlay, background/resume, open sheets, navigate back, and confirm
unsaved editor text survives. Confirm emergency actions remain operable.

On Android: repeat with screenshots/recording/casting and recent-app previews;
confirm captures hide protected content, nested routes retain protection, and
ordinary screens can be captured after protected routes unmount.

iOS compilation and these physical-device checks require macOS/devices and are
unverified here. No new package or device permission was introduced.

## Automated verification

- `flutter analyze lib`: no issues.
- `flutter test`: 263 passed (258 existing + 5 new; no tests removed).
- Four capture tests cover native capture notifications, interaction and unsaved
  input retention, nested lifetime, capture on entry/resume, and native failure.
  One logging test covers bodies, response data, authorization, URL/query data
  and error-message redaction. Existing Apple/Google log-redaction tests pass.
- Native Android compile result is recorded separately below. Physical capture
  verification and iOS compilation remain required regardless of Dart test results.

Android: `flutter build apk --debug --no-pub` passed and produced
`build/app/outputs/flutter-apk/app-debug.apk`. Existing Gradle 8.12, AGP 8.7.3
and Kotlin 2.1.0 emitted future-support warnings; toolchain currency belongs in
12.5. No build configuration or dependencies were upgraded in 12.1.
