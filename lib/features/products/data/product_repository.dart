import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'product.dart';
import 'product_image_data.dart';

/// Reads and writes product documents in Firestore.
class ProductRepository {
  /// Creates a repository backed by [firestore].
  ProductRepository(FirebaseFirestore firestore)
    : _products = firestore.collection('products');

  final CollectionReference<Map<String, dynamic>> _products;

  /// Streams products available for customer browsing.
  Stream<List<Product>> watchActiveProducts() =>
      _products.where('isActive', isEqualTo: true).snapshots().map(_toProducts);

  /// Streams every product, including inactive products for administrators.
  Stream<List<Product>> watchAllProducts() =>
      _products.snapshots().map(_toProducts);

  /// Fetches active products directly from the Firestore server.
  Future<List<Product>> getActiveProductsFromServer() async => _toProducts(
    await _products
        .where('isActive', isEqualTo: true)
        .get(const GetOptions(source: Source.server)),
  );

  /// Creates an inactive product with a server-generated document ID.
  Future<void> createProduct({
    required String name,
    required String waterType,
    required String description,
    required String? imageBase64,
    required List<ProductSize> sizes,
  }) async {
    final data = {
      ..._productData(name, waterType, description, imageBase64, sizes),
      'isActive': false,
      'createdAt': Timestamp.now(),
    };
    _ensureDocumentFits(data);
    await _products.doc().set(data);
  }

  /// Updates a product without altering legacy image URLs unless the photo is
  /// explicitly removed.
  Future<void> updateProduct(
    String id, {
    required String name,
    required String waterType,
    required String description,
    required String? imageBase64,
    required bool removeImage,
    required List<ProductSize> sizes,
  }) async {
    final reference = _products.doc(id);
    final snapshot = await reference.get();
    final currentData = snapshot.data();
    if (currentData == null) {
      throw StateError('The product no longer exists.');
    }

    final changes = _productData(
      name,
      waterType,
      description,
      imageBase64,
      sizes,
    );
    if (removeImage) {
      changes['imageBase64'] = FieldValue.delete();
      changes['imageUrl'] = FieldValue.delete();
    }

    final nextData = <String, dynamic>{...currentData, ...changes};
    if (removeImage) {
      nextData
        ..remove('imageBase64')
        ..remove('imageUrl');
    }
    _ensureDocumentFits(nextData);
    await reference.update(changes);
  }

  /// Sets whether [id] is visible to customers.
  Future<void> setActive(String id, bool isActive) =>
      _products.doc(id).update({'isActive': isActive});

  Map<String, dynamic> _productData(
    String name,
    String waterType,
    String description,
    String? imageBase64,
    List<ProductSize> sizes,
  ) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Product name is required.');
    }
    if (waterType.trim().isEmpty) {
      throw ArgumentError('Water type is required.');
    }
    if (sizes.any(
      (size) =>
          size.label.trim().isEmpty ||
          !size.price.isFinite ||
          size.price <= 0 ||
          (size.refillPrice != null &&
              (!size.refillPrice!.isFinite || size.refillPrice! <= 0)),
    )) {
      throw ArgumentError(
        'Each size needs a label and a price greater than 0.',
      );
    }
    final normalizedImage = imageBase64?.trim();
    if (normalizedImage != null && normalizedImage.isNotEmpty) {
      final decodedImage = decodeProductImage(normalizedImage);
      if (decodedImage == null) {
        throw ArgumentError('The selected product photo is invalid.');
      }
      if (decodedImage.lengthInBytes > maxProductImageBytes) {
        throw ArgumentError('Product photos must be smaller than 300 KB.');
      }
    }
    return {
      'name': name.trim(),
      'waterType': waterType.trim(),
      'description': description.trim(),
      if (normalizedImage != null && normalizedImage.isNotEmpty)
        'imageBase64': normalizedImage,
      'sizes': [
        for (final size in sizes)
          {
            'label': size.label.trim(),
            'price': size.price,
            if (size.refillPrice != null) 'refillPrice': size.refillPrice,
            'isAvailable': size.isAvailable,
          },
      ],
    };
  }

  void _ensureDocumentFits(Map<String, dynamic> data) {
    final encodedLength = utf8.encode(jsonEncode(_jsonSafe(data))).length;
    if (encodedLength + 1024 >= 1000000) {
      throw ArgumentError(
        'Product data must be under 1 MB. Choose a smaller photo or shorten the description.',
      );
    }
  }

  Object? _jsonSafe(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _jsonSafe(entry.value),
      };
    }
    if (value is Iterable) return value.map(_jsonSafe).toList();
    return value;
  }

  List<Product> _toProducts(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((document) => Product.fromMap(document.id, document.data()))
          .toList()
        ..sort(
          (first, second) =>
              first.name.toLowerCase().compareTo(second.name.toLowerCase()),
        );
}
