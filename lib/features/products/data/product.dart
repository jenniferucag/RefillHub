import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_image_data.dart';

/// A sellable size option belonging to a [Product].
class ProductSize {
  /// Creates a size option with its current price and availability.
  const ProductSize({
    required this.label,
    required this.price,
    required this.isAvailable,
    this.refillPrice,
  });

  /// Customer-facing label used to select this size.
  final String label;

  /// Current unit price in the business's configured currency.
  final num price;

  /// Whether this size can currently be ordered.
  final bool isAvailable;

  /// Optional administrator-configured price for refilling this size.
  final num? refillPrice;

  /// Creates a size from its Firestore map.
  ///
  /// Throws [FormatException] when a required value has the wrong type.
  factory ProductSize.fromMap(Map<String, dynamic> data) {
    final label = data['label'];
    final price = data['price'];
    final isAvailable = data['isAvailable'];
    final refillPrice = data['refillPrice'];
    if (label is! String ||
        price is! num ||
        !price.isFinite ||
        isAvailable is! bool ||
        (refillPrice != null &&
            (refillPrice is! num ||
                !refillPrice.isFinite ||
                refillPrice <= 0))) {
      throw const FormatException('Invalid product size.');
    }
    return ProductSize(
      label: label,
      price: price,
      isAvailable: isAvailable,
      refillPrice: refillPrice as num?,
    );
  }
}

/// Product catalog entry backed by a Firestore document.
class Product {
  /// Creates an immutable product snapshot.
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required List<ProductSize> sizes,
    this.imageUrl,
    this.imageBase64,
    Uint8List? imageBytes,
    this.waterType = 'Unspecified',
  }) : sizes = List.unmodifiable(sizes),
       imageBytes = imageBytes ?? decodeProductImage(imageBase64);

  /// Firestore document ID.
  final String id;

  /// Product name shown in the catalog.
  final String name;

  /// Product description.
  final String description;

  /// Optional URL for the product image.
  final String? imageUrl;

  /// Optional base64-encoded product image stored directly in Firestore.
  final String? imageBase64;

  /// Decoded once when this product snapshot is created.
  final Uint8List? imageBytes;

  /// Water type from the catalog; legacy documents use `Unspecified`.
  final String waterType;

  /// Whether the product is visible to customers.
  final bool isActive;

  /// Creation time stored in Firestore.
  final DateTime createdAt;

  /// Available size and price options.
  final List<ProductSize> sizes;

  /// Parses a product document, including each size entry.
  ///
  /// Throws [FormatException] when the document or one of its sizes is invalid.
  factory Product.fromMap(String id, Map<String, dynamic> data) {
    final name = data['name'];
    final description = data['description'];
    final imageUrl = data['imageUrl'];
    final imageBase64 = data['imageBase64'];
    final isActive = data['isActive'];
    final createdAt = data['createdAt'];
    final sizes = data['sizes'];
    final rawWaterType = data['waterType'];
    if (name is! String ||
        description is! String ||
        (imageUrl != null && imageUrl is! String) ||
        (imageBase64 != null && imageBase64 is! String) ||
        (rawWaterType != null && rawWaterType is! String) ||
        isActive is! bool ||
        createdAt is! Timestamp ||
        sizes is! List) {
      throw FormatException('Invalid product document: $id.');
    }
    final parsedSizes = <ProductSize>[];
    for (final size in sizes) {
      if (size is! Map<String, dynamic>) {
        throw FormatException('Invalid size in product document: $id.');
      }
      try {
        parsedSizes.add(ProductSize.fromMap(size));
      } on FormatException catch (error) {
        throw FormatException(
          'Invalid size in product document $id: ${error.message}',
        );
      }
    }
    return Product(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl as String?,
      imageBase64: imageBase64 as String?,
      waterType: rawWaterType is String && rawWaterType.trim().isNotEmpty
          ? rawWaterType.trim()
          : 'Unspecified',
      isActive: isActive,
      createdAt: createdAt.toDate().toUtc(),
      sizes: parsedSizes,
    );
  }
}
