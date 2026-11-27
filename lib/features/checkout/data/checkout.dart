import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/data/cart_item.dart';

/// A user-facing validation or checkout request error.
class CheckoutException implements Exception {
  /// Creates a checkout error with a display-safe [message].
  const CheckoutException(this.message);

  /// Message describing the checkout error.
  final String message;
}

/// Customer details and cart contents submitted for order placement.
class CheckoutRequest {
  /// Creates a checkout request.
  const CheckoutRequest({
    required this.items,
    required this.address,
    required this.phone,
    required this.notes,
    required this.deliveryFee,
    this.deliveryRequestedAt,
  });

  /// Cart snapshot; prices and availability are rechecked in Firestore.
  final List<CartItem> items;

  /// Delivery destination.
  final String address;

  /// Delivery contact number.
  final String phone;

  /// Optional delivery instructions.
  final String notes;

  /// Optional configured fee included in the displayed and saved total.
  final String? deliveryFee;

  /// Customer-requested delivery time for this purchase.
  final DateTime? deliveryRequestedAt;

  /// Fixed payment method used by checkout.
  final String paymentMethod = 'Cash on Delivery';
}

/// Callback used by the checkout flow to submit a validated request.
typedef PlaceOrder = Future<void> Function(CheckoutRequest request);

/// Parses a positive decimal delivery fee, returning `null` for invalid or zero values.
String? parseDeliveryFee(String? value) {
  final fee = value?.trim();
  if (fee == null || !RegExp(r'^\d+(\.\d+)?$').hasMatch(fee)) return null;
  if (RegExp(r'^0+(\.0+)?$').hasMatch(fee)) return null;
  return fee;
}

/// Configure with `--dart-define=DELIVERY_FEE=<amount>`. No fee by default.
const _configuredDeliveryFee = String.fromEnvironment('DELIVERY_FEE');

/// Build-configured delivery fee used to display the checkout estimate.
final deliveryFeeProvider = Provider<String?>(
  (ref) => parseDeliveryFee(_configuredDeliveryFee),
);

/// Adds decimal amount strings without introducing floating-point artifacts.
String addDecimals(String a, String b) {
  String fraction(String v) => v.contains('.') ? v.split('.').last : '';
  final scale = fraction(a).length > fraction(b).length
      ? fraction(a).length
      : fraction(b).length;
  BigInt scaled(String v) =>
      BigInt.parse(v.replaceAll('.', '') + '0' * (scale - fraction(v).length));
  final total = scaled(a) + scaled(b);
  if (scale == 0) return total.toString();
  final digits = total.toString().padLeft(scale + 1, '0');
  final whole = digits.substring(0, digits.length - scale);
  final frac = digits
      .substring(digits.length - scale)
      .replaceFirst(RegExp(r'0+$'), '');
  return frac.isEmpty ? whole : '$whole.$frac';
}
