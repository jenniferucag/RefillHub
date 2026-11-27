# Information Screens - Quick Reference

## Screens Overview

### 1. How to Order Screen
**Route**: `/info/how-to-order`

```
┌─────────────────────────────────┐
│ How to Order              ⬅️    │
├─────────────────────────────────┤
│                                 │
│ Ordering Information...          │
│                                 │
│ Steps to Order                  │
│                                 │
│ ┌──────────────────────────────┐│
│ │  ①  Step 1                   ││
│ │      First ordering step text ││
│ └──────────────────────────────┘│
│                                 │
│ ┌──────────────────────────────┐│
│ │  ②  Step 2                   ││
│ │      Second ordering step text││
│ └──────────────────────────────┘│
│                                 │
│ ┌──────────────────────────────┐│
│ │  ③  Step 3                   ││
│ │      Third ordering step text ││
│ └──────────────────────────────┘│
│                                 │
│    [🛒 Start Ordering]          │
│                                 │
└─────────────────────────────────┘
```

**Data Source**: BusinessInfo.orderingGuideSteps (array from Firestore)
**Features**:
- Numbered badges (1, 2, 3...)
- Full step descriptions
- Material design cards
- "Start Ordering" button navigates to /products

---

### 2. Delivery Information Screen
**Route**: `/info/delivery-information`

```
┌─────────────────────────────────┐
│ Delivery Information      ⬅️    │
├─────────────────────────────────┤
│                                 │
│ ┌──────────────────────────────┐│
│ │ 🕐 Operating Hours          ││
│ │   Monday-Friday: 9AM-6PM    ││
│ │   Saturday: 10AM-4PM        ││
│ └──────────────────────────────┘│
│                                 │
│ ┌──────────────────────────────┐│
│ │ 📍 Delivery Coverage        ││
│ │   Metro Manila and nearby... ││
│ └──────────────────────────────┘│
│                                 │
│ ┌──────────────────────────────┐│
│ │ 🚚 Delivery Policy          ││
│ │   Free delivery on orders... ││
│ └──────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

**Data Source**: 
- BusinessInfo.operatingHours
- BusinessInfo.deliveryCoverage
- BusinessInfo.deliveryPolicy

**Features**:
- Three info sections with icons
- Light background containers
- Empty state: "Not yet provided by RefillHub"
- Real-time updates from Firestore

---

### 3. About & Contact Screen
**Route**: `/info/about-contact`

```
┌─────────────────────────────────┐
│ RefillHub Information     ⬅️    │
├─────────────────────────────────┤
│                                 │
│ RefillHub                       │
│                                 │
│ About Us                        │
│ Eco-friendly water refill...    │
│                                 │
│ Contact Information             │
│ ┌──────────────────────────────┐│
│ │ ☎️  Phone                    ││
│ │    +63-999-123-4567      →   ││  (tap to call)
│ └──────────────────────────────┘│
│                                 │
│ ┌──────────────────────────────┐│
│ │ ✉️  Email                    ││
│ │    hello@refillhub.com   →   ││  (tap to email)
│ └──────────────────────────────┘│
│                                 │
│ Address                         │
│ 123 Main St, Manila            │
│                                 │
│ Operating Hours                 │
│ Mon-Fri: 9AM-6PM               │
│                                 │
│ ... (Delivery sections below)   │
│                                 │
└─────────────────────────────────┘
```

**Data Source**: BusinessInfo model (all fields)
**Features**:
- Tap phone number → Launches phone call
- Tap email → Opens email client
- Interactive contact cards with arrow icons
- Real-time streaming from Firestore
- All business information in one view

---

### 4. Navigation Drawer
**Accessible**: Menu button (☰) in AppBar on all customer screens

```
┌──────────────────────────────┐
│ ☰                            │
├──────────────────────────────┤
│                              │
│ 💧 RefillHub                │
│    Information & Support     │
│                              │
├──────────────────────────────┤
│ INFORMATION                  │
│                              │
│ 🛍️  How to Order            │
│ 🚚  Delivery Information     │
│ ℹ️  About & Contact          │
│ 💰  Pricing                  │
│                              │
└──────────────────────────────┘
```

**Features**:
- Menu button in AppBar (all screens)
- Four quick-access links
- Professional header with RefillHub branding
- Tap to navigate, drawer auto-closes
- Icons for visual identification

---

## User Flows

### Flow 1: Customer learns how to order
```
Home Screen
  → Tap "How to Order" card
    OR Menu → "How to Order"
  → View numbered steps
  → Tap "Start Ordering"
  → Go to Products screen
```

### Flow 2: Customer checks delivery info
```
Any Screen
  → Tap Menu (☰)
  → Tap "Delivery Information"
  → View hours, coverage, policy
  → Close and return
```

### Flow 3: Customer contacts RefillHub
```
Any Screen
  → Tap Menu (☰)
  → Tap "About & Contact"
  → Tap phone number
  → Phone call launches
```

### Flow 4: Customer calls RefillHub
```
BusinessInfo Screen
  → Tap phone number in Contact section
  → System opens phone app
  → Ready to dial
```

### Flow 5: Customer emails RefillHub
```
BusinessInfo Screen
  → Tap email in Contact section
  → Email client opens with compose window
  → Ready to type message
```

---

## Admin Updates Flow

**Admin Screen**: `/admin/business-info`

When admin updates any field:
1. Changes saved to Firestore
2. All customer screens update in real-time (via StreamProvider)
3. No app restart needed
4. All connected users see changes immediately

**Example Update**:
```
Admin enters:
  orderingGuideSteps: [
    "Browse our water refill options",
    "Add items to your cart",
    "Proceed to checkout",
    "Choose delivery time",
    "Complete payment",
    "Track your order"
  ]

Customer sees immediately:
  ✓ 6 numbered steps displayed
  ✓ Each with full description
  ✓ Ready to start ordering
```

---

## Integration with Home Screen

The Home Screen already has information link cards:

```
┌──────────────────────────────────────┐
│ Helpful information                  │
│ Pricing, ordering, delivery...       │
├──────────────────────────────────────┤
│                                      │
│ [💰 Pricing]  [🛍️ How to Order]  │
│ [🚚 Delivery] [ℹ️ About/Contact]  │
│                                      │
└──────────────────────────────────────┘
```

**Plus**: Menu button (☰) in AppBar gives quick drawer access to all info screens.

---

## Routes Summary

| Screen | Route | Linked From |
|--------|-------|-------------|
| How to Order | `/info/how-to-order` | Home cards, Drawer, Menu |
| Delivery Info | `/info/delivery-information` | Home cards, Drawer, Menu |
| About & Contact | `/info/about-contact` | Home cards, Drawer, Menu |
| Pricing | `/info/pricing` | Home cards, Drawer, Menu |

---

## Real-time Behavior

**Scenario**: Admin updates operating hours in `/admin/business-info`

```
Time 0:00s - Admin updates hours to "Mon-Fri 8AM-7PM"
Time 0.1s  - Saved to Firestore
Time 0.2s  - All StreamProviders notified
Time 0.3s  - Customer screen rebuilds
Time 0.5s  - New hours visible to customer
```

**Result**: Zero-delay updates across all customer screens showing business info.

---

## Error Handling Examples

### Empty/Missing Fields
```
Field not filled in Firestore:
  → Display: "Not yet provided by RefillHub"
  → Color: onSurfaceVariant (lighter text)
  → User understands info coming soon
```

### Phone/Email Not Configured
```
Field empty:
  → "Not yet provided by RefillHub" shown
  → Tap action disabled (no arrow icon)
  → No error when tapped

Field configured:
  → Actual phone/email shown
  → Arrow icon visible
  → Tap launches phone/email
```

### Network Error Loading Data
```
Error fetching from Firestore:
  → Circular progress shown
  → Error message displayed
  → Retry possible (reload screen)
```

---

## Accessibility Features

- ✅ Material Design compliance
- ✅ Large touch targets (48dp minimum)
- ✅ Semantic icons with labels
- ✅ High contrast text
- ✅ Clear visual hierarchy
- ✅ Dark mode support (via app theme)
- ✅ Keyboard navigable

---

## Performance Notes

- **Lazy Loading**: StreamProvider loads on demand
- **Caching**: Firestore caches data locally
- **Real-time**: WebSocket connection (via Firebase)
- **Responsive**: Works on 2G network with minor delay
- **Battery**: Minimal impact, Firebase handles optimization

---

## Admin Checklist

Before launching, fill in business info at `/admin/business-info`:

- [ ] Business name
- [ ] About us description
- [ ] Contact phone number (10+ digits)
- [ ] Contact email (valid format)
- [ ] Business address
- [ ] Operating hours
- [ ] Delivery coverage (service areas)
- [ ] Delivery policy (fees, minimums)
- [ ] Ordering guide steps (5-7 steps recommended)

**Recommendation**: Fill in all fields before making app public to avoid "Not yet provided" messages.
