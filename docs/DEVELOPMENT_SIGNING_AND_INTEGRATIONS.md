# Development signing and integrations

Scope: E01/E02 in the workspace build plan, development only. iPhone is the owner's primary device, installed through Sideloadly with the existing Apple ID still available. Android was installed from a GitHub APK. No USB access is assumed.

## Artifact identity and upgrades

Android and iOS workflows append artifact SHA256, filename, byte size and signing identity to `build-info.json`. Android metadata is produced only after `apksigner verify`; iOS bundle/version/build values come from the packaged app. The IPA is unsigned and requires Sideloadly signing. These manifests do not prove an installed app can be upgraded.

Baseline Android run [42125289848](https://github.com/cozy-health/cozy-health-mobile-app-main/actions/runs/42125289848), commit `7d48d7fff1729bab383f085a3aeec2e3ede48b8b`, signs with public certificate SHA256 `6729bb090cb14ceb5e3c3ff9a881649ff8f2100d1c7fa5e4f99d86c29ccabeb4`. The existing local debug key has SHA256 `fe734dacae6f78e1e385a5817962f0fab361793857a40d770bfe3606bb439206`. They differ. The runner-generated private key was not retained by this workflow and no persistent signing secret existed when inspected. The installed Android artifact has not been identified; the baseline is evidence of the CI signing problem, not proof of its installed certificate.

Permanent Android signing is pending the owner's key decision. Do not silently use the local key or claim compatibility. Never uninstall, clear storage or overwrite a sole copy of unsynced drafts/recordings to work around a signing error.

When candidate builds are available, the owner can test without USB:

1. On the existing app, note one saved journal and recording and create a recognisable local draft. Allow confirmed records to finish syncing; local drafts and pending recordings must not be assumed backed up.
2. iPhone: use the same Sideloadly Apple ID and existing application identity/settings to install the candidate IPA over the existing app. Do not delete the existing app. If Sideloadly requires a changed identity or refuses an update, stop and report the error.
3. Android: compare the candidate certificate with the installed artifact when available. Attempt an update only after the identity decision and data-preservation checks; stop on a signature conflict.
4. Reopen the app; verify the saved journal, recording playback, local draft and pending-sync behavior. Record the candidate commit/build and outcomes. These are V01/V03/V05 acceptance, separate from CI.

## Integration reconciliation

Read-only runtime checks on 6 November 2026 explicitly guarded Railway project `33f9a938-49e3-42c5-83c7-633ee85760fa`, environment `56b85cc3-e80b-4cb9-a0d4-b47abe8586f6` and API origin `https://api-dev.cozyhealth.org`.

Confirmed on API deployment `35822ef0-eb73-4b5d-9778-0da757b2d3be` and worker deployment `ad02e168-9cb5-43e3-b5d9-5fbc6625f271`:

- CORS allows the development website/dashboard. Dashboard deployment `46301458-cc34-4805-b6b0-93d2107251c3` points at the development API.
- Android push is enabled with matching development Firebase server credentials; iOS remote push remains disabled. Existing mobile workflows validate the development Firebase project and use development telemetry secrets.
- SMTP has four allowed development recipients and a configured test recipient. Support/privacy each have one assigned active reviewer. No messages were sent by this audit.
- Audio uses credentialed private S3 storage under the private root; ffmpeg/ffprobe are available on both services. No objects were created/deleted by this audit.
- Database queue is selected; the separate worker uses the explicit `queue:work --queue=high,default,email` start command, so its false supervisor-worker flag is not evidence of a missing worker. Scheduler heartbeat is fresh; audio cleanup, Student reminders/pruning and other existing jobs are registered. Queue consumption is not newly certified by this read-only audit.
- Genuine billing and emergency email remain disabled. Provider retention execution has no approval reference and stays gated pending the E10 owner policy decision; this audit does not authorize destructive retention.
- Development Sentry is enabled. Existing mobile crash/analytics code checks per-account consent and cancellation/withdrawal; this audit does not certify external telemetry delivery.

Native quiz invitation registration used the legacy Railway host despite development API-issued invitation links. The Android registration and iOS associated domain now use `api-dev.cozyhealth.org`; two failing configuration regressions reproduced this mismatch before repair. OS-verified opening still depends on association responses, signing and device testing, and is not claimed complete.

Both public association endpoints also returned HTTP 500 in development. Three API regressions reproduced database-backed browser session access to a missing `sessions` table. The API repair removes browser-session middleware from these public machine-readable routes, preserving their response contracts: configured identities return JSON; missing identities return HTTP 503. No application identities are fabricated. Android fingerprints and the iOS application ID were absent at inspection; filling them remains dependent on the signing decision/platform access. The stateless repair passed all three focused tests (12 assertions) before delivery.

Detailed local evidence: workspace `output/e02-api-inspect.json`, `e02-worker-inspect.json`, `e02-web-inspect.json`, `e02-development-status.json`. No credentials are included. Candidate CI links, commit SHA and remaining blockers are recorded in the workspace handoff.

Local validation: 12 Python tooling tests passed; focused quiz/support Flutter tests 14 passed; analyzer exit 0 with 15 existing findings outside this change; full internal-build Flutter tests 1,276 passed with one existing opt-in smoke skipped. API full suite passed 1,006 tests / 11,816 assertions, including preserved local assessment tests. Hosted builds/CI and physical-device acceptance are separate outcomes.
