# Profile pictures and built-in avatars

Settings → Profile → Edit → Change photo offers 24 Open Peeps avatars, gallery,
camera, and removal. A square crop and preview precede photo upload. Avatar saves
are independent of name, username, email, and bio edits. Canceling a picker or
preview does not change the profile. Guests can browse but must create an account
to save. Saving needs a connection; failed requests retain the preview for retry.

The shared `ProfileAvatar` displays the same selection in Home, Settings, Profile,
and Edit Profile. It handles blank URLs, broken images, loading, and signed-URL
renewal. Previously downloaded managed photos are cached in encrypted,
account-scoped Hive settings for offline display. Presets are bundled SVGs and
require no network. Neither the app nor its users call DiceBear at runtime.

The fixed catalog uses CC0 Open Peeps artwork by Pablo Stanley, exported through
DiceBear 10.x. See `assets/avatars/open_peeps/LICENSE.md` for provenance, export
seeds, and license links. The selection IDs are stable across releases.

Avatar changes use dedicated authenticated API endpoints. A server revision and
client account-scope checks prevent old responses or offline profile edits from
restoring a removed picture. The Hive adapter appends its new revision field,
retaining compatibility with existing records. No photo-upload operation enters
the generic offline sync queue.

Android uses the system photo picker and camera, then uCrop. The pending-picker
marker is account-scoped; reopening the picker can recover a selection if Android
restarted the activity. Recovered files still require cropping and confirmation.
iOS includes camera and photo-library purpose strings. Permission failures offer
device settings. Physical Android/iOS handoff must be checked before a release;
Windows test runs mock those native APIs. Community visibility is unchanged.

## Verification

```text
flutter test --no-pub
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub test/features/settings/avatar_picker_test.dart --dart-define=SURFACE_SCREENSHOTS=true
flutter build apk --debug --no-pub
```

Picker screenshots are written to ignored `build/surface-review/avatar_*.png`.
Tests cover selection, confirmation, cancellation, removal, guest restrictions,
permission denial, retry, profile merge protection, and the theme/layout matrix.
Backend storage uses the existing Railway project; see the API repository's
`docs/profile-avatars.md` for provisioning and migration instructions.

### Verified implementation

- Full Flutter suite: 674 passed; two existing opt-in tests skipped (live API
  smoke test and internal-build notification simulation).
- Avatar picker tests: 15 passed; 24 readable screenshots cover options, grid,
  and preview across light/dark, normal/high-contrast, and portrait/landscape.
- Normal and high-contrast app-wide audits: 430 checks passed each, with zero
  collected rendering errors.
- Static analysis: no errors or warnings. Two unrelated existing style notices
  remain; the final profile-merge file check reports no issues.
- Android debug APK built with the new native plugins. The obsolete AndroidX
  core pins were removed, Kotlin updated to 2.2.20, and pinned Sentry 8 sources
  compile with a scoped Kotlin 1.8 language setting.
- Backend: 608 tests passed. The Railway bucket is configured, and the deployed
  Laravel storage check passed private upload/read, signed download, unsigned
  access denial, and cleanup without accessing a user photo.
- Physical Android/iOS camera, gallery, and crop handoff remain untested. An iOS
  binary was not built on this Windows machine.
