# Firestore Security Rules - Orders

The rules are defined in [firestore.rules](./firestore.rules). Customers create
orders directly in Firestore; no callable or server-side order creation is
required.

## Order creation

Only an active customer may create an order, and only with their own UID as
`customerId`. New orders must have status `Pending`, use Cash on Delivery, and
include a valid order number, customer details, requested delivery timestamp,
items, initial status history, and server-generated `createdAt` /
`updatedAt` timestamps.

Purchase documents use `orderType: "purchase"`, have a null pickup request and
schedule, and store water type on each item. Refill documents use
`orderType: "refill"` and also include `waterType`, `containerSize`,
`containerCount`, and a requested pickup timestamp. Both schedules start as
null. When the refill price is not configured, `totalAmount`, item `unitPrice`,
and `lineTotal` are null so no price is invented.

The application re-reads active product and size data when placing the order.
Purchase prices come from product sizes; refill prices come from the size's
optional `refillPrice`. Each item stores a snapshot of its water type, product
name, size, unit price, quantity, and line total.

## Reading and updates

- Customers can read their own orders; admins can read all orders.
- Customers can cancel only their own `Pending` order.
- Admins can update only the fields needed for status changes, schedules,
  cancellation reasons, and delivery-person assignment.
- Status transitions and status-history appends are validated by the rules.
- Orders cannot be deleted.

Purchase status path: Pending → Confirmed → Preparing → Out for Delivery →
Delivered.

Refill status path: Pending → Confirmed → Picked Up → Preparing → Out for
Delivery → Delivered.

Admins may cancel before Preparing. Customers may cancel only while Pending.
Admin confirmation sets the accepted or edited schedule; refill confirmation
also requires pickup to precede delivery.

## Rule tests

`test/firestore_rules_test.js` covers direct customer creation for purchase and
refill orders, rejects invalid ownership/status, and checks subsequent access
and transition behavior against the Firestore emulator.
