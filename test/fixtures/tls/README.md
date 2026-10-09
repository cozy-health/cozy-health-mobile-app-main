# Synthetic TLS test identities

These localhost certificates, test CA, and private keys are generated solely
for loopback integration tests. They are not API certificates, production
credentials, or rotation pins. Never install these trust anchors in the app.

The client trusts `ca.pem`; `current.pem` and `next.pem` are separate server
identities signed by that CA. Server certificates have a localhost SAN,
`serverAuth` extended key usage, and an 825-day lifetime to satisfy macOS TLS
verification. The CA has certificate-signing key usage and a ten-year lifetime.
Do not extend the server lifetime or bypass TLS verification to fix expired tests.

To renew the fixtures, run these OpenSSL commands from this directory (in a
POSIX shell). Commit the updated certificates; the tests derive pins from them.
The checked-in private keys are synthetic test keys only.

```sh
openssl req -x509 -new -key ca.key -out ca.pem -sha256 -days 3650 \
  -subj '/CN=Cozy Health Synthetic Test CA/O=Cozy Health Synthetic Test Only' \
  -addext 'basicConstraints=critical,CA:TRUE' \
  -addext 'keyUsage=critical,keyCertSign,cRLSign'
for name in current next; do
  openssl req -new -key "$name.key" -out "$name.csr" \
    -subj '/CN=localhost/O=Cozy Health Synthetic Test Only'
  openssl x509 -req -in "$name.csr" -CA ca.pem -CAkey ca.key \
    -set_serial "$(if [ "$name" = current ]; then echo 1; else echo 2; fi)" \
    -out "$name.pem" -days 825 -sha256 -extfile server.cnf -extensions server
  openssl verify -purpose sslserver -verify_hostname localhost \
    -CAfile ca.pem "$name.pem"
  rm "$name.csr"
done
```
