# Customer My Orders - Visual & Feature Guide

## Screen Flow Diagram

```
Bottom Nav: Orders Tab
        ↓
MyOrdersScreen (TabBar)
  ├─ Current Tab
  │   └─ Active Orders List
  │      ├─ Pending orders
  │      ├─ Confirmed orders
  │      ├─ Preparing orders
  │      └─ Out for Delivery orders
  │         ↓ (tap card)
  │   CustomerOrderDetailsScreen
  │      ├─ Order Header
  │      ├─ Status Stepper (interactive visual)
  │      ├─ Items List
  │      ├─ Delivery Info
  │      ├─ Order Summary
  │      ├─ Status History Timeline
  │      └─ Cancel Button (Pending only)
  │
  └─ History Tab
      └─ Completed Orders List
         ├─ Delivered orders
         ├─ Cancelled orders
            ↓ (tap card)
         CustomerOrderDetailsScreen
            ├─ Order Header
            ├─ Cancelled Alert (if cancelled)
            ├─ Items List
            ├─ Delivery Info
            ├─ Order Summary
            └─ Status History Timeline
```

## Status Stepper Visual

### Order is Pending:
```
1 ● ━━━━ 2 ○ ━━━━ 3 ○ ━━━━ 4 ○ ━━━━ 5 ○
Pending  Confirmed Preparing Out for  Delivered
                           Delivery
```

### Order is Confirmed:
```
1 ● ━━━━ 2 ● ━━━━ 3 ○ ━━━━ 4 ○ ━━━━ 5 ○
Pending  Confirmed Preparing Out for  Delivered
                           Delivery
```

### Order is Preparing:
```
1 ● ━━━━ 2 ● ━━━━ 3 ● ━━━━ 4 ○ ━━━━ 5 ○
Pending  Confirmed Preparing Out for  Delivered
                           Delivery
```

### Order is Out for Delivery:
```
1 ● ━━━━ 2 ● ━━━━ 3 ● ━━━━ 4 ● ━━━━ 5 ○
Pending  Confirmed Preparing Out for  Delivered
                           Delivery
```

### Order is Delivered:
```
1 ● ━━━━ 2 ● ━━━━ 3 ● ━━━━ 4 ● ━━━━ 5 ●
Pending  Confirmed Preparing Out for  Delivered
                           Delivery
```

### Order is Cancelled:
```
[Stepper hidden]
┌─────────────────────────────────┐
│ ⓘ Order Cancelled               │
│   This order was cancelled      │
│   by you.                       │
└─────────────────────────────────┘
```

## Order Card Layout (Current & History)

```
╔════════════════════════════════════════╗
║ RH-20241126-0001              Pending  ║ ← Order number, Status badge (orange)
║ Total: ₱4,500                          ║ ← Total amount in green
║ 3 items                       ➜        ║ ← Item count, Arrow indicator
╚════════════════════════════════════════╝
```

## Order Details Screen Layout

### Header Section
```
╔════════════════════════════════════════╗
║ RH-20241126-0001                       ║
║ 2024-11-26 10:30                       ║
║                           Pending      ║ ← Status badge
╚════════════════════════════════════════╝
```

### Status Stepper Section
```
Order Progress
1 ● ━━━━ 2 ○ ━━━━ 3 ○ ━━━━ 4 ○ ━━━━ 5 ○
Pending  Confirmed Preparing Out for  Delivered
                           Delivery
```

### Items Section
```
Items (3)
╔════════════════════════════════════════╗
║ Water Bottle 1L         1x ₱500        ║
║ 1L                      = ₱500         ║
├────────────────────────────────────────┤
║ Detergent Powder        2x ₱1,500      ║
║ 1kg                     = ₱3,000       ║
├────────────────────────────────────────┤
║ Cloth Cleaner           2x ₱250        ║
║ 500ml                   = ₱500         ║
╚════════════════════════════════════════╝
```

### Delivery Information Section
```
Delivery Information
╔════════════════════════════════════════╗
║ Name        John Doe                   ║
║ Phone       +63 912 345 6789           ║
║ Address     123 Main St, Manila, NCR   ║
╚════════════════════════════════════════╝
```

### Order Summary Section
```
╔════════════════════════════════════════╗
║ Total Amount:        ₱4,500            ║ ← Large green text
║ Payment Method:      Cash on Delivery  ║
╚════════════════════════════════════════╝
```

### Status History Timeline Section
```
Status History
╔════════════════════════════════════════╗
║ ● Pending                              ║
║   2024-11-26 10:30                     ║
│  
│ ● Confirmed                            ║
│   2024-11-26 10:35                     ║
│  
│ ● Preparing (current)                  ║
│   2024-11-26 11:00                     ║
╚════════════════════════════════════════╝
```

## Cancelled Order Alert

```
╔════════════════════════════════════════╗
║ ⓘ Order Cancelled                      ║
║   This order was cancelled by you.     ║
╚════════════════════════════════════════╝
```

## Cancel Order Confirmation Dialog

```
╔════════════════════════════════════════╗
║ Cancel Order?                          ║
├────────────────────────────────────────┤
║ Are you sure you want to cancel this   ║
║ order? This action cannot be undone.   ║
├────────────────────────────────────────┤
║ [Keep Order]  [Cancel Order (RED)]     ║
╚════════════════════════════════════════╝
```

## Real-Time Update Scenario

### Admin Updates Order
Admin dashboard shows "Start Preparing" and clicks it
↓
Firestore: order.status = "Confirmed" → "Preparing"
           order.statusHistory.append({status: "Preparing", timestamp, changedBy: admin_uid})
↓
Firestore sends update to all listeners
↓
Customer watching order sees instant update:
  - Status badge changes from Blue (Confirmed) to Purple (Preparing)
  - Stepper updates to show step 3 as current
  - Status history timeline adds new entry
  - NO page refresh needed
↓
Customer continues viewing without interruption

## Tab Switching

### Current Orders → History
```
Current               History
Active Orders ──→ Completed/Cancelled
Pending              Orders
Confirmed            Delivered
Preparing            Cancelled
Out for Delivery
```

## Empty States

### Empty Current Orders
```
         🛍️ (shopping bag icon)
      No active orders
    Your active orders will
         appear here
```

### Empty History Orders
```
         🛍️ (shopping bag icon)
      No order history
   Your completed orders
         will appear here
```

## Error States

### Network Error
```
         ❌ Error
      Unable to load orders
      Please check your connection
```

## Status Color Scheme

| Status | Color | Hex | Usage |
|--------|-------|-----|-------|
| Pending | Orange | #FFA500 | Order just placed, awaiting confirmation |
| Confirmed | Blue | #2196F3 | Order confirmed by admin |
| Preparing | Purple | #9C27B0 | Order being prepared |
| Out for Delivery | Cyan | #00BCD4 | Order out with delivery person |
| Delivered | Green | #4CAF50 | Order successfully delivered |
| Cancelled | Red | #F44336 | Order cancelled by customer |

## User Interactions

### Scenario 1: Track Order Progress
1. Customer opens Orders tab
2. Sees "Pending" order in Current tab
3. Taps order card
4. Sees stepper at step 1 (Pending)
5. Waits a bit...
6. Admin confirms order → stepper jumps to step 2
7. Admin starts preparing → stepper jumps to step 3
8. Admin marks out for delivery → stepper jumps to step 4
9. Admin marks delivered → stepper completes to step 5
10. Order disappears from Current tab, appears in History tab

### Scenario 2: Cancel Pending Order
1. Customer views Pending order
2. Sees red "Cancel Order" button
3. Taps button
4. Confirmation dialog appears
5. Customer taps "Cancel Order"
6. Status changes to Cancelled
7. Stepper disappears
8. Red alert banner shows "Order Cancelled"
9. Screen pops to list
10. Order now in History tab with Cancelled badge

### Scenario 3: View Past Delivery
1. Customer switches to History tab
2. Sees list of delivered and cancelled orders
3. Taps a delivered order card
4. Views full order details
5. Sees completed stepper (all 5 steps filled)
6. Views entire status history
7. No cancel button (order already delivered)

## Accessibility Features

- Clear contrast ratios for status colors
- Status text labels in addition to colors (not color-only indicators)
- Readable font sizes (12-18pt)
- Proper touch targets (minimum 48x48dp for buttons)
- Descriptive icons with text labels
- Clear empty state messaging
- Proper semantic structure with sections

## Performance Considerations

- Lazy loading of images (not applicable here, but good practice)
- Riverpod auto-disposal of streams when widget unmounted
- Efficient re-builds (only when new data from Firestore)
- No unnecessary re-renders between tabs
- Efficient list building with itemBuilder
