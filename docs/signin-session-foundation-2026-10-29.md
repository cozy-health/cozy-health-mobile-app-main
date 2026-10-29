# Sign-in session foundation — 29 October 2026

This is development-only groundwork. It does not complete or enable staged sign-in protection.

Access/refresh credentials are installed as a generation-bound pair. Reads and writes are ordered; logout invalidates immediately. Refresh responses cannot revive an ended session, old authentication failures cannot clear a newer account, and a retry cannot transmit the original account's payload using another account's token. Account activation and stored-session restoration are serialized and checked against the session generation. Device proof is a server-generated secret in device-local secure storage, separate from public device IDs and security answers.

Regression evidence: the two new cross-account request tests reproduced the prior failures before the interceptor fix. Full validation results must be recorded after completion, not inferred from focused passes.

Remaining before enabling the backend flag:

- Patient challenge, email fallback, enrollment and settings screens, expiry/resend/error recovery and cancel-time revocation.
- Google/Apple stable identity-hint plumbing and refresh device-proof handling.
- Provider purpose-bound encrypted HttpOnly challenge/provisional cookies, BFF routes and client screens; no tokens or security answers in browser storage.
- End-to-end development acceptance including actual inbox delivery, account switching and expired challenges, followed by the existing rollout/readiness review.

The backend flag stays off. No production API settings, real customer sessions or store payments are changed by this foundation.