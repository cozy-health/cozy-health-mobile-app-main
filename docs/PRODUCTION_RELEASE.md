# Mobile production release

The legal bundle is included in the app assets. A Git push does not update an
installed app: the signed binary must be released through its store.

## Android

1. Register the final application ID in Play Console and provide it through
   `COZY_ANDROID_APPLICATION_ID`. The development ID remains unchanged.
2. Copy `android/key.properties.example` to `android/key.properties` and supply
   the upload keystore path, alias and passwords locally. Both the properties
   file and keystores are ignored by Git. Store credentials in the release
   system's secret store; do not place them in Dart definitions.
3. Obtain two distinct, independently verified production leaf-certificate
   SHA-256 fingerprints. Do not fabricate a future fingerprint or bypass the
   existing pin policy. Confirm a certificate-rotation plan before shipping.
4. Run the analyzer and consent/legal regression tests, then build:

   ```powershell
   $env:COZY_ANDROID_APPLICATION_ID = '<registered application ID>'
   flutter build appbundle --release --dart-define=COZY_ENVIRONMENT=production --dart-define=API_CURRENT_LEAF_SHA256=<current fingerprint> --dart-define=API_NEXT_LEAF_SHA256=<next fingerprint>
   ```

   The production release task rejects the placeholder ID, missing signing
   configuration, missing keystore, demo/internal mode and invalid pin pairs.
   Development builds retain their existing signing behavior.
5. Verify the upload certificate, production API target, sign-in, account
   deletion, consent choices, offline synchronization and legal links on a
   signed device build before uploading to a Play test track. Complete store
   privacy/safety declarations and obtain release approval before rollout.

## iOS

Use a Mac with Xcode, an enrolled Apple developer team, registered bundle ID,
distribution signing and provisioning profiles. The current placeholder bundle
ID must be replaced with the registered ID. Build an archive with the same
production environment and verified pin pair; do not enable internal/demo mode.
Validate the signed archive and device workflows before TestFlight/App Store
submission. No iOS archive or store submission can be produced on this Windows
workspace.

## Activation remains separate

Shipping a legal bundle does not make unpublished documents effective. Vendor
agreements, approved country/guardian assurance, retention verification and the
API publication/enforcement sequence remain release dependencies. Do not
remove their gates to obtain a successful build.

Signing setup follows the [Flutter Android release guide](https://docs.flutter.dev/deployment/android).
