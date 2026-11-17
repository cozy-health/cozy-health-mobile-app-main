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

## Picker opening reliability and iPhone acceptance

The actual Edit Profile picture and Change photo controls open the sheet before
checking the guest-session preference. The sheet permits browsing during that
check, blocks saves until confirmed, and offers retry after failure or a five-second
timeout. Repeated taps cannot stack sheets. Account changes dismiss the sheet and
its removal dialog; stale saves cannot update the new account. Profile picture
updates do not replace unsaved text edits. Malformed/stale API responses are errors,
not successful saves. A renewed signed URL restarts the offline cache download.

Automated regression coverage includes the real EditProfileScreen entry controls,
account lookup delay/error/timeout, dismissal, encrypted persistence, real repository
requests through a fake transport, malformed responses, and account switching.
Run the entry tests alongside the existing picker and restore tests:

```text
flutter test --no-pub test/features/settings/avatar_entry_flow_test.dart test/features/settings/avatar_picker_test.dart test/features/auth/restore_flow_test.dart
```

Both iOS workflows check the archive for the 24 bundled avatars, camera/library
purpose strings, and native plugin setup. The signed workflow now also embeds
BUILD_SHA and BUILD_RUN_ID and uploads build-info.json. Confirm the installed build
under Settings -> About before investigating an iPhone report.

Physical iPhone verification remains REQUIRED and has not been performed by these
Windows tests. Record iPhone model, iOS version, commit, build number, and outcomes:

- Tap both picture controls, with keyboard visible and while offline; exactly one
  sheet opens. Browse all avatars without camera/library permission.
- Preview, cancel, save, navigate Home/Settings/Profile/Edit, restart, and verify
  the saved selection. Offline save retains preview and permits retry.
- Test guests, account changes during save and removal confirmation, removal, and
  unsaved name/username/bio edits.
- Test camera/gallery, square crop, cancellation, denied/restricted permissions,
  return from device settings, and app background/foreground transitions.
- Collect sanitized runtime exceptions on any failure. Do not record patient
  pictures, signed URLs, tokens, or text. A failure before the sheet opens is not
  evidence of a bucket or upload API problem.

No iOS archive, signing, workflow execution, or physical-device pass is implied
by successful Windows tests. The iPhone incident's original runtime cause remains
unconfirmed until a build with known identity is exercised on the device.

Historical diagnostic: immediately before commit 6c76898 (2026-10-15 16:03 WAT),
Edit Profile used an empty Change photo callback and a placeholder picture tap
handler. Those builds display the controls but open no picker. This matches the
reported symptom; it does not establish which build is installed on the iPhone.
Install an identified build containing the avatar implementation and reliability
fixes before attributing a remaining failure to the current picker.

### Reliability update verification (2026-10-15)

- Full Flutter suite with INTERNAL_TEST_BUILD=true: 692 passed, one opt-in live
  API test skipped. The initial new save-test timing failure was corrected by
  awaiting its actual repository operation instead of a fixed sleep.
- Final avatar entry/picker run after the large-text scroll reset: 33 passed,
  including 18 new entry/repository/display regressions and 15 existing picker
  tests. Entry widget regressions use Flutter's iOS platform variant.
- Regenerated 24 options/grid/preview screenshots across theme, contrast, and
  orientation combinations. Inspected representative captures and corrected
  retained scroll position on options/grid/preview transitions.
- Full static analysis: no errors or warnings; existing style notices in
  hive_files_io.dart and repository_fixture.dart remain. Final analysis of the
  changed picker and new regression file: no issues.
- Android debug APK rebuilt successfully after the final UI fix.
- Backend avatar tests: 12 passed, 129 assertions.
- Both edited iOS workflow files parse as YAML. Archive checks and embedded build
  identity are present; macOS workflows and physical-iPhone checks remain unrun.
