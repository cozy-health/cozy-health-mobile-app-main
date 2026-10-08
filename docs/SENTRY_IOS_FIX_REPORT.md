# iOS Sentry compilation fix

## Status

Phase 9 (`94ef1e6`) was pushed to origin/develop. The Sentry fix is committed separately and not pushed, as requested. Native CI confirmation therefore remains pending; no green iOS result is claimed.

The four requested Phase 9/Sentry tracker rows were added to the root `C:/projects/cozyhealth/docs/DEFERRED.md` before starting this fix. The tracker is not part of the mobile fix commit.

## Exact original CI error

Source: https://github.com/cozy-health/cozy-health-mobile-app-main/actions/runs/37777288760

```text
build-ios  Build iOS (no codesign)  2026-10-08T12:34:58.4023110Z Running Xcode build...
build-ios  Build iOS (no codesign)  2026-10-08T12:34:58.4036610Z Xcode archive done. 56.6s
build-ios  Build iOS (no codesign)  2026-10-08T12:35:00.0468890Z Failed to build iOS app
build-ios  Build iOS (no codesign)  2026-10-08T12:35:00.0546930Z Swift Compiler Error (Xcode): Value of type 'SentryBinaryImageCache' has no member 'image'
build-ios  Build iOS (no codesign)  2026-10-08T12:35:00.0550540Z /Users/runner/.pub-cache/hosted/pub.dev/sentry_flutter-8.14.2/ios/sentry_flutter/Sources/sentry_flutter/SentryFlutterPlugin.swift:265:92
build-ios  Build iOS (no codesign)  2026-10-08T12:35:00.0551990Z
build-ios  Build iOS (no codesign)  2026-10-08T12:35:00.0840700Z Encountered error while archiving for device.
build-ios  Build iOS (no codesign)  2026-10-08T12:35:00.1029820Z ##[error]Process completed with exit code 1.
```

## Installed versions and build environment

| Setting | Value |
|---|---|
| pubspec.yaml sentry_flutter constraint | `^8.14.2`, unchanged |
| pubspec.lock sentry_flutter | `8.14.2`, unchanged |
| pubspec.lock sentry | `8.14.2`, unchanged |
| Sentry wrapper CocoaPods dependency | `Sentry/HybridSDK = 8.46.0` |
| Sentry wrapper SwiftPM dependency | `from: 8.46.0`, allowing newer 8.x releases |
| ios/Podfile | Not present in the checkout; Flutter generates it when building with CocoaPods on macOS |
| ios/Podfile.lock | Not present in the checkout; no stale lockfile was deleted |
| Checked-in iOS target | 12.0 in project.pbxproj and AppFrameworkInfo.plist |
| Original CI effective iOS target | Flutter automatically raised it to 13.0 before compilation, as recorded in the build log |
| CI Flutter | 3.44.6 stable |
| CI host | Workflow `macos-14`; actual image `macos-14-arm64`, version 20260831.0302.1 |
| CI Xcode | Not pinned in the workflow; the logged runner image documents 15.4 (15F31d) as default. Inferred from that image, because the old workflow did not print xcodebuild -version. |

Runner image source: https://github.com/actions/runner-images/blob/macos-14-arm64/20260831.0302/images/macos/macos-14-arm64-Readme.md

## Root cause

**B — Sentry Cocoa SDK API mismatch with the Flutter wrapper under Swift Package Manager.**

The CI log shows automatic SwiftPM migration before the failure. Flutter 3.44 enables SwiftPM by default. Sentry Flutter 8.14.2's Package.swift uses an open 8.x Cocoa version range, while its podspec pins the matching Cocoa version to 8.46.0.

The wrapper calls `binaryImageCache.image(byAddress:)`. Cocoa 8.46.0 exposes the Objective-C `imageByAddress:` API imported under that Swift spelling. By Cocoa 8.58.1, the cache was implemented in Swift and exposes `imageByAddress(_:)`, matching the missing-member diagnostic against this older wrapper. The failing log does not print the exact resolved Cocoa version, so it is not reported as a verified 8.58.1 resolution; the incompatible API change and unconstrained range were verified in upstream source.

This is not an OS-availability diagnostic or an unsupported compiler-language diagnostic. Updating Xcode or increasing the deployment target cannot supply the missing method. There is also no tracked Podfile.lock to refresh.

Primary sources:

- Flutter SwiftPM default and per-project opt-out: https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers
- Sentry Flutter 8.14.2 Package.swift: https://github.com/getsentry/sentry-dart/blob/8.14.2/flutter/ios/sentry_flutter/Package.swift
- Sentry Flutter 8.14.2 podspec: https://github.com/getsentry/sentry-dart/blob/8.14.2/flutter/ios/sentry_flutter.podspec
- Cocoa 8.46.0 cache API: https://github.com/getsentry/sentry-cocoa/blob/8.46.0/Sources/Sentry/include/HybridPublic/SentryBinaryImageCache.h
- Cocoa 8.58.1 cache API: https://github.com/getsentry/sentry-cocoa/blob/8.58.1/Sources/Swift/Core/Helper/SentryBinaryImageCache.swift

## Chosen fix

Set the documented project option in pubspec.yaml:

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

This makes Flutter use CocoaPods and therefore the wrapper's exact native SDK dependency, 8.46.0. It also prevents CI from automatically generating the problematic SwiftPM dependency graph from a clean checkout. The local Flutter tool source confirms that disabling SwiftPM causes Podfile setup for plugin projects; missing Podfile generation is automatic on a macOS build host.

The iOS workflow now prints `xcodebuild -version` and, after building, checks Podfile.lock for `Sentry/HybridSDK (8.46.0)` before publishing the IPA artifact. A future native SDK drift causes an explicit CI error.

Sentry stays installed. No Dart code, privacy filters, DSN, deployment target or Android workflow was changed. SwiftPM can be re-enabled after adopting a Sentry wrapper whose Cocoa API/dependency constraints work together.

## Files changed

- `pubspec.yaml` — per-project native dependency manager setting, with reason.
- `.github/workflows/build-ios.yml` — compiler version diagnostics and native SDK version verification.
- `docs/SENTRY_IOS_FIX_REPORT.md` — this report.

## Verification

- `flutter pub get`: passed; configuration accepted and pubspec.lock unchanged.
- `flutter analyze lib`: zero issues.
- `flutter test`: all 220 tests passed.
- `pod install` and `flutter build ios --no-codesign`: unavailable locally on Windows; neither CocoaPods nor Xcode is installed. No synthetic Podfile.lock was created and no package-cache source was edited.
- Updated iOS CI has not run, because the fix is intentionally not pushed. The Phase 9 push runs build the preceding commit without this fix.

## Commit

`fix(ios): resolve Sentry native compilation error`

Commit hash is provided in the completion message. Do not interpret the unpushed fix as a confirmed green iOS build.