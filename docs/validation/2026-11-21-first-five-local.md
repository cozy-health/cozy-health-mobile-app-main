# First-five local repair evidence — 21 November 2026

This records a completed local batch; the workspace BUILD_PLAN.md remains the authoritative remaining-work checklist. No push, deployment, live delivery or phone acceptance is established here.

## Repairs

- Reject concurrent registration, login, reset-request and reset-confirmation submissions before redraw.
- Keep failed/throttled reset-code requests retryable without advancing to a success state or discarding the email.
- Record each journal match from the unchanged detector while retaining the four-hour support-prompt cooldown. Preserve existing flags and historical records.
- Scope the prompt cooldown to the active account and surface.
- Retain the pinned SDK's standard generated/native-platform analyzer exclusions; no tracked Dart files lie under these excluded paths. App/test directories remain analyzed.

## Completed validation

Flutter 3.47.8: nine focused regressions; complete mobile suite 1,702 passed / one existing opt-in live API smoke skipped. Analyzer exits zero under existing CI flags, retaining eight existing nonfatal findings. New auth regression analysis is clean.

API source 205c61c68db544640d140b2715805b7d74916c64 is unchanged: applicable regression baseline 88 tests / 723 assertions passed.

Android arm64 internal debug build passed. APK ZIP integrity verified; SHA-256 `3df0bd5a331eb19c2091c4aa1a86af8d79fc74bfb13f203f6bd37af958a16af8`. This establishes compilation, not store signing or installation acceptance.

All 238 preserved design files were hash-verified after full validation; 181 test-rewritten files were restored exactly. Existing unrelated design edits were preserved.

Graphify refresh remains blocked by its develop-only policy on the current working branch. Direct source/caller inspection and regression validation were used; no graph pass is claimed.

Detailed local logs and source fingerprints: workspace output/first-five-20261121/batch.json and android-validation-status.json, linked from the workspace handoff.

## Screenshot delivery

[Brand-motion pack](../design/brand-motion-20261121/README.txt): eleven 1290×2796 uncropped PNGs from the current local widgets, with synthetic fixtures. Four selected capture tests passed. PNG hashes and source-input hashes are in its manifest. These are headless widget renders without OS chrome, not physical-device captures. Temporary capture harnesses were removed after retaining their local evidence copies.

## Still open

Applicable first-five phone, inbox, social-platform, cross-device, install/update and iOS signing/build acceptance remain open. Production remains stopped at the owner hard spending limit. Next local checklist work is voice/avatars/private files (item 6), followed by content/assessments (7), provider journeys (8), Student eligibility (9), and community/moderation (10).
