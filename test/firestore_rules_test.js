const project = 'demo-refillhub';
const base = `http://127.0.0.1:18893/v1/projects/${project}/databases/(default)/documents`;
const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
function token(uid) {
  const now = Math.floor(Date.now() / 1000);
  return `${encode({alg:'none',typ:'JWT'})}.${encode({
    iss:`https://securetoken.google.com/${project}`,
    aud:project, auth_time:now, user_id:uid, sub:uid, iat:now, exp:now+3600,
    firebase:{sign_in_provider:'password'}
  })}.`;
}
function value(v) {
  if (v === null) return {nullValue:null};
  if (v instanceof Date) return {timestampValue:v.toISOString()};
  if (Array.isArray(v)) return {arrayValue:{values:v.map(value)}};
  if (typeof v === 'object') return {mapValue:{fields:fields(v)}};
  if (typeof v === 'boolean') return {booleanValue:v};
  if (Number.isInteger(v)) return {integerValue:String(v)};
  if (typeof v === 'number') return {doubleValue:v};
  return {stringValue:v};
}
function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([k,v]) => [k,value(v)]));
}
async function request(method, path, uid, data) {
  return fetch(`${base}/${path}`, {
    method,
    headers: {
      ...(uid ? {Authorization:`Bearer ${uid === 'owner' ? 'owner' : token(uid)}`} : {}),
      ...(data ? {'Content-Type':'application/json'} : {}),
    },
    ...(data ? {body:JSON.stringify({fields:fields(data)})} : {}),
  });
}
async function check(label, method, path, uid, data, allowed) {
  const response = await request(method, path, uid, data);
  const actual = response.ok;
  if (actual !== allowed) {
    throw new Error(`${label}: got ${response.status}: ${await response.text()}`);
  }
  console.log(`PASS ${label}`);
}
const customer = {role:'customer',isActive:true,fullName:'Name',name:'Name',phone:'09',address:'Address',email:'a@example.com'};
async function checkProfileUpdate() {
  const updates = {name:'New Name',phone:'09171234567',address:'New Address'};
  const mask = Object.keys(updates).map(key => `updateMask.fieldPaths=${key}`).join('&');
  await check('profile update allowed', 'PATCH', `users/customer?${mask}`, 'customer', updates, true);
  const saved = await request('GET', 'users/customer', 'customer');
  if (!saved.ok) throw new Error(`Profile read failed: ${await saved.text()}`);
  const actual = (await saved.json()).fields;
  for (const [key, expected] of Object.entries(fields({...customer,...updates}))) {
    if (JSON.stringify(actual[key]) !== JSON.stringify(expected)) {
      throw new Error(`Unexpected saved ${key}: ${JSON.stringify(actual[key])}`);
    }
  }
  console.log('PASS profile update preserves role and status');
}
async function checkActiveProductsQuery(uid) {
  const response = await fetch(`${base}:runQuery`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token(uid)}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      structuredQuery: {
        from: [{collectionId:'products'}],
        where: {fieldFilter: {
          field: {fieldPath:'isActive'}, op:'EQUAL', value:{booleanValue:true},
        }},
      },
    }),
  });
  if (!response.ok) throw new Error(`Active products query failed: ${await response.text()}`);
  const result = await response.json();
  const documents = result.filter(item => item.document).map(item => item.document.name);
  if (documents.length !== 1 || !documents[0].endsWith('/products/test-active')) {
    throw new Error(`Unexpected ${uid} product results: ${JSON.stringify(documents)}`);
  }
  console.log(`PASS ${uid} query returns only active products`);
}
function decodedValue(encoded) {
  if ('stringValue' in encoded) return encoded.stringValue;
  if ('booleanValue' in encoded) return encoded.booleanValue;
  if ('integerValue' in encoded) return Number(encoded.integerValue);
  if ('doubleValue' in encoded) return encoded.doubleValue;
  if ('mapValue' in encoded) return decodedFields(encoded.mapValue.fields || {});
  if ('arrayValue' in encoded) return (encoded.arrayValue.values || []).map(decodedValue);
  if ('nullValue' in encoded) return null;
  return undefined;
}
function decodedFields(encodedFields) {
  return Object.fromEntries(
    Object.entries(encodedFields).map(([key, encoded]) => [key, decodedValue(encoded)]),
  );
}
async function submitOrder(orderId, uid, order) {
  const {createdAt, updatedAt, ...fieldsWithoutServerTimestamps} = order;
  return fetch(`${base}:commit`, {
    method:'POST',
    headers:{
      Authorization:`Bearer ${token(uid)}`,
      'Content-Type':'application/json',
    },
    body:JSON.stringify({
      writes:[{
        update:{
          name:`projects/${project}/databases/(default)/documents/orders/${orderId}`,
          fields:fields(fieldsWithoutServerTimestamps),
        },
        updateTransforms:[
          {fieldPath:'createdAt',setToServerValue:'REQUEST_TIME'},
          {fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'},
        ],
        currentDocument:{exists:false},
      }],
    }),
  });
}
async function checkDirectOrderCreation() {
  const now = new Date();
  const requestedDelivery = new Date(now.getTime()+60*60*1000);
  const day = now.toISOString().slice(0,10).replaceAll('-','');
  const order = {
    orderNumber:`RH-${day}-1234`,
    customerId:'customer',
    customerName:'Updated',
    phone:'09171234567',
    address:'Address',
    notes:'',
    orderType:'purchase',
    pickupRequestedAt:null,
    pickupScheduledAt:null,
    deliveryRequestedAt:requestedDelivery,
    deliveryScheduledAt:null,
    items:[{
      waterType:'Purified',
      productName:'Test Product',
      sizeLabel:'Standard',
      unitPrice:12.5,
      quantity:2,
      lineTotal:25,
    }],
    totalAmount:'25',
    paymentMethod:'Cash on Delivery',
    status:'Pending',
    statusHistory:[{
      status:'Pending',
      timestamp:now,
      changedBy:'customer',
    }],
    createdAt:now,
    updatedAt:now,
  };
  const response = await submitOrder('direct-order','customer',order);
  if (!response.ok) {
    throw new Error(`Direct customer order creation failed: ${await response.text()}`);
  }
  console.log('PASS customer creates own pending purchase order directly');

  const saved = await request('GET','orders/direct-order','customer');
  if (!saved.ok) throw new Error(`Direct order could not be read: ${await saved.text()}`);
  const savedFields = decodedFields((await saved.json()).fields);
  if (savedFields.status !== 'Pending' ||
      savedFields.customerId !== 'customer' ||
      savedFields.items[0].lineTotal !== 25) {
    throw new Error(`Unexpected direct order data: ${JSON.stringify(savedFields)}`);
  }

  const pickup = new Date(now.getTime()+60*60*1000);
  const refill = {
    ...order,
    orderNumber:`RH-${day}-5678`,
    orderType:'refill',
    waterType:'Purified',
    containerSize:'Standard',
    containerCount:2,
    pickupRequestedAt:pickup,
    deliveryRequestedAt:new Date(pickup.getTime()+60*60*1000),
    items:[{
      waterType:'Purified',
      productName:'Test Product',
      sizeLabel:'Standard',
      unitPrice:null,
      quantity:2,
      lineTotal:null,
    }],
    totalAmount:null,
  };
  const refillResponse = await submitOrder('direct-refill-order','customer',refill);
  if (!refillResponse.ok) {
    throw new Error(`Direct refill order creation failed: ${await refillResponse.text()}`);
  }
  console.log('PASS customer creates own unpriced refill order directly');

  const invalidStatus = await submitOrder('invalid-status-order','customer',{
    ...order,
    orderNumber:`RH-${day}-9999`,
    status:'Confirmed',
  });
  if (invalidStatus.ok) throw new Error('Direct order creation accepted a non-Pending status.');
  const foreignOrder = await submitOrder('foreign-order','customer',{
    ...order,
    customerId:'other',
    orderNumber:`RH-${day}-8888`,
  });
  if (foreignOrder.ok) throw new Error('Customer created an order for another user.');
}
async function main() {
  await check('customer registration', 'PATCH', 'users/customer', 'customer', customer, true);
  await checkProfileUpdate();
  await check('cannot register as admin', 'PATCH', 'users/attacker', 'attacker', {...customer,role:'admin'}, false);
  await check('cannot register inactive profile', 'PATCH', 'users/attacker', 'attacker', {...customer,isActive:false}, false);
  await check('cannot promote self', 'PATCH', 'users/customer', 'customer', {...customer,role:'admin'}, false);
  await check('cannot change own active status', 'PATCH', 'users/customer', 'customer', {...customer,isActive:false}, false);
  await check('active customer updates profile', 'PATCH', 'users/customer', 'customer', {...customer,name:'Updated'}, true);
  await check('cannot create another user', 'PATCH', 'users/other', 'customer', customer, false);
  await check('seed inactive profile', 'PATCH', 'users/inactive', 'owner', {...customer,isActive:false}, true);
  await check('inactive user reads own status', 'GET', 'users/inactive', 'inactive', null, true);
  await check('inactive user cannot edit profile', 'PATCH', 'users/inactive', 'inactive', {...customer,isActive:false,name:'Updated'}, false);
  await check('inactive user cannot reactivate self', 'PATCH', 'users/inactive', 'inactive', customer, false);
  await check('inactive user cannot delete own profile', 'DELETE', 'users/inactive', 'inactive', null, false);
  await check('customer cannot read another profile', 'GET', 'users/inactive', 'customer', null, false);
  await check('seed admin', 'PATCH', 'users/admin', 'owner', {...customer,role:'admin'}, true);
  await check('active admin can read another profile', 'GET', 'users/inactive', 'admin', null, true);
  await check('active admin can list users', 'GET', 'users', 'admin', null, true);
  const businessInfo = {
    businessName:'TEST Business', about:'TEST about', contactPhone:'09171234567',
    contactEmail:'test@example.com', address:'TEST address',
    operatingHours:'TEST hours', deliveryCoverage:'TEST coverage',
    deliveryPolicy:'TEST policy', scheduleNotes:'TEST notes',
    orderingGuideSteps:['TEST step'],
  };
  await check('admin creates business information', 'PATCH', 'business_info/main', 'admin', businessInfo, true);
  await check('customer can read business information', 'GET', 'business_info/main', 'customer', null, true);
  await check('unauthenticated user cannot read business information', 'GET', 'business_info/main', null, null, false);
  await check('customer cannot update business information', 'PATCH', 'business_info/main', 'customer', {...businessInfo,about:'Changed'}, false);
  await check('admin updates business information', 'PATCH', 'business_info/main', 'admin', {...businessInfo,about:'Updated'}, true);
  await check('business information rejects missing fields', 'PATCH', 'business_info/incomplete', 'admin', {businessName:'TEST'}, false);
  await check('customer cannot list users', 'GET', 'users', 'customer', null, false);
  await check('admin cannot alter own role', 'PATCH', 'users/admin', 'admin', customer, false);
  const activeMask = 'users/inactive?updateMask.fieldPaths=isActive';
  await check('admin activates another user', 'PATCH', activeMask, 'admin', {isActive:true}, true);
  await check('admin deactivates another user', 'PATCH', activeMask, 'admin', {isActive:false}, true);
  await check('admin cannot use a non-boolean active status', 'PATCH', activeMask, 'admin', {isActive:'yes'}, false);
  await check('admin cannot change own active status', 'PATCH', 'users/admin?updateMask.fieldPaths=isActive', 'admin', {isActive:false}, false);
  await check('admin cannot change another role', 'PATCH', 'users/inactive?updateMask.fieldPaths=role', 'admin', {role:'admin'}, false);
  await check('admin cannot change another profile', 'PATCH', 'users/inactive?updateMask.fieldPaths=name', 'admin', {name:'Changed'}, false);
  await check('admin cannot change role alongside active status', 'PATCH', 'users/inactive?updateMask.fieldPaths=role&updateMask.fieldPaths=isActive', 'admin', {role:'admin',isActive:true}, false);
  await check('seed inactive admin', 'PATCH', 'users/disabled-admin', 'owner', {...customer,role:'admin',isActive:false}, true);
  await check('inactive admin cannot read another profile', 'GET', 'users/customer', 'disabled-admin', null, false);
  await check('inactive admin cannot change active status', 'PATCH', activeMask, 'disabled-admin', {isActive:true}, false);
  await check('seed active test product', 'PATCH', 'products/test-active', 'owner', {name:'TEST',isActive:true}, true);
  await check('seed inactive test product', 'PATCH', 'products/test-inactive', 'owner', {name:'TEST',isActive:false}, true);
  await checkActiveProductsQuery('customer');
  await checkActiveProductsQuery('inactive');
  await checkActiveProductsQuery('no-profile');
  await check('customer can read active product', 'GET', 'products/test-active', 'customer', null, true);
  await check('customer cannot read inactive product', 'GET', 'products/test-inactive', 'customer', null, false);
  await check('customer cannot list all products', 'GET', 'products', 'customer', null, false);
  await check('admin can list all products', 'GET', 'products', 'admin', null, true);
  await check('inactive customer can read active product', 'GET', 'products/test-active', 'inactive', null, true);
  await check('inactive admin can read active product', 'GET', 'products/test-active', 'disabled-admin', null, true);
  await check('user without profile can read active product', 'GET', 'products/test-active', 'no-profile', null, true);
  await check('inactive customer cannot read inactive product', 'GET', 'products/test-inactive', 'inactive', null, false);
  await check('inactive admin cannot read inactive product', 'GET', 'products/test-inactive', 'disabled-admin', null, false);
  await check('user without profile cannot read inactive product', 'GET', 'products/test-inactive', 'no-profile', null, false);
  await check('user without profile cannot list all products', 'GET', 'products', 'no-profile', null, false);
  await check('unauthenticated user cannot read products', 'GET', 'products/test-active', null, null, false);
  const product = {
    name:'TEST product', waterType:'Purified', description:'TEST description', imageUrl:null,
    isActive:false, createdAt:new Date('2025-01-01T00:00:00Z'),
    sizes:[{label:'TEST size',price:10,isAvailable:true}],
  };
  await check('admin creates product', 'PATCH', 'products/test-created', 'admin', product, true);
  await check('customer cannot create product', 'PATCH', 'products/customer-created', 'customer', product, false);
  await check('inactive admin cannot create product', 'PATCH', 'products/disabled-created', 'disabled-admin', product, false);
  await check('invalid product rejected', 'PATCH', 'products/bad', 'admin', {...product,isActive:'yes'}, false);
  await check('admin edits product', 'PATCH', 'products/test-created?updateMask.fieldPaths=name&updateMask.fieldPaths=sizes', 'admin', {name:'TEST updated',sizes:[{label:'TEST large',price:25,isAvailable:false}]}, true);
  await check('customer cannot edit product', 'PATCH', 'products/test-created?updateMask.fieldPaths=name', 'customer', {name:'Changed'}, false);
  await check('customer cannot edit product prices', 'PATCH', 'products/test-created?updateMask.fieldPaths=sizes', 'customer', {sizes:[{label:'TEST size',price:0.01,isAvailable:true}]}, false);
  await check('inactive admin cannot edit product', 'PATCH', 'products/test-created?updateMask.fieldPaths=name', 'disabled-admin', {name:'Changed'}, false);
  await check('user without profile cannot edit product', 'PATCH', 'products/test-created?updateMask.fieldPaths=name', 'no-profile', {name:'Changed'}, false);
  await check('admin cannot change created timestamp', 'PATCH', 'products/test-created?updateMask.fieldPaths=createdAt', 'admin', {createdAt:new Date('2026-01-01T00:00:00Z')}, false);
  await check('admin activates product', 'PATCH', 'products/test-created?updateMask.fieldPaths=isActive', 'admin', {isActive:true}, true);
  await check('customer sees activated product', 'GET', 'products/test-created', 'customer', null, true);
  await check('admin deactivates product', 'PATCH', 'products/test-created?updateMask.fieldPaths=isActive', 'admin', {isActive:false}, true);
  await check('customer cannot see deactivated product', 'GET', 'products/test-created', 'customer', null, false);
  await check('admin can still read deactivated product', 'GET', 'products/test-created', 'admin', null, true);
  await check('admin cannot delete product', 'DELETE', 'products/test-created', 'admin', null, false);
  await check('customer cannot delete product', 'DELETE', 'products/test-created', 'customer', null, false);
  await check('unauthenticated user cannot delete product', 'DELETE', 'products/test-created', null, null, false);
  await checkDirectOrderCreation();
  const order = {
    orderNumber:'RH-20250101-0001', customerId:'customer', customerName:'Name',
    phone:'09', address:'Address', notes:'', orderType:'purchase',
    pickupRequestedAt:null, pickupScheduledAt:null,
    deliveryRequestedAt:new Date('2027-01-01T00:00:00Z'),
    deliveryScheduledAt:null, items:[{
      waterType:'Purified', productName:'TEST product', sizeLabel:'TEST size',
      quantity:1, unitPrice:9999, lineTotal:9999,
    }],
    totalAmount:'9999', paymentMethod:'Cash on Delivery', status:'Pending',
      statusHistory:[{
        status:'Pending', timestamp:new Date('2025-01-01T00:00:00Z'),
        changedBy:'customer',
      }],
      createdAt:new Date('2025-01-01T00:00:00Z'),
    updatedAt:new Date('2025-01-01T00:00:00Z'),
  };
  await check('seed another customer order', 'PATCH', 'orders/other-order', 'owner', {...order,customerId:'other'}, true);
  await check('customer cannot read another customer order', 'GET', 'orders/other-order', 'customer', null, false);
  await check('seed own customer order', 'PATCH', 'orders/customer-order', 'owner', order, true);
  await check('customer can read own order', 'GET', 'orders/customer-order', 'customer', null, true);
  await check('customer cannot change own order price', 'PATCH', 'orders/customer-order?updateMask.fieldPaths=totalAmount', 'customer', {totalAmount:'0.01'}, false);
  await check('seed pending order for status transition probe', 'PATCH', 'orders/status-probe', 'owner', {...order,customerId:'other'}, true);
  const statusMask = 'orders/status-probe?updateMask.fieldPaths=status&updateMask.fieldPaths=statusHistory&updateMask.fieldPaths=updatedAt&updateMask.fieldPaths=deliveryScheduledAt';
  await check('admin cannot skip Pending directly to Delivered', 'PATCH', statusMask, 'admin', {
      status:'Delivered',
      statusHistory:[...order.statusHistory,{status:'Delivered',timestamp:new Date('2025-01-02T00:00:00Z'),changedBy:'admin'}],
      updatedAt:new Date('2025-01-02T00:00:00Z'),
  }, false);
  const confirmedAt = new Date('2025-01-02T00:00:00Z');
  await check('admin can transition Pending to Confirmed', 'PATCH', statusMask, 'admin', {
      status:'Confirmed',
      statusHistory:[...order.statusHistory,{status:'Confirmed',timestamp:confirmedAt,changedBy:'admin'}],
      updatedAt:confirmedAt,
      deliveryScheduledAt:new Date('2027-01-02T00:00:00Z'),
  }, true);
  const preparingAt = new Date('2025-01-03T00:00:00Z');
  await check('admin can transition Confirmed to Preparing', 'PATCH', statusMask, 'admin', {
      status:'Preparing',
      statusHistory:[...order.statusHistory,
        {status:'Confirmed',timestamp:confirmedAt,changedBy:'admin'},
        {status:'Preparing',timestamp:preparingAt,changedBy:'admin'}],
      updatedAt:preparingAt,
      deliveryScheduledAt:new Date('2027-01-02T00:00:00Z'),
  }, true);
  await check('seed pending order for rejection probe', 'PATCH', 'orders/reject-probe', 'owner', {...order,customerId:'other'}, true);
  const rejectMask = 'orders/reject-probe?updateMask.fieldPaths=status&updateMask.fieldPaths=statusHistory&updateMask.fieldPaths=updatedAt&updateMask.fieldPaths=cancellationReason';
  const rejectedAt = new Date('2025-01-02T00:00:00Z');
  await check('admin cannot reject without a reason', 'PATCH', rejectMask, 'admin', {
      status:'Cancelled',
      statusHistory:[...order.statusHistory,{status:'Cancelled',timestamp:rejectedAt,changedBy:'admin'}],
      updatedAt:rejectedAt,
  }, false);
  await check('admin can reject with a reason', 'PATCH', rejectMask, 'admin', {
      status:'Cancelled',
      statusHistory:[...order.statusHistory,{status:'Cancelled',timestamp:rejectedAt,changedBy:'admin'}],
      updatedAt:rejectedAt,
      cancellationReason:'Unable to serve this address.',
  }, true);
  await check('incomplete order rejected', 'PATCH', 'orders/order1', 'customer', {owner:'customer'}, false);
  await check('inactive users cannot access orders', 'GET', 'orders/order1', 'inactive', null, false);
  await check('unauthenticated access denied', 'GET', 'users/customer', null, null, false);
}
main().catch(error => { console.error(error); process.exitCode = 1; });
