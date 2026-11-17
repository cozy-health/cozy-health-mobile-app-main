# Mobile production release

The legal bundle is included in the app assets. A Git push does not update an
installed app: the signed binary must be released through its store.

## Android

1. Use the approved production application ID `org.cozyhealth.app` in the new
   Cozy Health Play listing. The older `org.cozyhealth.app.dev` listing has its
   own permanent package identity. Record the new listing URL and Play app ID.
2. Copy `android/key.properties.example` to `android/key.properties` and supply
   the upload keystore path, alias and passwords locally. Both the properties
   file and keystores are ignored by Git. Store credentials in the release
   system's secret store; do not place them in Dart definitions.
3. Enable Google sign-in in production Firebase and refresh the native SDK
   configuration after adding the upload certificate and Play App Signing
   certificate. Configure the API's Google token audience from the actual
   production web/server OAuth client. Record actual sign-in and push receipt.
4. The release PR runs `Build Android Production Candidate` for branches in this
   repository, using the workflow run number as its Android version code. After
   merge, manual dispatch accepts an unused positive version code for later
   releases. Its shared configuration tool selects the registered Firebase
   app, requires its server OAuth client and uses the converted production
   Sentry project. Credentials come from repository secrets. The workflow runs
   tooling tests, analyzer and full widget tests, then verifies the upload key,
   signed bundle, native page compatibility, package and version identity.
   For an equivalent local build after preparing signing and configuration:

   ```powershell
   $env:COZY_ANDROID_APPLICATION_ID = 'org.cozyhealth.app'
   $env:COZY_BUILD_TARGET = 'production-android'
   python tool/prepare_push_config.py
   flutter build appbundle --release --dart-define-from-file=push-defines.json --build-number=<unused version code>
   ```

   The production release task rejects the placeholder ID, missing signing
   configuration, missing keystore and demo/internal mode. API transport checks
   the platform trust chain, certificate hostname and expiry. Follow
   CERT_ROTATION.md for renewal verification.
5. Verify the upload certificate, production API target, sign-in, account
   deletion, consent choices, offline synchronization and legal links on a
   signed device build before uploading to a Play test track. Complete store
   privacy/safety declarations and obtain release approval before rollout.

## iOS

Use a Mac with Xcode, an enrolled Apple developer team, registered bundle ID,
distribution signing and provisioning profiles. The current placeholder bundle
ID must be replaced with the registered ID. Build an archive with the same
production environment and platform TLS verification. Keep internal/demo mode disabled.
Validate the signed archive and device workflows before TestFlight/App Store
submission. No iOS archive or store submission can be produced on this Windows
workspace.

## Activation remains separate

Shipping a legal bundle does not make unpublished documents effective. Vendor
agreements, approved country/guardian assurance, retention verification and the
API publication/enforcement sequence remain release dependencies. Do not
remove their gates to obtain a successful build.

Signing setup follows the [Flutter Android release guide](https://docs.flutter.dev/deployment/android).
