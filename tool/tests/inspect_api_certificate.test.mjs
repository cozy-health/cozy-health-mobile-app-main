import test from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs'
import vm from 'node:vm'
import { createHash } from 'node:crypto'

const source = fs.readFileSync(new URL('../inspect_api_certificate.mjs', import.meta.url), 'utf8')
  .replace(/^import .+ from .+\r?\n/gm, '')

function inspect(host) {
  const connections = []
  const output = []
  const socket = {
    getPeerCertificate: () => ({ raw: Buffer.from('synthetic certificate'), subject: {}, issuer: {}, valid_from: 'fixture start', valid_to: 'fixture end' }),
    getProtocol: () => 'TLSv1.3', authorized: true,
    end() {}, setTimeout() {}, on() {},
  }
  const context = {
    process: { argv: ['node', 'inspect_api_certificate.mjs', ...(host ? [host] : [])] },
    createHash, console: { log: value => output.push(JSON.parse(value)) },
    tls: { connect: (options, connected) => {
      connections.push(options)
      queueMicrotask(connected)
      return socket
    } },
  }
  return { run: () => vm.runInNewContext(source, context), connections, output }
}

test('default inspection uses the development host and verified TLS', async () => {
  const inspection = inspect()
  inspection.run()
  await Promise.resolve()
  assert.equal(inspection.connections.length, 1)
  const options = inspection.connections[0]
  assert.equal(options.host, 'api-dev.cozyhealth.org')
  assert.equal(options.servername, options.host)
  assert.equal(options.rejectUnauthorized, true)
  assert.equal(options.minVersion, 'TLSv1.2')
  assert.equal(inspection.output[0].leafSha256, createHash('sha256').update('synthetic certificate').digest('hex'))
})

for (const host of ['api.cozyhealth.org', 'cozy-health-api-production.up.railway.app', 'untrusted.example', 'https://api-dev.cozyhealth.org']) {
  test(`rejects ${host} before opening a socket`, () => {
    const inspection = inspect(host)
    assert.throws(inspection.run, /restricted to api-dev\.cozyhealth\.org/)
    assert.equal(inspection.connections.length, 0)
  })
}
