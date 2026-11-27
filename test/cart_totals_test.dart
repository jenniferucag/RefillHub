import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/cart/data/cart_item.dart';

void main() {
  group('cartTotal calculation', () {
    test('calculates zero total for empty cart', () {
      expect(cartTotal([]), '0');
    });

    test('calculates single item total', () {
      final items = [
        CartItem(
          productId: 'p1',
          productName: 'Product A',
          sizeLabel: 'Medium',
          unitPrice: 100.50,
          quantity: 1,
        ),
      ];
      expect(cartTotal(items), '100.5');
    });

    test('calculates total for multiple items with same price', () {
      final items = [
        CartItem(
          productId: 'p1',
          productName: 'Product A',
          sizeLabel: 'Medium',
          unitPrice: 100,
          quantity: 2,
        ),
        CartItem(
          productId: 'p1',
          productName: 'Product A',
          sizeLabel: 'Large',
          unitPrice: 100,
          quantity: 3,
        ),
      ];
      expect(cartTotal(items), '500');
    });

    test('calculates total with different prices', () {
      final items = [
        CartItem(
          productId: 'p1',
          productName: 'Product A',
          sizeLabel: 'Medium',
          unitPrice: 100.50,
          quantity: 2,
        ),
        CartItem(
          productId: 'p2',
          productName: 'Product B',
          sizeLabel: 'Large',
          unitPrice: 250.75,
          quantity: 1,
        ),
      ];
      expect(cartTotal(items), '451.75');
    });

    test('handles decimal precision without floating-point errors', () {
      final items = [
        CartItem(
          productId: 'p1',
          productName: 'Product',
          sizeLabel: 'Size',
          unitPrice: 0.1,
          quantity: 3,
        ),
      ];
      // 0.1 * 3 should be exactly 0.3, not 0.30000000000000004
      expect(cartTotal(items), '0.3');
    });

    test('calculates total with many decimal places', () {
      final items = [
        CartItem(
          productId: 'p1',
          productName: 'Product',
          sizeLabel: 'Size',
          unitPrice: 123.456,
          quantity: 2,
        ),
      ];
      expect(cartTotal(items), '246.912');
    });

    test('calculates large totals correctly', () {
      final items = [
        CartItem(
          productId: 'p1',
          productName: 'Product',
          sizeLabel: 'Size',
          unitPrice: 9999.99,
          quantity: 10,
        ),
      ];
      expect(cartTotal(items), '99999.9');
    });

    test('removes trailing zeros from decimal part', () {
      final items = [
        CartItem(
          productId: 'p1',
          productName: 'Product',
          sizeLabel: 'Size',
          unitPrice: 100.50,
          quantity: 2,
        ),
      ];
      expect(cartTotal(items), '201');
    });

    test('calculates total with scientific notation prices', () {
      final items = [
        CartItem(
          productId: 'p1',
          productName: 'Product',
          sizeLabel: 'Size',
          unitPrice: 1e2, // 100
          quantity: 2,
        ),
      ];
      expect(cartTotal(items), '200');
    });

    test('calculates mixed decimal quantities', () {
      final items = [
        CartItem(
          productId: 'p1',
          productName: 'Product A',
          sizeLabel: 'Size A',
          unitPrice: 50.25,
          quantity: 2,
        ),
        CartItem(
          productId: 'p2',
          productName: 'Product B',
          sizeLabel: 'Size B',
          unitPrice: 75.75,
          quantity: 1,
        ),
        CartItem(
          productId: 'p3',
          productName: 'Product C',
          sizeLabel: 'Size C',
          unitPrice: 25,
          quantity: 4,
        ),
      ];
      // (50.25 * 2) + 75.75 + (25 * 4) = 100.5 + 75.75 + 100 = 276.25
      expect(cartTotal(items), '276.25');
    });
  });

  group('CartItem', () {
    test('creates cart item with valid data', () {
      final item = CartItem(
        productId: 'p1',
        productName: 'Product A',
        sizeLabel: 'Medium',
        unitPrice: 100,
        quantity: 2,
      );

      expect(item.productId, 'p1');
      expect(item.productName, 'Product A');
      expect(item.sizeLabel, 'Medium');
      expect(item.unitPrice, 100);
      expect(item.quantity, 2);
    });

    test('calculates lineTotal correctly', () {
      final item = CartItem(
        productId: 'p1',
        productName: 'Product',
        sizeLabel: 'Size',
        unitPrice: 50.25,
        quantity: 4,
      );

      // Manual calculation: 50.25 * 4 = 201
      final lineTotal = item.unitPrice * item.quantity;
      expect(lineTotal, 201);
    });

    test('withQuantity returns new instance with updated quantity', () {
      final original = CartItem(
        productId: 'p1',
        productName: 'Product',
        sizeLabel: 'Size',
        unitPrice: 100,
        quantity: 2,
      );

      final updated = original.withQuantity(5);

      expect(original.quantity, 2);
      expect(updated.quantity, 5);
      expect(updated.productId, original.productId);
      expect(updated.unitPrice, original.unitPrice);
    });

    test('converts to JSON and back', () {
      final original = CartItem(
        productId: 'p1',
        productName: 'Product A',
        sizeLabel: 'Large',
        unitPrice: 150.50,
        quantity: 3,
      );

      final json = original.toJson();
      final restored = CartItem.fromJson(json);

      expect(restored.productId, original.productId);
      expect(restored.productName, original.productName);
      expect(restored.sizeLabel, original.sizeLabel);
      expect(restored.unitPrice, original.unitPrice);
      expect(restored.quantity, original.quantity);
    });

    test('rejects invalid JSON', () {
      expect(() => CartItem.fromJson('not a map'), throwsFormatException);
      expect(() => CartItem.fromJson({}), throwsFormatException);
    });

    test('rejects empty product ID', () {
      expect(
        () => CartItem.fromJson({
          'productId': '',
          'productName': 'Product',
          'sizeLabel': 'Size',
          'unitPrice': 100,
          'quantity': 1,
        }),
        throwsFormatException,
      );
    });

    test('rejects empty product name', () {
      expect(
        () => CartItem.fromJson({
          'productId': 'p1',
          'productName': '  ',
          'sizeLabel': 'Size',
          'unitPrice': 100,
          'quantity': 1,
        }),
        throwsFormatException,
      );
    });

    test('rejects empty size label', () {
      expect(
        () => CartItem.fromJson({
          'productId': 'p1',
          'productName': 'Product',
          'sizeLabel': '',
          'unitPrice': 100,
          'quantity': 1,
        }),
        throwsFormatException,
      );
    });

    test('rejects negative or zero price', () {
      expect(
        () => CartItem.fromJson({
          'productId': 'p1',
          'productName': 'Product',
          'sizeLabel': 'Size',
          'unitPrice': 0,
          'quantity': 1,
        }),
        throwsFormatException,
      );
      expect(
        () => CartItem.fromJson({
          'productId': 'p1',
          'productName': 'Product',
          'sizeLabel': 'Size',
          'unitPrice': -50,
          'quantity': 1,
        }),
        throwsFormatException,
      );
    });

    test('rejects invalid quantity', () {
      expect(
        () => CartItem.fromJson({
          'productId': 'p1',
          'productName': 'Product',
          'sizeLabel': 'Size',
          'unitPrice': 100,
          'quantity': 0,
        }),
        throwsFormatException,
      );
      expect(
        () => CartItem.fromJson({
          'productId': 'p1',
          'productName': 'Product',
          'sizeLabel': 'Size',
          'unitPrice': 100,
          'quantity': 100, // exceeds maxQuantity of 99
        }),
        throwsFormatException,
      );
      expect(
        () => CartItem.fromJson({
          'productId': 'p1',
          'productName': 'Product',
          'sizeLabel': 'Size',
          'unitPrice': 100,
          'quantity': -1,
        }),
        throwsFormatException,
      );
    });

    test('rejects non-finite prices', () {
      expect(
        () => CartItem.fromJson({
          'productId': 'p1',
          'productName': 'Product',
          'sizeLabel': 'Size',
          'unitPrice': double.infinity,
          'quantity': 1,
        }),
        throwsFormatException,
      );
    });

    test('respects max quantity constraint', () {
      expect(
        () => CartItem.fromJson({
          'productId': 'p1',
          'productName': 'Product',
          'sizeLabel': 'Size',
          'unitPrice': 100,
          'quantity': CartItem.maxQuantity,
        }),
        returnsNormally,
      );
    });
  });
}
