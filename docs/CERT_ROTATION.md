# Mobile API TLS and certificate renewal

The owner selected platform certificate-authority, hostname and expiry verification for production. Native requests use the shared `ApiDestinationPolicy` and `VerifiedApiAdapter`. The configured public API is `https://api.cozyhealth.org`.

## Transport rules

- Require HTTPS, the configured API hostname and its exact port.
- Reject destinations containing user information.
- Verify the certificate chain, hostname and expiry during the TLS handshake before sending HTTP headers or bodies.
- Disable redirects and HTTP proxy routing through this API adapter.
- Use the same transport for authentication, content requests and push-token cleanup.
- Keep the native transport requirement for health API requests. The existing web transport remains unavailable.

Production builds use the platform trust store. The optional adapter SecurityContext is used by isolated loopback tests. Production callers use the default context. The previous leaf-fingerprint build defines and two-pin release gate have been removed under the approved production plan.

## Renewal acceptance

Railway manages public certificate renewal. Before release, verify the configured public hostname through a normally verified TLS connection and run the native API smoke test. Record the source revision, hostname and observed certificate validity in release evidence.

The focused loopback suite accepts two trusted certificates and changes the server certificate while retaining the same client transport. It also rejects expired, wrong-host and untrusted certificates before the server receives a request, rejects invalid destinations and prevents redirect following. The checked-in CA and private keys are synthetic fixtures confined to these tests.

## Incident handling

Investigate chain failures, expiry, hostname mismatch and edge configuration through independent provider access. Preserve saved records and queued writes while connectivity is unavailable. Correct the server certificate or hostname configuration and verify normal TLS acceptance before resuming affected checks. Cordelia Ebo is incident primary, with team@cozyhealth.org for escalation.

## References

[Android TLS guidance](https://developer.android.com/privacy-and-security/security-ssl), [Dart SecureSocket](https://api.dart.dev/dart-io/SecureSocket/startConnect.html), [Railway public networking](https://docs.railway.com/networking/public-networking/specs-and-limits).
