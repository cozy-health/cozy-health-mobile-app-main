# Phase 12.5 Android build repair

## Root cause

The SDK manager registered Android platform 35, but its android.jar and core-for-system-modules.jar were missing. The directory and package metadata alone were insufficient evidence of a complete installation. JNI targets compileSdk 35; Gradle failed while resolving its Java compile dependencies.

The failed :jni module belongs to path_provider_android 2.3.1 -> jni / jni_flutter, not flutter_jailbreak_detection. Removing jailbreak detection would not repair the missing platform files.

## Repair

Used sdkmanager to uninstall and reinstall only platforms;android-35. Both missing jars are now present. No Gradle wrapper upgrade, dependency downgrade, global pub-cache edit, or detection feature removal. A separate confirmed Java/Kotlin mismatch in the vendored jailbreak plugin was repaired by setting both targets to 11, matching the app.

## Build configuration

| Component | Configuration |
|---|---|
| Gradle wrapper | 8.12 |
| AGP | 8.7.3 |
| Android Kotlin plugin | 2.1.0 |
| Diagnostic Gradle runtime | Eclipse Adoptium JDK 21.0.11 |
| App Java source/target and Kotlin jvmTarget | 11 |
| JNI | 1.1.0, Java source/target 11, compileSdk 35, minSdk 21 |
| App compileSdk | Flutter default, currently 36 |

## Existing jailbreak plugin patch retained

Licensed local flutter_jailbreak_detection 1.10.0 source, original detection logic unchanged. No explicit Gradle minimum or providers.* calls. Build metadata patch: Kotlin 1.7.20 -> 2.1.0; AGP 7.3.1 -> 8.7.3; compileSdk 33 -> 35; namespace appmire.be.flutterjailbreakdetection; removed manifest package attribute. minSdk remains 17. Plugin now explicitly targets Java/Kotlin 11. Without these settings the release compiler reported Java 1.8 versus Kotlin 21; aligning both is the approved case C fix.

## Phase 12.5 mobile work

- Android release R8 minification and resource shrinking enabled with focused ProGuard rules.
- Device-integrity checks on launch, dismissible warning, authenticated aggregate-only detection reporting; detection errors never block use.
- Compatible dependency updates and pinned local plugin build metadata.
- Apple OAuth test expectation includes and verifies persistent device ID added by 12.3; no tests removed.
- Two formatting lint findings in warning service fixed.

## Verification

- gradlew :jni:compileReleaseJavaWithJavac: BUILD SUCCESSFUL in 2m 29s; 11 actionable tasks.
- gradlew assembleRelease: BUILD SUCCESSFUL in 12m 53s; 724 actionable tasks; R8 minification and resource shrinking completed.
- flutter analyze lib: no issues found. Full flutter test: 291 passed (baseline 282); no test count decrease.
- Prior device-integrity focused tests: 2 passed.

Original full failure stack trace is in local jni-error.log (provider exception begins at line 264). It resolves through Gradle internal file dependencies and identifies no plugin source line. Repaired SDK payload, rather than speculative script changes.

No changes to backend/dashboard in this repair turn. No production migration or push. Release signing remains the existing development key; this build verifies compilation, not store readiness.



## R8 compatibility repair

R8 exposed missing com.google.android.gms.auth.api.credentials classes referenced by the obsolete SmartAuth 2.0.0 dependency of Pinput 4.0.0. Google sign-in resolves a current play-services-auth version which no longer contains those classes. Updated Pinput to 5.0.2, removing SmartAuth entirely. The app only uses the code input for email password reset; its old Android SMS autofill method defaulted to none, and no credential APIs were called. Existing PIN themes, controller, length, and completion callback remain unchanged. No dontwarn rules were added to hide missing classes. See the [upstream Pinput 5 migration changelog](https://pub.dev/packages/pinput/changelog). Analysis/tests are rerun after this dependency change.


## Final mobile validation

After updating Pinput: flutter analyze lib reports no issues; flutter test passes all 291 tests (baseline 282). flutter build apk --release succeeded (330.6s Gradle task; 69.7 MB APK). Generated Android build/Kotlin cache paths are ignored. No tests removed. All source changes remain within the mobile repository. Source whitespace was normalized in the vendored files without changing detection logic.

## Files in the mobile Phase 12.5 commit

- .gitignore
- android/app/build.gradle.kts
- android/app/proguard-rules.pro
- docs/PHASE_12_5_JNI_DIAGNOSIS.md
- lib/core/services/device_integrity_service.dart
- lib/core/widgets/device_integrity_notice.dart
- lib/features/auth/data/auth_service.dart
- lib/main.dart
- pubspec.lock
- pubspec.yaml
- test/core/device_integrity_test.dart
- test/features/auth/apple_auth_test.dart
- third_party/flutter_jailbreak_detection/LICENSE
- third_party/flutter_jailbreak_detection/PATCHES.md
- third_party/flutter_jailbreak_detection/README.md
- third_party/flutter_jailbreak_detection/android/build.gradle
- third_party/flutter_jailbreak_detection/android/gradle.properties
- third_party/flutter_jailbreak_detection/android/gradlew
- third_party/flutter_jailbreak_detection/android/gradlew.bat
- third_party/flutter_jailbreak_detection/android/settings.gradle
- third_party/flutter_jailbreak_detection/android/src/main/AndroidManifest.xml
- third_party/flutter_jailbreak_detection/android/src/main/kotlin/appmire/be/flutterjailbreakdetection/FlutterJailbreakDetectionPlugin.kt
- third_party/flutter_jailbreak_detection/ios/Classes/FlutterJailbreakDetectionPlugin.h
- third_party/flutter_jailbreak_detection/ios/Classes/FlutterJailbreakDetectionPlugin.m
- third_party/flutter_jailbreak_detection/ios/Classes/SwiftFlutterJailbreakDetectionPlugin.swift
- third_party/flutter_jailbreak_detection/ios/flutter_jailbreak_detection.podspec
- third_party/flutter_jailbreak_detection/lib/flutter_jailbreak_detection.dart
- third_party/flutter_jailbreak_detection/pubspec.yaml

APK: build/app/outputs/flutter-apk/app-release.apk
SHA-256: 28547F1312302B0B3B8F49F71289315738ECF5CA9EDFD355ED732204A6F7834A
