# Admin Delivery Management - Feature Overview

## Architecture

```
Admin Dashboard (Real Counts)
├── Total Orders Count
├── Pending Orders Count
├── In Progress Count
├── Delivered Orders Count
└── Today's Orders List (Up to 10)
    ├── Order Number
    ├── Customer Name
    ├── Status Badge
    └── Total Amount

Admin Delivery Management Screen
├── Status Filter Chips
│   ├── All
│   ├── Confirmed
│   ├── Preparing
│   └── Out for Delivery
├── Summary Cards (By Status)
│   ├── Confirmed Count
│   ├── Preparing Count
│   └── Out for Delivery Count
└── Order Cards List
    ├── Order Header (Number + Customer)
    ├── Status Badge
    ├── Delivery Address
    ├── Phone Number
    ├── Delivery Person Input + Assign Button
    ├── Status Action Button (Contextual)
    └── Details Button
```

## Data Flow

```
Firestore Orders Collection
        ↓
OrderRepository.getAllOrders()
        ↓
getAllOrdersProvider (FutureProvider)
        ↓
├─→ totalOrdersCountProvider
├─→ pendingOrdersCountProvider
├─→ inProgressOrdersCountProvider
├─→ deliveredOrdersCountProvider
├─→ todayOrdersListProvider
└─→ todayOrdersCountProvider
        ↓
Admin Dashboard + Delivery Management Screen
```

## Screen Flow

### Admin Dashboard
```
┌─────────────────────────────────────┐
│ Operations overview                 │
│ A quick view of order activity      │
├─────────────────────────────────────┤
│                                     │
│ [Total] [Pending] [In Prog] [Done] │
│   248      18        12      218    │
│                                     │
├─────────────────────────────────────┤
│ Today's Orders                      │
│                                     │
│ RH-20250101-0001  | John  | ₱1500  │
│ RH-20250101-0002  | Sarah | ₱2000  │
│ RH-20250101-0003  | Mike  | ₱1200  │
│                                     │
└─────────────────────────────────────┘
```

### Delivery Management Screen
```
┌──────────────────────────────────────────────────────┐
│ Delivery Management                                  │
│ Manage order delivery status and assign personnel.   │
├──────────────────────────────────────────────────────┤
│ [All] [Confirmed] [Preparing] [Out for Delivery]    │
├──────────────────────────────────────────────────────┤
│                                                      │
│ ┌────────────────────────────────────────────────┐  │
│ │ Confirmed: 5  Preparing: 3  Out for Delivery: 7 │  │
│ └────────────────────────────────────────────────┘  │
│                                                      │
│ ┌────────────────────────────────────────────────┐  │
│ │ RH-20250101-0005        [Confirmed]            │  │
│ │ John Doe                                       │  │
│ │                                                │  │
│ │ Delivery: 123 Main St, Apt 4B                  │  │
│ │ Phone: 555-0123                                │  │
│ │                                                │  │
│ │ [Assign delivery person: ___________] [Assign]│  │
│ │                                                │  │
│ │ [Mark Preparing] [Details]                     │  │
│ └────────────────────────────────────────────────┘  │
│                                                      │
│ ┌────────────────────────────────────────────────┐  │
│ │ RH-20250101-0006        [Preparing]            │  │
│ │ Sarah Smith                                    │  │
│ │                                                │  │
│ │ Delivery: 456 Oak Ave                          │  │
│ │ Phone: 555-0456                                │  │
│ │                                                │  │
│ │ [Assign delivery person: John __] [Assign]    │  │
│ │                                                │  │
│ │ [Mark Out for Delivery] [Details]              │  │
│ └────────────────────────────────────────────────┘  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## Status Transition Flow

```
Pending
  ↓ (Customer places order OR Admin confirms)
Confirmed
  ↓ (Admin clicks "Mark Preparing")
Preparing
  ↓ (Admin clicks "Mark Out for Delivery")
Out for Delivery
  ↓ (Admin clicks "Mark Delivered")
Delivered

(Cancelled path: Pending → Cancelled)
```

## Component Breakdown

### AdminDeliveryManagementScreen
- **Type**: ConsumerStatefulWidget
- **State**: Selected status filter
- **Responsibilities**:
  - Load orders from Firestore
  - Filter by status
  - Display order cards
  - Render summary metrics

### _DeliveryOrderCard
- **Type**: ConsumerStatefulWidget
- **Local State**:
  - Delivery person text controller
  - Loading state
- **Responsibilities**:
  - Display order information
  - Handle delivery person assignment
  - Handle status transitions
  - Show order details dialog

### _DeliverySummary
- **Type**: StatelessWidget
- **Input**: List of delivery orders
- **Responsibilities**:
  - Count orders by status
  - Display metric cards
  - Responsive layout

### Admin Dashboard Updates
- **Type**: ConsumerWidget
- **Dependencies**: Riverpod providers
- **Responsibilities**:
  - Display real metrics via AsyncValue
  - Show today's orders
  - Handle loading/error states

## Riverpod Providers

```
FutureProvider<List<CustomerOrder>>
  └─ getAllOrdersProvider
      ├─ totalOrdersCountProvider: Future<int>
      ├─ pendingOrdersCountProvider: Future<int>
      ├─ inProgressOrdersCountProvider: Future<int>
      ├─ deliveredOrdersCountProvider: Future<int>
      ├─ todayOrdersListProvider: Future<List<CustomerOrder>>
      └─ todayOrdersCountProvider: Future<int>
```

## Color Scheme

| Status | Color | Hex |
|--------|-------|-----|
| Confirmed | Blue | #2196F3 |
| Preparing | Purple | #9C27B0 |
| Out for Delivery | Cyan | #00BCD4 |
| Delivered | Green | #4CAF50 |
| Pending | Orange | #FF9800 |
| Cancelled | Red | #F44336 |

## Error Handling

- Try-catch on all Firestore operations
- User-friendly error messages via SnackBar
- Loading state prevents double-taps
- Null-safety enforced throughout

## Performance Considerations

- Providers cache results until invalidated
- Filtering done in-memory (small dataset)
- Sorted by status priority (O(n log n))
- Dashboard counts recomputed on order changes
- No N+1 queries - single getAllOrders call
