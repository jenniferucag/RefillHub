# Firestore Orders Rules - Quick Reference

## Permission Matrix

| Operation | Customer | Admin | Notes |
|-----------|----------|-------|-------|
| **CREATE** | ✅ Own, Pending only | ❌ N/A | Must use own ID, hardcoded Pending status |
| **READ** | ✅ Own orders | ✅ All orders | Complete isolation by customerId |
| **UPDATE** | ✅ Cancel Pending | ✅ All fields (status/history/time) | Customers: status→Cancelled only |
| **DELETE** | ❌ Blocked | ❌ Blocked | Permanent records, use Cancel instead |

## Rule Summary

```firestore-rules
match /orders/{orderId} {
  // CREATE: Active customers with own ID and Pending status
  allow create: if activeUser() 
    && request.resource.data.customerId == request.auth.uid
    && request.resource.data.status == 'Pending'
    && [all required fields present & typed]

  // READ: Customers see own, Admins see all
  allow read: if (activeUser() && resource.data.customerId == request.auth.uid)
    || admin()

  // UPDATE: Customers cancel Pending, Admins manage workflow
  allow update: if (activeUser() 
      && resource.data.customerId == request.auth.uid
      && resource.data.status == 'Pending'
      && request.resource.data.status == 'Cancelled'
      && [only status/statusHistory/updatedAt changed])
    || (admin() && [only status/statusHistory/updatedAt changed])

  // DELETE: Never allowed
  allow delete: if false
}
```

## Key Constraints

1. **On CREATE**
   - `activeUser()` required
   - `customerId` must equal `request.auth.uid`
   - `status` must be exactly `'Pending'`
   - All 12 fields required with correct types

2. **On READ**
   - Customers: `customerId == request.auth.uid`
   - Admins: No restrictions

3. **On UPDATE (Customer)**
   - Only modifiable: `status`, `statusHistory`, `updatedAt`
   - Only allowed if: `status == 'Pending'` currently
   - New status: Must be `'Cancelled'`

4. **On UPDATE (Admin)**
   - Only modifiable: `status`, `statusHistory`, `updatedAt`
   - New status: Any string value
   - Full workflow control

5. **On DELETE**
   - Always blocked (no exceptions)

## Field Types Enforced

```
orderNumber: string
customerId: string
customerName: string
phone: string
address: string
notes: string
items: array
totalAmount: string
paymentMethod: string
status: string
statusHistory: array
createdAt: timestamp
updatedAt: timestamp
```

## File Location

📄 `/firestore.rules` - Lines 68-121

## Related Documentation

- 📖 [ORDER_IMPLEMENTATION.md](ORDER_IMPLEMENTATION.md) - Order model details
- 📖 [FIRESTORE_ORDERS_RULES.md](FIRESTORE_ORDERS_RULES.md) - Detailed rule documentation
