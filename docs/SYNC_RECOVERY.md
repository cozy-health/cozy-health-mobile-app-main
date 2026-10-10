# Sync recovery — 2026-10-10

The sync queue now drains edits made during an upload, replaces obsolete queued edits and recovers legacy id-only queue entries from their typed cache. Session expiry no longer waits on its own upload; account changes are serialized, drafts remain account-scoped, and login/session resume explicitly retries uploads. Initial online state also triggers retry.

Safe persisted error categories distinguish expired session, denied access, connection/server problems and rejected data. The pending sheet closes after successful retry and remains dismissible after failure without deleting saved changes.

All 11 real mobile serializers were exported as synthetic fixtures and verified against backend persistence. Notification read state, read-all and safety-plan reset now queue uploads. Their downloads respect pending changes and account boundaries. Safety-plan cache keeps the canonical singleton; notification read time/deep link survive encrypted reopen; profile parsing accepts decimal strings; saved-article background refresh is enabled.

Validation is completed in an isolated worktree so unrelated concurrent Home design edits are excluded. See the API's docs/SYNC_RECOVERY.md for database fixes, contract inventory and test limits. No connected Android device was available; installing/running the updated app is still required to confirm the reported phone's recovery.

Final results: full isolated mobile suite 528 passed (2m16s); Flutter analysis no issues; full backend suite 521 passed (3,576 assertions). A certificate test helper was also corrected to decode both LF and CRLF PEM fixtures in fresh Windows checkouts. All 10 certificate enforcement tests pass; transport verification was not relaxed.

The crisis and FAB overlay implementation is unchanged. Demo/guest behavior, certificate verification and later feature-phase dependencies remain as documented in the build plan.
