import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/products/data/product.dart';

void main() {
  final createdAt = DateTime.utc(2025, 1, 1);
  Map<String, dynamic> productData() => {
    'name': 'TEST product',
    'description': 'TEST description',
    'isActive': true,
    'createdAt': Timestamp.fromDate(createdAt),
    'sizes': [
      {'label': 'TEST size A', 'price': 120, 'isAvailable': true},
      {'label': 'TEST size B', 'price': 32.5, 'isAvailable': false},
    ],
  };

  test('reads document id, optional image and actual sizes from Firestore', () {
    final product = Product.fromMap('test-id', productData());
    expect(product.id, 'test-id');
    expect(product.name, 'TEST product');
    expect(product.waterType, 'Unspecified');
    expect(product.imageUrl, isNull);
    expect(product.imageBase64, isNull);
    expect(product.imageBytes, isNull);
    expect(product.isActive, isTrue);
    expect(product.createdAt, createdAt);
    expect(product.sizes.map((size) => size.label), [
      'TEST size A',
      'TEST size B',
    ]);
    expect(product.sizes.map((size) => size.price), [120, 32.5]);
    expect(product.sizes.map((size) => size.isAvailable), [true, false]);
    expect(() => product.sizes.clear(), throwsUnsupportedError);

    final withImage = productData()
      ..['imageUrl'] = 'https://example.test/image';
    expect(
      Product.fromMap('test-id', withImage).imageUrl,
      'https://example.test/image',
    );
  });

  test('decodes an optional base64 image once on the product snapshot', () {
    final data = productData()..['imageBase64'] = base64Encode([1, 2, 3]);
    final product = Product.fromMap('test-id', data);
    expect(product.imageBase64, base64Encode([1, 2, 3]));
    expect(product.imageBytes, [1, 2, 3]);
    expect(identical(product.imageBytes, product.imageBytes), isTrue);
  });

  test('reads optional administrator refill prices from product sizes', () {
    final data = productData()
      ..['sizes'] = [
        {
          'label': 'TEST size A',
          'price': 120,
          'refillPrice': 45.5,
          'isAvailable': true,
        },
        {'label': 'TEST size B', 'price': 32.5, 'isAvailable': false},
      ];

    final product = Product.fromMap('test-id', data);
    expect(product.sizes.first.refillPrice, 45.5);
    expect(product.sizes.last.refillPrice, isNull);
  });

  test('reads water types and treats legacy products as unspecified', () {
    final typed = productData()..['waterType'] = ' Purified ';
    expect(Product.fromMap('test-id', typed).waterType, 'Purified');
    expect(
      Product.fromMap('legacy-id', productData()).waterType,
      'Unspecified',
    );
    expect(
      () => Product.fromMap('bad-id', productData()..['waterType'] = 1),
      throwsFormatException,
    );
  });

  test(
    'surfaces invalid product and size data instead of inventing defaults',
    () {
      for (final data in [
        productData()..remove('createdAt'),
        productData()..['imageUrl'] = 1,
        productData()..['isActive'] = null,
        productData()..['sizes'] = 'not a list',
        productData()
          ..['sizes'] = [
            {'label': 'TEST size', 'price': '10', 'isAvailable': true},
          ],
        productData()
          ..['sizes'] = [
            {'label': 'TEST size', 'price': double.nan, 'isAvailable': true},
          ],
        productData()
          ..['sizes'] = [
            {
              'label': 'TEST size',
              'price': 10,
              'refillPrice': -1,
              'isAvailable': true,
            },
          ],
        productData()..['sizes'] = [null],
      ]) {
        expect(() => Product.fromMap('bad-id', data), throwsFormatException);
      }
    },
  );
}
