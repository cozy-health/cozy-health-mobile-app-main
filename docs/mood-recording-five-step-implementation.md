# Five-step mood check-in implementation

Implemented 2026-10-21. This supersedes the four-step/dialog interaction described
in the earlier mood recording notes. Feeling-selection artwork, chip layout and
category composition remain unchanged; the shell now reports five steps.

## Flow

| Step | Behavior |
| --- | --- |
| 1. Feeling | Existing selection UI. A Home shortcut reveals its category but does not confirm a feeling. |
| 2. Intensity | Dedicated five-level slider with a visual preview and the chosen feeling. |
| 3. Causes | Expandable groups, multiple selections, a persistent selection summary and optional Skip when empty. |
| 4. Coping | Eight-choice preview plus selected historical/additional choices. “See all” opens the searchable response sheet. Skip appears only when empty. |
| 5. Review | Independent Feeling, Intensity, Causes and Coping edit actions. Save waits for persistence. |
| Saved | Receipt uses the returned saved entry. Home, Log another and past entries remain available without timed navigation. |

Review edits are transactional. Continue applies edits and returns to Review;
Back restores the prior answers. Changing Feeling first requires confirmation on
Intensity. Temporary Review edits do not overwrite the committed draft.

The coping sheet has a separate temporary selection set. Search preserves hidden
selections. Use selected responses applies; X, barrier, Back and drag dismissal
cancel. Applying the sheet keeps the user on Coping, including during Review
editing. The sheet handles keyboard insets; its background check-in does not
resize when the search keyboard opens. The sheet respects reduced motion.

## Data and compatibility

- No API, model schema, adapter, catalog migration or dependency changes.
- The catalog still contains 72 feelings, 48 causes and 34 unique responses.
- Draft version 3 stores zero-based positions for all five steps. Existing
  nine-step and version 2 drafts migrate; version 3 migration is idempotent.
  Future versions remain available for explicit discard and are not interpreted.
- The UI displays 1–5; new intensity changes store 2/4/6/8/10. Visiting a
  historical stored value such as 7 does not round it to 8.
- Historical body, sleep, energy, note, custom cause and helpfulness fields survive
  editing. Retired causes and responses remain visible and removable.
- One stable entry ID survives retries. Double submissions are ignored. Save
  failures keep Review and the draft available; draft cleanup failure cannot
  turn a persisted entry into a reported save failure.
- Existing offline queue and crisis handling remain in use. Draft and save work
  are bound to the opening account; late callbacks cannot produce a receipt or
  write a draft into another account.
- Existing unrelated eligibility and consent work in this workspace is preserved.

## Design and verification

Scoped controls use `CozyColors.recording` tokens and the custom `AppPressable`
for press feedback, keyboard activation and accessible semantics. Existing app
themes, Outfit typography and supplied artwork are retained. Choices wrap for
large text and constrained widths, with 48px minimum touch targets.

Actual Flutter renders: [light/dark gallery](../build/mood-selection-review/v3-index.html).
Checked-in image baselines: `test/goldens/mood_recording/v3/`. These are widget
renders, not physical-device screenshots.

Focused coverage includes transactional Review cancellation/application, changed
Feeling confirmation, legacy migration, historical odd intensities, hidden fields,
stable retry IDs, account changes during pending work, sheet search and all four
dismissal paths, landscape search keyboard, 320/430px widths, landscape, 200% text,
light/dark themes and semantic touch-target guidelines.

Run checks from the mobile app root, with Flutter/Dart outside the Windows sandbox:

```powershell
flutter analyze --no-pub
flutter test --no-pub --dart-define=SURFACE_REAL_FONTS=true
flutter build apk --debug --no-pub
```

To propose new visual baselines, run the mood screen test with
`--dart-define=SURFACE_REAL_FONTS=true --update-goldens` and visually inspect every
changed image before accepting it. Ordinary tests without the font flag do not
compare mood golden files.

## Verification results — 2026-10-22

- Focused controller, flow and pressable checks: **39 passed**, including all
  twelve real-font light/dark image comparisons without updating baselines.
- Draft/UX checks: **12 passed**. Storage restart, expiry and clearing still use
  real encrypted storage; widget migration checks use the controller's injected
  draft store to avoid file writes stranded in Flutter's fake-time zone.
- Two existing UI heading checks now assert the current **Assessment History**
  title; both passed after the assertion correction. Quiz production code was
  not changed.
- The broad run recorded **827 passed and 2 skipped** before its two stale
  heading assertions and the older draft-test teardown stall were resolved.
  The affected files were rechecked separately; the complete suite was not
  rerun after those test-only corrections. See `v3-final-tests.log`,
  `v3-ux-recheck.log` and `v3-headings-recheck.log` in the review output folder.
- Android debug APK: **built successfully** at
  `build/app/outputs/flutter-apk/app-debug.apk`. An initial dependency-host DNS
  failure recovered on retry. No dependency versions were changed.
- Full analysis reported **No issues found**. See `v3-final-analyze.log`.
- No physical-device, Android emulator or iOS runtime acceptance was performed.
  The available environment did not expose an Android emulator.
