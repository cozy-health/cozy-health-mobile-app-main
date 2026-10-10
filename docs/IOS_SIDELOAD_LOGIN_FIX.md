# iPhone sideload login fix — 2026-10-10

Affected build: develop commit `272e62eba6acf36f59ed2ee59acd3dd681d2711b`, GitHub run `38049470891`, build 107.

The iOS workflow packaged a release-mode IPA without certificate pin defines.
`ApiClient` required pins outside debug mode and rejected requests before sending
credentials. The login screen reduced the secure-connection exception to the
reported “check your connection” message. Re-running build 107 cannot change it.

The develop-only workflow now sets `INTERNAL_TEST_BUILD=true` explicitly and
labels its artifact `ios-internal-test-ipa-<sha>-<run>`. This selects normal
platform-verified HTTPS for internal sideload testing, while retaining host,
port, redirect and certificate chain/expiry checks. Production defaults still
require two independently verified leaf pins. Build identity records internal
test mode. The secure-connection login error now directs users to update the
test build instead of blaming their connection.

Regression tests exercise an internal release login request without pins,
production rejection before sending credentials, and internal rejection of an
untrusted certificate. The workflow includes an opt-in live transport check:
health must return 200 and an empty login must return email/password validation
errors (422). It does not use real credentials or mutate an account.

Local validation output is in the workspace's `docs/IOS_LOGIN_FIX_*_2026-10-10.txt`.
The full local Flutter suite passed 539 tests, including existing untracked
audit diagnostics that are not part of this fix's commit. All 13 targeted TLS
tests passed, the live internal-release connection check passed, and Flutter
analysis found no issues. Diagnostic passes are not feature acceptance passes.
Xcode/IPA packaging cannot be executed on this Windows machine. The GitHub macOS
run and installation on the reported iPhone are the remaining device acceptance
checks. Download the new internal-test artifact and sideload its
`Runner-unsigned.ipa`, keeping the same app identity so local data is preserved.
