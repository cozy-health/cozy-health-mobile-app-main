# Local mobile polish and MySQL checks — 22 November 2026

Owner authorized the Journal/Settings recommendations and committing the existing local native-feel changes. Local source only: no push, production action, live deliveries or desktop control. Base mobile d654774ed5bcff994fd435711c95baf5321e5e2e.

## UI changes and evidence

| Before | After | Why |
|---|---|---|
| Journal inherited a focused form outline and separate boxed footer panels. | Borderless writing surface, clear reflection heading and a single quiet footer with compact tags during keyboard entry. | Prioritize reflection while preserving tagging, drafts and Done behavior. |
| Settings profile used generic loading labels without bounded recovery. | Profile-shaped skeleton, grouped loading semantics, eight-second preparation timeout and explicit retry. | Explain loading and provide an escape from indefinite waiting. |
| Account refresh had no specific failure presentation. | Retain cached identity and explain reported refresh failures; discard late retry results after account/session changes. | Keep useful settings accessible without showing another account's data. |

Five full-screen, uncropped synthetic PNGs and checksums: ../design/journal-settings-20261122/. Widget renders are not iPhone observations. Existing repository behavior may return cached data after transport failures; this batch does not claim all network failures are surfaced distinctly.

Seven Settings regressions passed: placeholder and timeout, duplicate retry prevention/recovery, cached-stream failure, guest readiness, stale session result and 200% text in both themes. Two Journal regressions passed at 320px width/200% text with keyboard in both themes, preserving text/tags after a failed save. Initial focused failures exposed keyboard-inset propagation and test semantics-handle cleanup; fixes and passing reruns are retained in output/journal-settings-20261122/. No assertion was weakened or test removed.

Includes the prior approved native-feel edits and reproduced recorder/tab/avatar repairs documented in 2026-11-22-items-6-10.md. Student policy remains school-email verification, documents disabled, legacy 14-day pending-evidence cleanup.

## MySQL acceptance

Existing provider replacement, Student concurrency and community moderation runners all passed. Runtime MySQL 9.7.4; isolated container cozy-local-acceptance-20261122, ID 22e58c9dc0273b2d2f45bd9172830d64d222b629f2ce0df14beec76a890155e6; only 127.0.0.1:58909, disposable database cozy_release_test. Test mail/cache only. Container stopped afterwards. Logs and mysql-results.json in workspace output/journal-settings-20261122/. No production/recovery database or original rehearsal container touched.

The previous scoped API baseline remains 335 passes/3,037 assertions; no API application code changed here. These concurrency checks close the local MySQL dependency, not live provider/Student/moderation acceptance.

## Final validation

Final analyzer exits 0: 14 reported entries representing seven unique pre-existing diagnostics, each printed twice (three API constructor infos and four scratch-file findings); none in the changed files. Android arm64 debug INTERNAL_TEST_BUILD=true build exits 0; ZIP integrity and new Journal/Settings kernel markers verified. APK SHA-256: 14f449817ecdefc0f947b10bcc7ebe24832abd6f9ab122ec45c619a789896234. Existing Kotlin/Android SDK tooling warnings remain in the build log. Full mobile invocation completed with 1,719 passes, one existing opt-in live smoke skip and one failure (exit 1): Windows errno 1224 prevented writing the generated popup-visibility-dark.png reference. The exact unchanged failing test passed on isolated rerun (one pass, exit 0). The failed invocation is retained; it is not reported as a single green run. All 1,720 non-skipped cases passed across the full invocation and that rerun. No application/test source changed during final validation. All 251 original design assets hash-match their pre-run copies after restoring 62 generated PNGs. Detailed results: workspace output/journal-settings-20261122/completion.json. iOS compilation and physical-device checks remain unavailable locally. Graph refreshes were rejected by the launcher develop-only branch policy; direct source/caller checks and runtime regressions are the fallback. No fresh graph pass claimed.

## Open dependencies

Physical-device recording/playback/camera and UI checks; live inbox/push receipt, refresh/revocation and account separation; two additional provider pilots; actual Student reviewer/store acceptance; approved production content; elapsed retention and remaining launch gates in workspace BUILD_PLAN.md. Railway remains stopped at the owner's spending cap. Five previously blocked synthetic temp-directory removals remain untouched. No entire category 6–10 is marked complete.
