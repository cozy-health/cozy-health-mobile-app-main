# Support/privacy development delivery - 4 November 2026

Added customer support inbox/conversation and privacy-request screens using existing branded pressables, tokens, account/session guards and transport. Existing report submission gains an idempotency key. Customer support/privacy remains reachable through consent recovery while Home/private health content remains protected. Generic support email/inbox links carry no account identifiers or tokens; Android/iOS declarations are included.

Tests cover cross-account/same-account-session late responses, reply and privacy idempotency payloads, malformed responses, foreign/token-bearing links, failed reply draft/retry, explicit privacy confirmation, dark/light large-text layout and consent-recovery boundaries. The first newly available focused run reproduced a test tap before scroll layout settled; the test now settles before tapping and still asserts two sends, one reused request ID, retained failed draft and cleared successful draft. No assertion was removed or weakened.

Installed Flutter **3.44.6 / Dart 3.12.2** matches CI. Scoped formatting was applied. Local full analysis ran with existing CI flags; new brace findings were fixed in the changed files without suppressing diagnostics. An unfinished local full test run was stopped to apply those final fixes. Final full analyzer/tests must run in the hosted development Android/iOS workflows for the exact pushed SHA; pending native builds are not successes. Local final focused outcomes and hosted run links are recorded in the workspace HANDOFF.

Final local focused validation: **23 tests passed** across the new customer operations and existing consent-gate suites after formatting/brace fixes. Full hosted validation remains the release gate for this commit.

Physical-phone install/upgrade/audio/storage/background/share/link acceptance remains open. No general sign-in enrollment, consent enforcement, store/payment or production change. Preserve unrelated AGENTS/README/docs/artwork and failure artifacts. The full 175-item build register ships in API `docs/BUILD_PLAN.md`.
