# Customer My Orders - Quick Implementation Reference

## What Was Built

### 1. My Orders Screen - Two-Tab Interface
**Location**: `lib/features/orders/presentation/my_orders_screen.dart`

```dart
class MyOrdersScreen extends ConsumerStatefulWidget
  - Current Tab: Shows active orders (not Delivered/Cancelled)
  - History Tab: Shows completed and cancelled orders
  - Tab switching with TabController
  - Order cards show: order number, total, item count, status
  - Newest orders first (from watchCustomerOrders stream)
```

**Key Features**:
- Real-time order list via `customerOrdersProvider`
- Filtering logic: `order.status != 'Delivered' && order.status != 'Cancelled'` for Current
- Empty state messages for each tab
- Tap navigation to `CustomerOrderDetailsScreen`

---

### 2. Customer Order Details Screen - Real-Time Updates
**Location**: `lib/features/orders/presentation/customer_order_details_screen.dart`

```dart
class CustomerOrderDetailsScreen extends ConsumerStatefulWidget
  - Receives: initialOrder (passed on navigation)
  - Watches: watchOrderProvider(orderId) for real-time updates
  - Shows all order details with sections:
    * Order Header (number, date, status badge)
    * Status Stepper (visual progress: 1→5)
    * Cancelled Alert (red banner if status = 'Cancelled')
    * Items List
    * Delivery Information
    * Order Summary (total, payment method)
    * Notes (if present)
    * Status History Timeline
    * Cancel Button (Pending only)
```

**Real-Time Magic**:
```dart
final orderAsync = ref.watch(watchOrderProvider(widget.initialOrder.id));

orderAsync.when(
  data: (order) {
    // Widget rebuilds when Firestore sends update
    // No refresh button needed
    // Admin status changes appear instantly
  }
)
```

---

## Status Stepper Implementation

### Visual Flow
```
1 ● ━━━━ 2 ○ ━━━━ 3 ○ ━━━━ 4 ○ ━━━━ 5 ○
Pending  Confirmed Preparing Out for  Delivered
                           Delivery
```

**Code Logic**:
```dart
class _StatusStepper extends StatelessWidget {
  static const statusSequence = [
    'Pending', 'Confirmed', 'Preparing', 
    'Out for Delivery', 'Delivered'
  ];
  
  int currentIndex = statusSequence.indexOf(status);
  
  // Show circles 1-5
  // Completed steps (< currentIndex) = colored
  // Current step = bold + colored
  // Future steps = grey
  // Connecting lines = green if completed
}
```

**When Cancelled**:
- Stepper is completely hidden with `SizedBox.shrink()`
- Red alert banner shown instead

---

## Real-Time Update Flow

### The Magic: Firestore Snapshots
```
Admin Screen                     Customer Screen
─────────────                    ───────────────
Clicks "Confirm"      ──────→    
Dialog confirms       
                                 watchOrderProvider listening...
Updates Firestore:               ↓
  status: Confirmed              Receives snapshot
  statusHistory.append()         ↓
  updatedAt: now                 Widget rebuilds
                                 ↓
                      ←────────  Stepper shows step 2
                                 Status history timeline updated
                                 No manual refresh needed
```

### Implementation
```dart
// Customer watching order
final orderAsync = ref.watch(watchOrderProvider(orderId));

// When admin updates in Firestore:
// updateOrderStatus(orderId, newStatus, adminUid) {
//   ordersRef.doc(orderId).update({
//     'status': newStatus,
//     'statusHistory': FieldValue.arrayUnion([...]),
//     'updatedAt': FieldValue.serverTimestamp(),
//   });
// }

// Firestore automatically sends update to watchOrderProvider listener
// Widget.build() runs again with new order data
// UI updates in real-time
```

---

## Cancel Order Implementation

### UI Only Shows for Pending
```dart
if (order.status == 'Pending')
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isCancelling ? null : _cancelOrder,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
      ),
      child: Text(_isCancelling ? 'Cancelling...' : 'Cancel Order'),
    ),
  ),
```

### Cancellation Flow
```dart
Future<void> _cancelOrder() async {
  // 1. Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel Order?'),
      content: const Text('Are you sure? This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), ...),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), ...),
      ],
    ),
  );
  
  if (confirmed != true) return;
  
  // 2. Update order status
  setState(() => _isCancelling = true);
  try {
    await repository.updateOrderStatus(
      widget.initialOrder.id,
      'Cancelled',
      userId, // Customer's UID
    );
    
    // 3. Show success and pop
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order cancelled successfully')),
    );
    Navigator.pop(context);
  } catch (e) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

## Firestore Security Rules for Customers

```
match /orders/{orderId} {
  // Customers can read only their own orders
  allow read: if activeUser()
    && resource.data.customerId == request.auth.uid;

  // Customers can update only to cancel Pending orders
  allow update: if activeUser()
    && resource.data.customerId == request.auth.uid
    && resource.data.status == 'Pending'
    && request.resource.data.diff(resource.data).affectedKeys()
       .hasOnly(['status', 'statusHistory', 'updatedAt'])
    && request.resource.data.status == 'Cancelled'
    && request.resource.data.statusHistory is list
    && request.resource.data.updatedAt is timestamp;
}
```

---

## Status History Timeline

### Data Structure (from OrderStatusHistory)
```dart
class OrderStatusHistory {
  final String status;           // "Pending", "Confirmed", etc.
  final DateTime timestamp;      // When changed
  final String changedBy;        // User ID who made change
}

// Example timeline:
[
  OrderStatusHistory(status: 'Pending', timestamp: 2024-11-26T10:30, changedBy: 'cust123'),
  OrderStatusHistory(status: 'Confirmed', timestamp: 2024-11-26T10:35, changedBy: 'admin456'),
  OrderStatusHistory(status: 'Preparing', timestamp: 2024-11-26T11:00, changedBy: 'admin456'),
]
```

### UI Rendering
```dart
Column(
  children: order.statusHistory.asMap().entries.map((entry) {
    final history = entry.value;
    final isFirst = entry.key == 0;
    
    return Column(
      children: [
        if (!isFirst) const Divider(height: 16),
        Row(
          children: [
            Column(
              children: [
                // Dot with status color
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(history.status),
                  ),
                ),
                // Vertical line to next entry
                if (!isFirst)
                  Container(width: 2, height: 20, color: Colors.grey[300]),
              ],
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(history.status, style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(_formatDateTime(history.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }).toList(),
)
```

---

## Cancelled State Alert

### Shows Only When Cancelled
```dart
if (order.status == 'Cancelled')
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red[50],
      border: Border.all(color: Colors.red[300]!),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: Colors.red[700]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Cancelled', style: TextStyle(..., color: Colors.red[700])),
              SizedBox(height: 4),
              Text('This order was cancelled by you.', style: TextStyle(color: Colors.red[700])),
            ],
          ),
        ),
      ],
    ),
  ),
```

---

## Tab Switching Logic

### Tab Controller Setup
```dart
class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
```

### Filtering Logic
```dart
final currentOrders = orders
    .where((order) =>
        order.status != 'Delivered' && order.status != 'Cancelled')
    .toList();

final historyOrders = orders
    .where((order) =>
        order.status == 'Delivered' || order.status == 'Cancelled')
    .toList();
```

---

## Status Colors (Consistent Across All Screens)

```dart
Color _getStatusColor(String status) {
  return switch (status) {
    'Pending' => Colors.orange,
    'Confirmed' => Colors.blue,
    'Preparing' => Colors.purple,
    'Out for Delivery' => Colors.cyan,
    'Delivered' => Colors.green,
    'Cancelled' => Colors.red,
    _ => Colors.grey,
  };
}
```

---

## Navigation Integration

### From OrdersScreen (Entry Point)
```dart
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => const MyOrdersScreen();
}
```

### Order Card to Details
```dart
_OrderCard(
  order: order,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CustomerOrderDetailsScreen(initialOrder: order),
      ),
    );
  },
)
```

---

## Key Providers

```dart
// Watch all orders for current user (real-time)
final customerOrdersProvider = StreamProvider.autoDispose.family<List<CustomerOrder>, String>(
  (ref, customerId) {
    final repository = ref.watch(orderRepositoryProvider);
    return repository.watchCustomerOrders(customerId);
  },
);

// Watch single order (real-time for details screen)
final watchOrderProvider = StreamProvider.autoDispose.family<CustomerOrder?, String>(
  (ref, orderId) {
    final repository = ref.watch(orderRepositoryProvider);
    return repository.watchOrder(orderId);
  },
);
```

---

## Testing Quick Checklist

### Visual
- [ ] Current tab shows only active orders
- [ ] History tab shows only completed/cancelled
- [ ] Stepper shows correct progress (1-5)
- [ ] Stepper hidden when cancelled
- [ ] Cancelled alert only shows when status = Cancelled
- [ ] Cancel button only shows for Pending

### Real-Time
- [ ] Admin updates order → customer sees update instantly (no refresh)
- [ ] Multiple status changes tracked in history timeline
- [ ] Timestamps correct format (YYYY-MM-DD HH:MM)

### Functionality
- [ ] Tap order card opens details screen
- [ ] Tab switching works smoothly
- [ ] Empty states show when appropriate
- [ ] Cancel confirmation dialog required
- [ ] Cancelled orders move to History tab
- [ ] Error handling works (network failure, etc.)

---

## Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Stepper not updating | Not using watchOrderProvider | Use `ref.watch()` not `ref.read()` |
| Cancel button always shows | Status check wrong | Check `order.status == 'Pending'` exactly |
| Real-time update delays | Query/indexing issue | Verify Firestore listener is active |
| Cancelled alert doesn't show | Status check case-sensitive | Use exact string 'Cancelled' |
| Navigation doesn't work | Missing initialOrder parameter | Pass `initialOrder: order` on navigation |
| Stepper steps wrong | Status index calculation | statusSequence order must match status values |
