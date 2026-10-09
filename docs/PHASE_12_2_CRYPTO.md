# Phase 12.2 — mobile crypto

Status: local implementation. **Do not push/distribute until two actual API leaf
pins and build wiring are ready.** Missing pins intentionally block health API
requests. Current/next production rotation is not verified. See CERT_ROTATION.md.

## Encryption and migration

All application Hive opens/getters now use EncryptedHive, including typed health
records, drafts/settings, queues, endpoint/config caches and device registry.
Native startup also discovers and migrates inactive account scopes. Each logical
box has a random 32-byte secure-storage key and an encrypted physical name ending
`_aes256_v1`. Existing token persistence remains in Flutter secure storage.

Legacy migration copies complete Hive adapter records, flushes, reopens and
compares all serialized values/keys before persisting completion status and
removing the matching legacy box. It never uses API JSON as a full storage
snapshot: that JSON omits fields such as conversation creation dates. Hive 2.2.3
is pinned because copying uses its binary reader/writer implementation.

Missing/changed keys, unreadable data, incomplete verification and changed legacy
copies block access while preserving files. New plaintext writes from a downgraded
app are retained alongside the encrypted copy for recovery. Concurrent/late opens
wait until migration and cleanup finish. Hive's automatic truncation recovery is
disabled. Startup displays a generic recovery message without keys or paths.
Do not reset secure storage, delete files or reinstall to resolve a key failure
without reviewing unsynced data. No automatic destructive reset or key replacement
for an existing encrypted box is implemented.

HiveAesCipher uses AES-256-CBC/PKCS7. This is confidentiality at rest; Hive's CRC
is not cryptographic authentication, and logical file removal does not guarantee
secure erasure of old filesystem blocks/backups. Native device upgrade, key-loss,
backup and rollback tests remain in Phase 24. Browser APIs are blocked; this
report does not certify web secure-key storage or inactive browser-scope migration.

## Transport and pinning

Android explicitly denies cleartext, trusts system CAs and disables app backup.
iOS ATS arbitrary-load/media/web exceptions are explicitly false. The shared Dio
client uses a native TLS connection factory to enforce normal chain/hostname/
expiry validation plus the leaf DER SHA-256 **before HTTP headers/body are sent**.
It rejects HTTP, alternate hosts/ports, redirects and HTTP proxies. A response
certificate callback adds another check. Health API requests fail closed if the
rotation set is missing, invalid or mismatched. There is no unpinned fallback.

The production host is fixed in ApiConstants. Both public pins must be supplied
as `API_CURRENT_LEAF_SHA256` / `API_NEXT_LEAF_SHA256` Dart defines. The current
live wildcard was inspected through verified TLS 1.3; the next actual leaf and
rotation owner are unavailable. CERT_ROTATION.md records its hash/expiry and the
required overlap/incident procedure. Existing CI passes neither define and is
unchanged after approval review rejected adding an unprovisioned persistent gate.
Default artifacts are **not API-capable releases**. Synthetic localhost TLS test
keys are solely test fixtures, not a production backup certificate.

## Secret audit

Gitleaks 8.30.1, with verified official release checksum, scanned the current
tracked/unignored source snapshot and all local Git refs. Current findings:
two synthetic TLS fixture keys and a dynamically generated secure-key test
expression; each was reviewed as non-production. No findings in pre-12.2 mobile
history. No broad allowlist or test suppression was added. Backend/dashboard
results and infrastructure verification limits are in the backend crypto report.
Historical backend .env credentials are dead per owner; no rotation was performed.

## Verification

- `flutter test --no-pub`: **279 passed** (263 existing + 16 added; none removed).
- `flutter analyze --no-pub lib`: **no issues**.
- `flutter build apk --debug --no-pub`: **passed**. This is a compilation check;
  the artifact has no production pin defines and cannot access the health API.
- Effective merged Android debug manifest: cleartext=false, backup=false,
  fullBackupContent=false, network security configuration attached; packaged XML
  denies cleartext and trusts only system anchors.
- Existing Gradle 8.12/AGP 8.7.3/Kotlin 2.1.0 future-support warnings remain in
  12.5; no platform toolchain was upgraded here.

Existing 263 tests remain. Added tests exercise
legacy drafts/queued payloads, fields absent from API JSON, missing/changed keys,
interrupted copy, verified leftover cleanup, downgraded-app writes, concurrent
late opens, two real loopback TLS leaves, pre-request mismatch rejection, normal
chain validation, HTTP/host/redirect rejection, and invalid rotation configuration.
Signed iOS/physical-device/proxy checks are deferred to Phase 24. 12.1 unsigned
iOS and Android compilation already passed GitHub CI on 2026-10-09.

## File inventory

- lib/core/storage/encrypted_hive.dart; hive_files.dart; hive_files_io.dart;
  hive_files_stub.dart.
- lib/core/services/local_db_service.dart; feature_flags_service.dart;
  lib/core/repositories/endpoint_cache.dart; lib/main.dart.
- lib/core/api/api_client.dart; api_transport.dart; api_transport_io.dart;
  api_transport_stub.dart; leaf_pin_policy.dart; lib/core/constants/api_constants.dart.
- android/app/src/main/AndroidManifest.xml;
  android/app/src/main/res/xml/network_security_config.xml; ios/Runner/Info.plist.
- pubspec.yaml (pin Hive 2.2.3 and directly declare the already locked crypto
  package); pubspec.lock (crypto dependency classification only).
- test/core/encrypted_hive_test.dart; certificate_pinning_test.dart;
  test/fixtures/tls/current.pem, current.key, next.pem, next.key, README.md.
- Existing test fixture updates: test/core/feature_flags_service_test.dart;
  preferences_upload_test.dart; test/features/empty_states/empty_states_test.dart;
  home/feature_tour_test.dart; offline/offline_ux_test.dart;
  onboarding/onboarding_flow_test.dart; settings/digital_wellbeing_test.dart;
  ux/ux_test.dart; test/support/repository_fixture.dart.
- tool/inspect_api_certificate.mjs; docs/CERT_ROTATION.md; this report.

No existing tests removed; no 12.2 push or production rotation/migration performed.
