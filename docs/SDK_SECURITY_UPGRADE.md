# Flutter SDK security baseline

Development builds use Flutter 3.47.8 in all three existing mobile workflows.
This is the stable patched baseline for
[GHSA-frr6-h895-5pxp](https://github.com/dart-lang/sdk/security/advisories/GHSA-frr6-h895-5pxp).
The previously pinned Flutter 3.44.6 / Dart 3.12.2 combination is affected.
The advisory concerns compromised intermediate CA certificates and outbound
`dart:io` TLS verification on Android, Windows and certain Linux environments.
An existing affected binary requires rebuilding; changing a workflow does not
repair an already installed application.

The 208 hosted packages in the reviewed lockfile had no OSV querybatch findings
on 8 November 2026. That package result does not cover the SDK itself.
Use the pinned SDK for analysis, the full internal-build test suite and native
development builds. Keep normal certificate verification and the existing
production pin/release gates. No production or mobile store release is authorized
by this development upgrade.

The SDK requires lockfile updates to matcher 0.12.20, meta 1.19.0,
test_api 0.7.12 and vector_math 2.4.4. A separate OSV query of those four
versions on 9 November 2026 returned no findings. Existing analyzer rules and
coverage are preserved; automatic SDK migration exclusions were not adopted.

The first hosted Android native build reproduced the SDK's minimum-Gradle check:
Gradle 8.13 was below the required 8.14 baseline. The wrapper now uses the
official Gradle 8.14.6 patch distribution with its published SHA256 checksum.
The compatibility check remains enabled. Existing Android plugin and Kotlin
versions are preserved.
