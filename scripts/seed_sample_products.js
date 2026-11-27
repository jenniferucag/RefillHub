// SAMPLE development seed: writes supplied data to a local Firestore emulator only.
const fs = require('node:fs/promises');

async function main() {
  const [file, confirmation, ...extra] = process.argv.slice(2);
  if (!file || confirmation !== '--confirm-sample' || extra.length) {
    throw new Error('Usage: node scripts\\seed_sample_products.js <sample-data.json> --confirm-sample');
  }
  const host = process.env.FIRESTORE_EMULATOR_HOST || '';
  const match = /^127\.0\.0\.1:([0-9]{1,5})$/.exec(host);
  const project = process.env.FIRESTORE_PROJECT_ID || '';
  if (!match || Number(match[1]) < 1 || Number(match[1]) > 65535 ||
      !/^demo-[a-z0-9-]+$/.test(project)) {
    throw new Error('Set FIRESTORE_EMULATOR_HOST to 127.0.0.1:port and FIRESTORE_PROJECT_ID to a demo- project.');
  }

  const products = JSON.parse(await fs.readFile(file, 'utf8'));
  if (!Array.isArray(products) || products.length === 0) {
    throw new Error('Input must be a non-empty array of sample products.');
  }
  const ids = new Set();
  for (const product of products) {
    const id = product?.id;
    if (typeof id !== 'string' || !id || id.includes('/') ||
        id === '.' || id === '..' || /^__.*__$/.test(id) ||
        Buffer.byteLength(id, 'utf8') > 1500 || ids.has(id)) {
      throw new Error('Each product must have a unique, valid Firestore document id.');
    }
    ids.add(id);
    if (Object.keys(product).some(key => !['id', 'name', 'waterType', 'description', 'imageUrl', 'isActive', 'createdAt', 'sizes'].includes(key)) ||
        typeof product.name !== 'string' || typeof product.description !== 'string' ||
        typeof product.waterType !== 'string' || product.waterType.trim().length === 0 ||
        (product.imageUrl != null && typeof product.imageUrl !== 'string') ||
        typeof product.isActive !== 'boolean' || !Array.isArray(product.sizes) ||
        typeof product.createdAt !== 'string' ||
        !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,9})?(?:Z|[+-]\d\d:\d\d)$/.test(product.createdAt) ||
        !Number.isFinite(Date.parse(product.createdAt))) {
      throw new Error(`Invalid product fields for id ${id}.`);
    }
    for (const size of product.sizes) {
      if (!size || typeof size !== 'object' || Array.isArray(size) ||
          Object.keys(size).some(key => !['label', 'price', 'isAvailable'].includes(key)) ||
          typeof size.label !== 'string' ||
          typeof size.price !== 'number' || !Number.isFinite(size.price) ||
          typeof size.isAvailable !== 'boolean') {
        throw new Error(`Invalid product size for id ${id}.`);
      }
    }
  }

  const base = `http://${host}/v1/projects/${project}/databases/(default)/documents/products`;
  for (const product of products) {
    const fields = {
      name: {stringValue: product.name},
      waterType: {stringValue: product.waterType.trim()},
      description: {stringValue: product.description},
      isActive: {booleanValue: product.isActive},
      createdAt: {timestampValue: product.createdAt},
      sizes: {
        arrayValue: {
          values: product.sizes.map(size => ({
            mapValue: {
              fields: {
                label: {stringValue: size.label},
                price: {doubleValue: size.price},
                isAvailable: {booleanValue: size.isAvailable},
              },
            },
          })),
        },
      },
    };
    if (product.imageUrl != null) {
      fields.imageUrl = {stringValue: product.imageUrl};
    }
    const response = await fetch(`${base}?documentId=${encodeURIComponent(product.id)}`, {
      method: 'POST',
      headers: {'Content-Type': 'application/json', Authorization: 'Bearer owner'},
      body: JSON.stringify({fields}),
    });
    if (!response.ok) {
      throw new Error(`Could not create sample product ${product.id}: ${response.status} ${await response.text()}`);
    }
    console.log(`SAMPLE: created ${product.id}`);
  }
}

main().catch(error => {
  console.error(`SAMPLE seed failed: ${error.message}`);
  process.exitCode = 1;
});
