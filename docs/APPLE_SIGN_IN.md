# Apple Sign-In (Phase 4b-2)

Both active auth screens show Apple's standard black, 56-point button above
Google on supported iOS devices. Android and unavailable iOS devices hide it.
Loading prevents concurrent email/password, Google or Apple sign-in; cancellation
is silent and errors appear in a SnackBar. A 409 shows a linking-specific message.

The Apple SDK requests email and fullName. Mobile forwards `identity_token` and
`authorization_code` to `/api/v1/auth/apple`; `full_name` and `email` are forwarded
only when supplied. Subsequent logins do not invent a default name. The backend
uses the verified identity token's email for ownership; the optional SDK email
is not authoritative. The authorization code is exchanged by the backend for an
encrypted refresh token for deletion revocation. Mobile stores neither provider
credential. All Apple request body fields are redacted from logs.

Successful login stores the Sanctum token, exits guest mode, caches/fetches the
profile and starts the existing data sync. Login respects Stay logged in;
create-account persists the session. Both follow the personalization completion
check rather than sending an Apple-verified user through email verification.

## Phase 4c configuration

Apple is disabled by default. Until configuration is ready, a supported iOS
device displays “Apple Sign-In is not configured” without requesting credentials.

1. Enroll in Apple Developer Program and register/enable Sign in with Apple for
   the actual app Bundle ID (`com.example.cozyHealth` currently; confirm the
   intended shipping ID before registering it).
2. Configure the Apple signing team and provisioning profile in Xcode. The
   repository includes `Runner.entitlements`, the Sign in with Apple capability,
   and `CODE_SIGN_ENTITLEMENTS` for Debug, Release and Profile. Paid signing is
   still required; these files do not configure a Developer account.
3. Set the backend `APPLE_BUNDLE_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID` and
   `APPLE_PRIVATE_KEY` securely on Railway so code exchange and revocation work.
   Native iOS uses Bundle ID as the audience/client ID. No Service ID is required
   for this flow. `AppleConfig.serviceId` reads `APPLE_SERVICE_ID` for a future
   web flow; it is not passed to the native SDK. Do not bundle a private key in
   mobile code. `APPLE_REDIRECT_URI` is for web flows, not native iOS.
4. Enable mobile with `flutter run --dart-define=APPLE_SIGN_IN_ENABLED=true`.
   This public build flag is only a readiness switch, not a substitute for
   signing, backend keys or token verification. Existing Google build defines
   still need to be supplied when enabling both providers.
5. Test first/subsequent login, Hide My Email, existing-account linking, disabled
   accounts, cancellation, session persistence, and account deletion/revocation
   on a real device. No credentials or device testing were performed in 4b-2.

Info.plist retains the Google callback URL scheme and adds
`$(PRODUCT_BUNDLE_IDENTIFIER)` as a separate URL type, as requested. Native
Apple authentication does not use a web callback scheme.

Apple's name/email are normally supplied only on first authorization. If first
authorization succeeds at Apple but the backend request fails, those fields may
not be supplied on retry; the backend's existing default-name behavior applies.

Source: [sign_in_with_apple SDK and platform setup](https://pub.dev/packages/sign_in_with_apple).
