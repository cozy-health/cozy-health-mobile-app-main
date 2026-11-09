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
