import tls from 'node:tls'
import { createHash } from 'node:crypto'

// Routine inspection must never fall back to a legacy production hostname.
const host = process.argv[2] || 'api-dev.cozyhealth.org'
if (host !== 'api-dev.cozyhealth.org') {
  throw new Error('Certificate inspection is restricted to api-dev.cozyhealth.org.')
}
const socket = tls.connect({ host, port: 443, servername: host, minVersion: 'TLSv1.2', rejectUnauthorized: true }, () => {
  const cert = socket.getPeerCertificate()
  console.log(JSON.stringify({ host, leafSha256: createHash('sha256').update(cert.raw).digest('hex'),
    subject: cert.subject, issuer: cert.issuer, validFrom: cert.valid_from, validTo: cert.valid_to,
    tls: socket.getProtocol(), authorized: socket.authorized }, null, 2))
  socket.end()
})
socket.setTimeout(15000, () => socket.destroy(new Error('TLS connection timed out')))
socket.on('error', error => { console.error(error.message); process.exitCode = 1 })
