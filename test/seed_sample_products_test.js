const assert = require('node:assert/strict');
const {execFile} = require('node:child_process');
const {randomUUID} = require('node:crypto');
const fs = require('node:fs/promises');
const http = require('node:http');
const os = require('node:os');
const path = require('node:path');
const {test} = require('node:test');
const {promisify} = require('node:util');

const exec = promisify(execFile);
const script = path.join(__dirname, '..', 'scripts', 'seed_sample_products.js');

test('SAMPLE seed requires local demo mode and preserves supplied product data', async () => {
  const file = path.join(os.tmpdir(), `refillhub-seed-test-${randomUUID()}.json`);
  const product = {
    id: 'TEST-id',
    name: 'TEST ONLY product',
    waterType: 'Purified',
    description: 'TEST ONLY description',
    isActive: true,
    createdAt: '2025-01-01T00:00:00Z',
    sizes: [{label: 'TEST ONLY size', price: 12.5, isAvailable: true}],
  };
  let received;
  const server = http.createServer((request, response) => {
    let body = '';
    request.setEncoding('utf8');
    request.on('data', chunk => { body += chunk; });
    request.on('end', () => {
      received = {method: request.method, url: request.url, body: JSON.parse(body)};
      response.writeHead(200, {'Content-Type': 'application/json'});
      response.end('{}');
    });
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const env = {
    ...process.env,
    FIRESTORE_EMULATOR_HOST: `127.0.0.1:${server.address().port}`,
    FIRESTORE_PROJECT_ID: 'demo-refillhub',
  };
  try {
    await fs.writeFile(file, JSON.stringify([product]));
    await assert.rejects(exec(process.execPath, [script, file], {env}), /--confirm-sample/);
    await assert.rejects(
      exec(process.execPath, [script, file, '--confirm-sample'], {
        env: {...env, FIRESTORE_EMULATOR_HOST: 'example.com:8080'},
      }),
      /127\.0\.0\.1:port/,
    );
    await assert.rejects(
      exec(process.execPath, [script, file, '--confirm-sample'], {
        env: {...env, FIRESTORE_PROJECT_ID: 'production-project'},
      }),
      /demo- project/,
    );
    assert.equal(received, undefined);

    await fs.writeFile(file, JSON.stringify([product, product]));
    await assert.rejects(exec(process.execPath, [script, file, '--confirm-sample'], {env}), /unique/);
    assert.equal(received, undefined);

    await fs.writeFile(file, JSON.stringify([product]));
    const result = await exec(process.execPath, [script, file, '--confirm-sample'], {env});
    assert.match(result.stdout, /SAMPLE: created/);
    assert.equal(received.method, 'POST');
    assert.match(received.url, /\/documents\/products\?documentId=TEST-id$/);
    assert.deepEqual(received.body.fields, {
      name: {stringValue: product.name},
      waterType: {stringValue: product.waterType},
      description: {stringValue: product.description},
      isActive: {booleanValue: true},
      createdAt: {timestampValue: product.createdAt},
      sizes: {arrayValue: {values: [{mapValue: {fields: {
        label: {stringValue: product.sizes[0].label},
        price: {doubleValue: 12.5},
        isAvailable: {booleanValue: true},
      }}}]}},
    });
  } finally {
    await new Promise((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
    await fs.unlink(file);
  }
});
