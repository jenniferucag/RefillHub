# Business Information - Quick Reference

## 🚀 Quick Start

### Admin: Edit Business Info
1. Go to `/admin/business-info`
2. Fill in company details
3. Click "Save Changes"
4. See success message ✓

### Customer: View Business Info
1. Go to `/info/about-contact`
2. See all business information
3. Empty fields show: "Not yet provided by RefillHub"
4. Updates appear in real-time

---

## 📝 Fields Explained

| Field | Purpose | Example |
|-------|---------|---------|
| **Business Name** | Company name | RefillHub |
| **About** | Company description | Sustainable refillable products for your home... |
| **Contact Phone** | Customer service phone | +1 (555) 123-4567 |
| **Contact Email** | Customer service email | support@refillhub.com |
| **Address** | Business location | 123 Main St, City, State 12345 |
| **Operating Hours** | Hours of operation | Mon-Fri: 9am-6pm, Sat: 10am-4pm |
| **Delivery Coverage** | Service area | Delivery available within 5km radius |
| **Delivery Policy** | Shipping terms | Free delivery over $50, 2-3 day delivery |
| **Ordering Guide Steps** | How to order (list) | 1. Browse products<br/>2. Add to cart<br/>3. Checkout |

---

## 🏗️ File Structure

```
lib/features/info/
├── data/
│   ├── business_info.dart              ← Model
│   ├── business_info_repository.dart   ← Firestore ops
│   └── business_info_providers.dart    ← Riverpod providers
└── presentation/
    ├── business_info_screen.dart       ← Customer view
    └── info_screen.dart                (existing)

lib/features/admin/
├── data/                               ← New directory
└── presentation/
    └── admin_business_info_screen.dart ← Admin edit
```

---

## 🔥 Firestore Structure

```
Database: Firestore
Collection: config
Document: business_info
Fields:
  - businessName: string
  - about: string
  - contactPhone: string
  - contactEmail: string
  - address: string
  - operatingHours: string
  - deliveryCoverage: string
  - deliveryPolicy: string
  - orderingGuideSteps: array<string>
```

---

## 🔐 Security Rules

```firestore
// Signed-in users can read business_info
allow read: if signedIn() && document == 'business_info';

// Only admins can update business_info
allow update: if admin()
  && document == 'business_info'
  && [all fields are strings or string array]
```

---

## 🎯 Routes

| Route | Purpose | Access |
|-------|---------|--------|
| `/admin/business-info` | Edit business info | Admin only |
| `/info/about-contact` | View business info | Signed-in users |

---

## 💾 Data Model

```dart
class BusinessInfo {
  String businessName;
  String about;
  String contactPhone;
  String contactEmail;
  String address;
  String operatingHours;
  String deliveryCoverage;
  String deliveryPolicy;
  List<String> orderingGuideSteps;
}
```

---

## 🏃 Usage

### In Widgets

**Read-only (Customer View):**
```dart
final businessInfoAsync = ref.watch(businessInfoStreamProvider);
// Use AsyncValue pattern to handle loading/error/data
```

**Edit (Admin View):**
```dart
final repository = ref.read(businessInfoRepositoryProvider);
await repository.updateBusinessInfo(updatedInfo);
```

---

## ✅ Empty Field Handling

| Scenario | Display |
|----------|---------|
| Field is empty string | "Not yet provided by RefillHub" |
| Field has content | Actual content |
| Ordering guide is empty | Section not shown |
| Ordering guide has items | Numbered list (1, 2, 3...) |

---

## 🛠️ Common Tasks

### Add a New Field

1. Add to `BusinessInfo` model
2. Update `fromMap()` and `toMap()`
3. Update `copyWith()`
4. Add form field in admin screen
5. Add display section in customer screen
6. Update Firestore rules validation

### Change Empty Message

Find in `business_info_screen.dart`:
```dart
const String _notProvided = 'Not yet provided by RefillHub';
```

### Add Validation

Add to admin screen `_saveChanges()`:
```dart
if (_contactEmailController.text.isNotEmpty &&
    !_isValidEmail(_contactEmailController.text)) {
  setState(() => _errorMessage = 'Invalid email');
  return;
}
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Not yet provided" shows all fields | Document doesn't exist in Firestore |
| Changes don't appear in customer view | Refresh page or check stream provider |
| Admin can't save | Check Firestore rules allow admin + check auth status |
| Fields are grayed out | Check if fields are marked as empty in Firestore |

---

## 📊 Real-time Updates

**How it works:**
1. Customer views `/info/about-contact`
2. Widget uses `businessInfoStreamProvider` (StreamProvider)
3. Admin updates business info at `/admin/business-info`
4. Firestore updates `config/business_info`
5. Stream emits new data
6. Customer view rebuilds automatically ✓
7. No page refresh needed!

---

## 🎨 Styling Notes

- Uses existing `AppCard` widget for sections
- Responsive design (constrains to max 800px width)
- Follows Material Design with theme colors
- Empty fields use `onSurfaceVariant` color
- Errors use `errorContainer` background
- Success uses `tertiaryContainer` background

---

## 📱 Responsive Design

- Mobile: Full width with padding
- Tablet/Desktop: Centered, max 800px width
- Breaks gracefully on all screen sizes
- Text adjusts with device orientation

---

## 🔄 Data Flow

```
Admin Screen
    ↓
Text Controllers
    ↓
Save Button
    ↓
_saveChanges() method
    ↓
BusinessInfoRepository.updateBusinessInfo()
    ↓
Firestore: config/business_info
    ↓
Real-time Stream
    ↓
Customer Screen (StreamProvider)
    ↓
Display Updated Info
```

---

## 📚 Related Files

- `firestore.rules` - Security configuration
- `lib/core/router/app_router.dart` - Route definitions
- `lib/core/widgets/app_card.dart` - Card widget (used)
- `lib/main.dart` - App entry point

---

## ✨ Key Features

✅ Real-time updates (no refresh needed)  
✅ Admin-only editing (Firestore rules enforced)  
✅ Empty field handling ("Not yet provided")  
✅ Numbered ordering guide list  
✅ Responsive design  
✅ Error/success feedback  
✅ Loading states  
✅ No hardcoded values  

---

## 🚫 What NOT to Do

❌ Don't hardcode business info in code  
❌ Don't store sensitive data in model  
❌ Don't bypass Firestore rules  
❌ Don't put passwords/API keys in fields  
❌ Don't delete Firestore rules validation  

---

## 📞 Support

For issues or questions:
1. Check Firestore console for data
2. Check Flutter analyzer: `flutter analyze`
3. Check browser console for errors
4. Verify Firestore rules syntax
5. Test with `/design-preview` if available

---

**Last Updated:** 2026-11-26  
**Version:** 1.0.0  
**Status:** ✅ Production Ready
