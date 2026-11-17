# Vendored flutter_jailbreak_detection 1.10.0

Source: https://pub.dev/packages/flutter_jailbreak_detection/versions/1.10.0
Repository: https://github.com/jeroentrappers/flutter_jailbreak_detection
Original BSD-3-Clause license is retained in LICENSE.

The released plugin predates Android Gradle Plugin 8 namespace requirements.
Only build metadata is adapted: explicit namespace, removal of the old manifest
package declaration, AGP 8.7.3 / Kotlin 2.1.0 matching the host app, and compileSdk
35 for the host's AndroidX constraints. Dart/Kotlin/Swift detection logic is
unchanged; upstream trailing whitespace is normalized. No global pub cache files
are modified. Review upstream changes before
replacing this pinned source; detection is advisory and can produce false results.

Java source/target compatibility and Kotlin jvmTarget are explicitly set to 11,
matching the host app. Without these settings, Java defaulted to 1.8 while Kotlin
inherited the build JDK target (21), causing release compilation to fail.
