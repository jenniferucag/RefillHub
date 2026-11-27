# Customer My Orders Screen

## Overview
Customer-facing order management interface with real-time status updates, order progress tracking via visual stepper, and order cancellation functionality.

## Features

### 1. My Orders Screen (Tab-Based)
**File:** `lib/features/orders/presentation/my_orders_screen.dart`

#### Current Orders Tab
- Shows all active orders (Pending, Confirmed, Preparing, Out for Delivery)
- Orders displayed as cards showing:
  - Order number (e.g., RH-20241126-0001)
  - Total amount with green emphasis
  - Item count
  - Status badge with color coding
  - Arrow indicating clickable detail view

#### History Tab
- Shows completed and cancelled orders
- Orders displayed in same card format as Current tab
- Allows customers to review past transactions

#### Search & Organization
- Newest orders displayed first (via Firestore stream)
- Empty state messages for each tab
- Smooth tab transitions

#### Status Color Coding
- 🟠 Pending → Orange
- 🔵 Confirmed → Blue
- 🟣 Preparing → Purple
- 🔷 Out for Delivery → Cyan
- 🟢 Delivered → Green
- 🔴 Cancelled → Red

### 2. Customer Order Details Screen
**File:** `lib/features/orders/presentation/customer_order_details_screen.dart`

#### Real-Time Updates
- Uses `watchOrderProvider` for Firestore snapshots
- Status changes made by admin appear without page refresh
- Order history automatically updates as admin transitions statuses

#### Order Header
- Order number
- Order creation date/time
- Current status badge

#### Status Stepper
- Visual stepper showing progress through order lifecycle
- Shows all 5 status levels: Pending → Confirmed → Preparing → Out for Delivery → Delivered
- Completed steps shown with status color
- Current step highlighted in bold
- Connecting lines show completion progress (green when completed)
- Steps numbered 1-5 in circles
- Status labels below each step for clarity
- **Hidden when order is Cancelled**

#### Cancelled State Alert
- Red banner with info icon
- Clear messaging: "Order Cancelled"
- Explanation: "This order was cancelled by you"
- Only shown when status is 'Cancelled'

#### Items List
- Product name
- Size label
- Quantity and unit price
- Line total (quantity × unit price)
- Dividers between items for clarity

#### Delivery Information
- Customer name
- Phone number
- Delivery address
- Displayed in readable format

#### Order Summary
- Total amount (prominent green text, 18pt bold)
- Payment method used

#### Notes Section
- Displays order notes if present
- Hidden if no notes

#### Status History Timeline
- Vertical timeline of all status transitions
- Each entry shows:
  - Colored dot matching status color
  - Status name
  - Exact timestamp (YYYY-MM-DD HH:MM format)
  - Vertical line connecting timeline entries
  - Dots and labels show progression chronologically

#### Cancel Order Button
- **Only visible for Pending orders**
- Red button for clear action intent
- Triggers confirmation dialog
- Confirmation dialog:
  - Asks "Are you sure you want to cancel this order?"
  - Notes: "This action cannot be undone."
  - Two buttons: "Keep Order" and "Cancel Order"
  - Red styling on confirm button
- Shows loading state during cancellation
- Success snackbar notification
- Auto-pops to list on successful cancellation
- Error snackbar if cancellation fails

## Data Flow

### Real-Time Status Updates
1. Customer opens My Orders → MyOrdersScreen
2. Navigates to order detail → CustomerOrderDetailsScreen
3. Screen watches specific order via `watchOrderProvider(orderId)`
4. Firestore stream emits updates when admin changes order status
5. Widget rebuilds with latest order data
6. Status stepper reflects new status
7. Status history timeline updates automatically

### Order Cancellation Flow
1. Customer taps "Cancel Order" (only visible for Pending orders)
2. Confirmation dialog displays
3. Customer confirms or cancels
4. If confirmed:
   - `updateOrderStatus()` called with 'Cancelled' status
   - Customer's UID stored in statusHistory
   - Firestore transaction updates order
   - Success snackbar shown
   - Screen pops back to list
5. If not confirmed:
   - Dialog dismissed
   - No changes made

## Technical Details

### Riverpod Providers Used
- `customerOrdersProvider(userId)` - StreamProvider for all customer orders
  - Auto-updates when new orders placed or statuses change
  - Separates current vs history orders client-side
  
- `watchOrderProvider(orderId)` - StreamProvider for single order
  - Real-time updates for order details screen
  - Emits entire order object on any change
  - Handles null gracefully (order deleted)

### Firestore Queries
- **Fetch customer orders**: `orders` collection → filter by `customerId` → sort by `createdAt` DESC
- **Watch single order**: Document listener on specific order ID
- **Update order status**: Batch write with:
  - New status
  - Append statusHistory entry with timestamp and customer UID
  - Update `updatedAt` timestamp

### UI Patterns
- **Tab Controller**: Manages Current/History tabs
- **FutureBuilder**: Handles async order fetching
- **StreamProvider**: Real-time Firestore updates
- **Navigator**: Card tap → detail screen navigation
- **Dialog**: Confirmation before cancellation

## Firestore Security Rules Impact

Customers can:
- ✅ Read only their own orders (enforced by customerId check)
- ✅ Create orders with status 'Pending' (enforced at checkout)
- ✅ Update their own Pending orders to 'Cancelled' status only (enforced by rules)
- ❌ Update any other fields
- ❌ Update non-Pending orders
- ❌ Delete orders

Admins can:
- ✅ Read all orders
- ✅ Update order status to any value
- ✅ Add status history entries with admin UID
- ✅ Assign delivery person
- ✅ Update updatedAt timestamp
- ❌ Delete orders

## User Experience Flows

### Browse Orders
1. Customer taps "Orders" in bottom nav
2. MyOrdersScreen opens with Current tab active
3. Active orders displayed as cards
4. Customer can switch to History tab to view past orders
5. Newest orders appear first

### View Order Details
1. Customer taps order card
2. CustomerOrderDetailsScreen opens
3. Stepper shows current progress
4. Status history shows all past transitions
5. If admin updates status while viewing, page auto-updates
6. Customer sees real-time progress updates

### Cancel Pending Order
1. Customer views Pending order details
2. Red "Cancel Order" button visible at bottom
3. Customer taps button
4. Confirmation dialog appears
5. Customer confirms cancellation
6. Order status changes to Cancelled
7. Stepper hidden, cancelled alert shown
8. Screen pops back to list (now shows in History tab)

## Edge Cases Handled

- **Order not found**: Shows error message
- **Network error**: Shows snackbar with error details
- **Cancelled while viewing**: Stepper hidden, alert shown, cancel button removed
- **Empty tabs**: Appropriate empty state messages
- **Null delivery notes**: Notes section hidden
- **Very long product names**: Text wrapping in items list
- **Multiple status changes**: Timeline shows all changes chronologically

## Testing Checklist

- [ ] Current tab shows only active orders (not Delivered/Cancelled)
- [ ] History tab shows only completed and cancelled orders
- [ ] Orders sorted newest first in both tabs
- [ ] Empty state shows for tabs with no orders
- [ ] Clicking order card navigates to details screen
- [ ] Status stepper displays correctly for all statuses
- [ ] Stepper hidden when order is Cancelled
- [ ] Cancelled alert only shows for Cancelled orders
- [ ] Status history timeline displays all transitions
- [ ] Real-time update: Admin changes status → customer sees update without refresh
- [ ] Cancel button only visible for Pending orders
- [ ] Cancel button disabled during cancellation (shows loading)
- [ ] Confirmation dialog requires explicit confirm
- [ ] Cancelled orders appear in History tab
- [ ] Error handling works for network failures
- [ ] All text is readable and properly formatted
- [ ] Status colors consistent with admin and other screens

## Files Created/Modified

### Created
- `lib/features/orders/presentation/my_orders_screen.dart` - Customer orders list with tabs
- `lib/features/orders/presentation/customer_order_details_screen.dart` - Order details with stepper

### Modified
- `lib/features/orders/presentation/orders_screen.dart` - Updated to use MyOrdersScreen
- (No data layer changes needed - reuses existing repository methods)

## Architecture Notes

1. **Real-Time Updates**: Uses Firestore snapshots via Riverpod StreamProviders rather than polling
2. **Client-Side Filtering**: Current vs History filtering done in Dart (simple list operations)
3. **Stateful Widget**: MyOrdersScreen uses ConsumerStatefulWidget to manage TabController
4. **Immutable Order Data**: Order objects are immutable, entire object re-emitted on any change
5. **Provider Caching**: Riverpod auto-disposes providers when widget is unmounted
6. **Error Boundaries**: Each async operation has error handling with user feedback
