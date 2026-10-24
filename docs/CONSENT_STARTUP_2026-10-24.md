# Consent startup and resume

Document consent remains separate from the retired custom age/guardian onboarding.

The gate no longer resets verified same-session content on every resume. A network-confirmed nonblocking policy lets the application continue while consent history loads in the background. Fresh application configuration can also avoid the initial consent-history loading gate. Cached/default feature flags never establish that consent is nonblocking.

Unknown policy and actual server consent denials remain gated. A required-policy transition hides unverified content while records load. Unknown checks time out after 15 seconds with retry; late responses cannot release a timed-out gate. Required documents still require explicit acceptance, including the separate health-data acknowledgement. No loading failure is stored as acceptance.

Session changes clear document state, choices and request ownership. A consent-required API denial overrides a previously nonblocking policy. Resume failures retain only already verified same-session state. Public crisis support remains available.

Focused regressions cover the reproduced history/resume interruptions, network-only policy, server-denial precedence, policy activation while open, timeout/late completion, existing account separation, required-document acceptance and retry. Complete analyzer, suite and Android/iOS artifact validation must be recorded for the exact pushed development commit.

This change does not implement the proposed breathing or popup redesign. Those proposals are awaiting the owner's screenshot approval. Android server push activation is a separate development configuration change; iOS remote delivery remains gated on Apple/APNs setup.

Development CI selects FIREBASE_OPTIONS_DEV_JSON and validates both clients against cozy-health-dev-2026. Inspection found the development API still inherited cozy-health-prod-2026 sender configuration. Android push was disabled again on development after detecting that mismatch; no device was registered and no test notification was sent. Changing the development sender credential awaits the owner's decision. Never change the client guard to accept the production project or claim credential validation establishes device delivery.
