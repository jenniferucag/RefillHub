/// A product-size selection and quantity persisted in a customer's local cart.
class CartItem {
  /// Creates a cart line.
  const CartItem({
    required this.productId,
    required this.productName,
    required this.sizeLabel,
    required this.unitPrice,
    required this.quantity,
    this.waterType = 'Unspecified',
  });

  /// Maximum quantity that can be stored for one product size.
  static const maxQuantity = 99;

  /// Firestore product document ID.
  final String productId;

  /// Product name shown in the cart.
  final String productName;

  /// Selected size label.
  final String sizeLabel;

  /// Cached unit price; checkout revalidates it against the Firestore catalog.
  final num unitPrice;

  /// Number of units selected.
  final int quantity;

  /// Water type cached with this cart selection.
  final String waterType;

  /// Returns a copy of this cart line with [quantity].
  CartItem withQuantity(int quantity) => CartItem(
    productId: productId,
    productName: productName,
    sizeLabel: sizeLabel,
    unitPrice: unitPrice,
    quantity: quantity,
    waterType: waterType,
  );

  /// Serializes this cart line for local JSON storage.
  Map<String, Object> toJson() => {
    'productId': productId,
    'productName': productName,
    'sizeLabel': sizeLabel,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'waterType': waterType,
  };

  /// Parses and validates a cart line from local JSON data.
  ///
  /// Throws [FormatException] when the data is malformed or out of range.
  factory CartItem.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid cart item.');
    }

    final id = value['productId'];
    final name = value['productName'];
    final label = value['sizeLabel'];
    final price = value['unitPrice'];
    final quantity = value['quantity'];
    final waterType = value['waterType'] ?? 'Unspecified';
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        label is! String ||
        label.trim().isEmpty ||
        price is! num ||
        !price.isFinite ||
        price <= 0 ||
        quantity is! int ||
        quantity < 1 ||
        quantity > maxQuantity ||
        waterType is! String ||
        waterType.trim().isEmpty) {
      throw const FormatException('Invalid cart item.');
    }
    return CartItem(
      productId: id,
      productName: name,
      sizeLabel: label,
      unitPrice: price,
      quantity: quantity,
      waterType: waterType.trim(),
    );
  }
}

/// Calculates the cart subtotal using decimal-string arithmetic.
String cartTotal(Iterable<CartItem> items) {
  // Sum decimal representations as scaled integers to avoid floating-point artifacts.
  var total = BigInt.zero;
  var scale = 0;
  for (final item in items) {
    final parts = item.unitPrice.toString().toLowerCase().split('e');
    final decimal = parts.first.split('.');
    final exponent = parts.length == 2 ? int.parse(parts.last) : 0;
    var itemScale = (decimal.length == 2 ? decimal.last.length : 0) - exponent;
    var amount = BigInt.parse(decimal.join()) * BigInt.from(item.quantity);
    if (itemScale < 0) {
      amount *= BigInt.from(10).pow(-itemScale);
      itemScale = 0;
    }
    if (itemScale > scale) {
      total *= BigInt.from(10).pow(itemScale - scale);
      scale = itemScale;
    } else {
      amount *= BigInt.from(10).pow(scale - itemScale);
    }
    total += amount;
  }
  if (scale == 0) return total.toString();
  final digits = total.toString().padLeft(scale + 1, '0');
  final whole = digits.substring(0, digits.length - scale);
  final fraction = digits
      .substring(digits.length - scale)
      .replaceFirst(RegExp(r'0+$'), '');
  return fraction.isEmpty ? whole : '$whole.$fraction';
}
