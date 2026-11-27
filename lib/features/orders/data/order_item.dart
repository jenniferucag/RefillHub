/// Product and size snapshot included in a customer order.
class OrderItem {
  /// Creates an order line with its placement-time unit price.
  const OrderItem({
    required this.productName,
    required this.sizeLabel,
    required this.unitPrice,
    required this.quantity,
    this.waterType = 'Unspecified',
  });

  /// Product name copied from the catalog.
  final String productName;

  /// Selected product size label.
  final String sizeLabel;

  /// Unit price at the time the order was placed.
  final num? unitPrice;

  /// Number of units ordered.
  final int quantity;

  /// Water type copied from the catalog when the order was placed.
  final String waterType;

  /// Calculated line total (`unitPrice * quantity`).
  num? get lineTotal => unitPrice == null ? null : unitPrice! * quantity;

  /// Serializes this line item to a Firestore-compatible map.
  Map<String, Object?> toJson() => {
    'productName': productName,
    'sizeLabel': sizeLabel,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'waterType': waterType,
    'lineTotal': lineTotal,
  };

  /// Parses an order line and validates its required values.
  ///
  /// Throws [FormatException] when the value is malformed.
  factory OrderItem.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid order item.');
    }

    final productName = value['productName'];
    final sizeLabel = value['sizeLabel'];
    final unitPrice = value['unitPrice'];
    final quantity = value['quantity'];
    final waterType = value['waterType'] ?? 'Unspecified';
    final lineTotal = value['lineTotal'];

    if (productName is! String ||
        productName.trim().isEmpty ||
        sizeLabel is! String ||
        sizeLabel.trim().isEmpty ||
        (unitPrice != null &&
            (unitPrice is! num || !unitPrice.isFinite || unitPrice <= 0)) ||
        quantity is! int ||
        quantity < 1 ||
        quantity > 99 ||
        waterType is! String ||
        waterType.trim().isEmpty ||
        (lineTotal != null &&
            (lineTotal is! num ||
                !lineTotal.isFinite ||
                lineTotal <= 0 ||
                unitPrice == null ||
                lineTotal != unitPrice * quantity))) {
      throw const FormatException('Invalid order item.');
    }

    return OrderItem(
      productName: productName,
      sizeLabel: sizeLabel,
      unitPrice: unitPrice,
      quantity: quantity,
      waterType: waterType.trim(),
    );
  }
}
