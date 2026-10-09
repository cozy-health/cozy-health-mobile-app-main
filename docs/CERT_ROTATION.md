# API leaf certificate pinning and rotation

**Rollout blocked:** two real independently verified leaf pins and a named
rotation owner are required. The next certificate and owner have not been
supplied. No backup certificate has been invented.

## Policy and current observation

Pin SHA-256 of the complete leaf certificate's DER bytes, not an intermediate,
root, PEM text or SPKI public-key digest. The API host is
`cozy-health-api-production.up.railway.app`, TCP 443.

Observed on 2026-10-09 over a normally verified TLS 1.3 connection:

- SHA-256: `fb370ca26842da2b2ff8e3182e0e8cfc6fb8eac32cdb5718f45a4b39b9e140af`.
- Subject: `*.up.railway.app`; issuer: Let's Encrypt YE2.
- Validity: 2026-09-27 03:01:43 UTC to 2026-12-26 03:01:42 UTC.

Railway controls wildcard renewal. This observation does not establish a future
pin or consistency across every edge. The project must obtain advance rotation
certificates, or resolve the hosting/domain arrangement before shipping.

`API_CURRENT_LEAF_SHA256` and `API_NEXT_LEAF_SHA256` are public Dart build defines.
The defaults are empty. Missing, duplicate or malformed pins fail closed. Normal
chain, hostname and expiry verification remains enabled. A native connection
factory checks the leaf before handing the TLS socket to HttpClient, so a
mismatch blocks credentials and health data before transmission. Dio's response
callback adds a second check. HTTPS API host/port checks are mandatory; redirects
and HTTP proxies are disabled. No unpinned retry, remote pin fetch or fail-open
switch exists. Web health requests are blocked because browsers do not expose
the peer certificate to this implementation.

## Release prerequisites

1. Assign the certificate/incident owner. Obtain the actual future certificate
   and verify its DER fingerprint, chain, hostname and validity independently.
   A duplicate current pin or synthetic certificate is not a backup.
2. Configure both public fingerprints in the build system. Pass
   `--dart-define=API_CURRENT_LEAF_SHA256=<verified current>` and
   `--dart-define=API_NEXT_LEAF_SHA256=<verified next>` to APK and IPA builds.
3. Existing CI is unchanged and passes neither define. **Default artifacts have
   health API access blocked. Do not push/distribute this mobile change until
   real pins and build wiring are ready.**
4. Recheck the live leaf with `node tool/inspect_api_certificate.mjs`, across
   relevant edges, immediately before release. Run tests/analysis and device
   acceptance/rejection checks with the real pins.

## Planned rotation

1. Verify the future leaf before activating it at the edge.
2. Release clients with overlapping current + next pins. Verify supported-client
   adoption, including offline users, and an emergency distribution path before
   switching the server. A minimum-version API cannot repair broken TLS.
3. Test valid current/next certificates, untrusted/expired/wrong-host/unpinned
   certificates and trusted-proxy interception. Confirm rejected requests send
   no credentials. Device/proxy and signed iOS checks remain in Phase 24.
4. Activate the next leaf only after supported clients accept it. Probe edges
   and monitor failure rates independently of the pinned API.
5. Publish a new overlapping set before the next renewal. Remove an old pin only
   when supported clients no longer need it.
6. Record owner, fingerprints, validity, app versions, adoption evidence, switch
   time and verification results in an appended rotation record.

## Incident recovery

On mismatch, preserve local drafts and queued writes; do not disable verification.
Investigate expiry, hostname, edge inconsistency and interception. Restore the
previous approved leaf only if it remains valid and uncompromised. Otherwise
distribute a verified app update through a channel independent of the API. A
compromised private key must be revoked, never restored as an outage workaround.

Loopback TLS tests cover two synthetic leaves, pre-request pin rejection,
untrusted chain, HTTP/alternate host, redirects and invalid rotation configuration.
Those localhost test keys are not production pins. Real rotation is unverified.

References: [Dio certificate validation](https://pub.dev/documentation/dio/latest/io/IOHttpClientAdapter-class.html),
[Dart connection factory](https://api.dart.dev/dart-io/HttpClient/connectionFactory.html).
