# Phase 8.2 — private crash reporting

Sentry Flutter is installed using the version selected by the project's dependency resolver (8.14.2). No DSN is committed. Supply `--dart-define=SENTRY_DSN=<project DSN>` to enable reporting; builds without a DSN start normally without telemetry.

`lib/core/services/crash_reporting.dart` configures the SDK and reconstructs outgoing error events from an allowlist. It removes messages, exception values, user identity, requests, arbitrary contexts/tags, breadcrumbs, thread variables, absolute paths, function names and source context. It retains event IDs, timestamps, severity, approved exception types, package source locations and the fixed feature tag. Unknown exception types become `ApplicationError`. Route paths and record IDs are never transmitted as tags.

Feature tags cover auth, mood_checkin, journal, chat, provider, crisis and app. Crisis route errors and all errors while the crisis support overlay is open are discarded. Overlay suppression restores reporting in `finally`, including when dismissal fails.

Print, HTTP, interaction and native breadcrumbs are disabled. Screenshots, view hierarchy, feedback and scope sync are disabled. Native crash handling and watchdog termination reporting are disabled because native uploads bypass the Dart event filter. Performance sample rate is configured to 0.2, but transaction uploads are dropped until a separate safe transaction schema is implemented. Replay is not enabled.

## Phase 8.5 verification needed

No real DSN is available, so delivery to the Sentry dashboard cannot be verified. The explicit debug-only `CrashReporting.debugProbe()` sends a generic test exception when a DSN is configured; it is never called automatically. Enable a real DSN and invoke the probe from a debug session to confirm dashboard delivery. Native crash reporting and performance telemetry need privacy verification before enabling them. This phase reports Dart/Flutter errors only.

Seven tests exercise event redaction, unknown field handling, fixed feature tags, crisis route/overlay suppression, SDK configuration and startup without a DSN.
