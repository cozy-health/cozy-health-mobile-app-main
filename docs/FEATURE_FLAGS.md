# Mobile feature configuration

FeatureFlagsService fetches public `/api/v1/config` on launch and resumes, and every ten minutes while foregrounded. Polling stops in the background. Duplicate refreshes share one request. Public requests use skipAuth; a failed public fetch cannot clear the session or user data.

The device-global Hive `app_config` box stores the public payload and fetch timestamp. A cold start accepts cache younger than sixty minutes. Expired, malformed or future-dated cache falls back to existing defaults. Fetch failures preserve the last valid in-memory configuration. The public cache holds no user content or identity.

Assistant uses a FeatureGate so disabled chat is never constructed. MainScreen hides its tab and quick action, preserves all remaining tab indices, and omits the Assistant spotlight from the optional tour. Other flag keys are exposed for future feature gates; this change only wires the requested Assistant gate.

Crisis hub, breathing, grounding and safety plan are explicitly always enabled; remote values cannot turn them off. Unknown feature keys default disabled.

Tests cover launch fetching, Hive persistence, freshness/expiry, malformed data, foreground polling, concurrent fetches, Assistant gating, stable navigation indices and public-config authentication isolation.
