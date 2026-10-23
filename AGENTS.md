# AGENTS.md — Flutter Project Rules

## Flutter and Dart Command Execution

In this Windows setup, `flutter` and `dart` commands MUST be run
outside the sandbox.

**Reason:**
- The current Flutter SDK lives outside the workspace under `C:\Users\pc\flutter`
- Flutter startup needs access to SDK Git metadata and writes to the SDK cache
- Sandboxed runs hang or fail because that location is not accessible inside the sandbox

**Policy:**
- Do NOT tell the user to run routine `flutter` or `dart` commands manually
- Request approval to run them outside the sandbox, then execute directly
- Use a persistent prefix approval for `flutter` and `dart`
- If permission is not granted, trigger an approval request instead of stopping at instructions only
- Use the installed SDK explicitly when needed:
  `C:\Users\pc\flutter\bin\flutter.bat` and
  `C:\Users\pc\flutter\bin\dart.bat`.

## CI acceptance for every change

- Include tests and build validation in each edit's implementation scope. Run
  focused regressions after each logical change, then validate the final code
  with the complete CI commands before reporting readiness:
  `flutter analyze --no-fatal-infos --no-fatal-warnings` and
  `flutter test --dart-define=INTERNAL_TEST_BUILD=true`.
- Preserve meaningful coverage for gestures/navigation, stored data, themes,
  large text, responsive layouts and accessibility. Update fixtures/finders
  when approved UI changes, and fix real behavior when broken. Do not skip or
  remove failures, weaken assertions, suppress diagnostics or disable checks.
- Match the Flutter version and build defines in `.github/workflows`. Verify
  affected native builds. iOS requires hosted macOS CI when working on Windows;
  local widget-test success alone does not prove APK/IPA builds succeed.
- After an authorized develop push, verify the remote SHA and monitor both
  Android and iOS jobs for that SHA through tests, build and artifact upload.
  Repair failures within the approved scope and verify the new pushed SHA.
  Report infrastructure blocks or out-of-scope failures with evidence and a
  repair plan; never call pending/failed native builds complete.
- Run Flutter/Dart commands outside the sandbox as required above. Record the
  final commit, commands, results and remaining limitations in the handoff.
