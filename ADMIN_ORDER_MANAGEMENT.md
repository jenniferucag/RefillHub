# Admin Order Management System

## Overview
Comprehensive admin order management system for RefillHub with order list filtering/search, detailed order views, and status transition management.

## Features Implemented

### 1. Admin Order List Screen
**File:** `lib/features/orders/presentation/admin_orders_list_screen.dart`

Features:
- **Search functionality**: Search by order number or customer name (case-insensitive)
- **Status filter chips**: Quick filter by status (All, Pending, Confirmed, Preparing, Out for Delivery, Delivered, Cancelled)
- **Newest-first sorting**: Orders automatically sorted by creation date
- **Order cards** displaying:
  - Order number
  - Customer name
  - Status with color-coded badge
  - Total amount
  - Item count
  - Tap to view details

### 2. Admin Order Details Screen
**File:** `lib/features/orders/presentation/admin_order_details_screen.dart`

Sections:
- **Order Header**: Order number, status badge
- **Customer Information**: Name, phone, address
- **Items List**: Product name, size, quantity, unit price, line total
- **Order Summary**: Total amount, payment method
- **Notes**: Optional notes (displayed if present)
- **Delivery Person**: Optional text field to assign delivery person
- **Status History Timeline**: Visual timeline of all status changes with:
  - Status dot with color coding
  - Timestamp
  - Admin UID who made the change
- **Action Buttons**: Dynamic buttons based on current order status

### 3. Status Transition Logic
Supported transitions with admin confirmation:

| Current Status | Available Actions |
|---|---|
| Pending | Confirm Order, Reject Order (with reason) |
| Confirmed | Start Preparing |
| Preparing | Mark Out for Delivery |
| Out for Delivery | Mark Delivered |
| Delivered | No actions |
| Cancelled | No actions |

### 4. Status Color Coding
- **Pending**: Orange
- **Confirmed**: Blue
- **Preparing**: Purple
- **Out for Delivery**: Cyan
- **Delivered**: Green
- **Cancelled**: Red

## Data Model Updates

### CustomerOrder Model
**File:** `lib/features/orders/data/order.dart`

Added field:
- `deliveryPerson: String?` - Optional delivery person assignment

Updated methods:
- `toMap()`: Now returns `Map<String, Object?>` to handle nullable deliveryPerson
- `fromMap()`: Parses optional deliveryPerson field

### OrderRepository Extensions
**File:** `lib/features/orders/data/order_repository.dart`

New methods:
- `getAllOrders(): Future<List<CustomerOrder>>` - Fetch all orders (newest first)
- `watchAllOrders(): Stream<List<CustomerOrder>>` - Real-time all orders stream
- `searchOrders(String query): Future<List<CustomerOrder>>` - Search by order number or customer name
- `getOrdersByStatus(String status): Future<List<CustomerOrder>>` - Filter orders by status
- `updateDeliveryPerson(String orderId, String deliveryPerson): Future<void>` - Assign delivery person

### Riverpod Providers
**File:** `lib/features/orders/data/order_providers.dart`

New providers:
- `getAllOrdersProvider` - FutureProvider for fetching all orders (server source)
- `watchAllOrdersProvider` - StreamProvider for real-time all orders stream

## Firestore Security Rules Updates
**File:** `firestore.rules`

Admin-only order management with these permissions:

### Create Orders
- **Customers**: Can create with:
  - Their own `customerId`
  - Status must be `'Pending'`
  - Required fields validated

### Read Orders
- **Customers**: Can read only their own orders
- **Admins**: Can read all orders

### Update Orders
- **Customers**: Can update only to cancel `'Pending'` orders
- **Admins**: Can update:
  - `status` - New order status
  - `statusHistory` - Append status changes
  - `updatedAt` - Timestamp
  - `deliveryPerson` - Optional delivery person (string)

### Delete Orders
- **No one**: Deletes disabled for all users

## UI/UX Details

### Confirmation Dialogs
- Standard confirmation for status transitions (Confirm/Cancel)
- Special rejection dialog:
  - Text input for rejection reason
  - Reject button (red) / Cancel button

### Loading States
- Loading indicators during data fetch
- Disabled buttons during update operations
- Success/error snackbar notifications

### Error Handling
- Error displays in list view
- Error snackbars during updates
- Graceful handling of Firebase exceptions

## Navigation
- Admin Order List Screen accessible from admin dashboard
- Tap order card → Admin Order Details Screen
- Details screen shows full order info and available actions
- Changes auto-reflected with status history timeline

## Testing Checklist
- [ ] Admin can view all orders
- [ ] Search by order number works (case-insensitive)
- [ ] Search by customer name works
- [ ] Status filter chips work correctly
- [ ] Orders sorted newest-first
- [ ] Order details display all information correctly
- [ ] Status history timeline displays correctly
- [ ] Delivery person can be assigned
- [ ] All status transitions work with confirmation
- [ ] Rejection requires reason
- [ ] Status history updated with admin UID
- [ ] Firestore rules prevent unauthorized access
- [ ] Customers can only read own orders
- [ ] Customers can only cancel Pending orders

## Files Created/Modified

### Created
- `lib/features/orders/presentation/admin_order_details_screen.dart` - Details view with actions

### Modified
- `lib/features/orders/data/order_repository.dart` - Added admin query methods
- `lib/features/orders/data/order.dart` - Added deliveryPerson field
- `lib/features/orders/data/order_providers.dart` - Added admin providers
- `lib/features/orders/presentation/admin_orders_list_screen.dart` - Navigation to details
- `firestore.rules` - Admin order management permissions

## Architecture Decisions

1. **Client-side Search**: Search is performed client-side after fetching all orders. This simplifies implementation but loads full dataset. For production with many orders, consider Firestore full-text search.

2. **Status History as List**: Status history stored as immutable list in Firestore. Each transition appends a new entry with status, timestamp, and admin UID.

3. **DeliveryPerson Optional**: The deliveryPerson field is optional and only included in Firestore documents if set, keeping documents lean.

4. **Riverpod State Management**: Uses Riverpod providers for dependency injection and caching of order data.

5. **Status Color Consistency**: Status colors are consistent across list and detail views via centralized color mapping.
