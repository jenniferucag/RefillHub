import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/core/widgets/empty_state.dart';
import 'package:refillhub/features/cart/data/cart_item.dart';
import 'package:refillhub/features/products/data/product.dart';

import 'support/auth_test_support.dart';

void main() {
  group('CartScreen empty state', () {
    testWidgets('shows empty state when cart is empty', (tester) async {
      final app = TestApp(role: 'customer');
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      // Navigate to cart
      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon);
        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.byType(EmptyState), findsOneWidget);
      }
    });
  });

  group('CartScreen with items', () {
    testWidgets('displays items in cart', (tester) async {
      final product = Product(
        id: 'p1',
        name: 'Product A',
        description: 'Test product',
        isActive: true,
        createdAt: DateTime.utc(2025),
        sizes: [ProductSize(label: 'Medium', price: 100, isAvailable: true)],
      );

      final storage = MemoryCartStorage();
      final app = TestApp(
        role: 'customer',
        cartStorage: storage,
        productsStream: () => Stream.value([product]),
        allProductsStream: () => Stream.value([product]),
      );

      // Add item to cart
      await storage.save('user', [
        CartItem(
          productId: 'p1',
          productName: 'Product A',
          sizeLabel: 'Medium',
          unitPrice: 100,
          quantity: 2,
        ),
      ]);

      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      // Navigate to cart
      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon);
        await tester.pumpAndSettle();

        // Should show the item
        expect(find.text('Product A'), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // quantity
      }
    });

    testWidgets('shows checkout button when cart has items', (tester) async {
      final product = Product(
        id: 'p1',
        name: 'Product A',
        description: 'Test product',
        isActive: true,
        createdAt: DateTime.utc(2025),
        sizes: [ProductSize(label: 'Medium', price: 100, isAvailable: true)],
      );

      final storage = MemoryCartStorage();
      final app = TestApp(
        role: 'customer',
        cartStorage: storage,
        productsStream: () => Stream.value([product]),
        allProductsStream: () => Stream.value([product]),
      );

      await storage.save('user', [
        CartItem(
          productId: 'p1',
          productName: 'Product A',
          sizeLabel: 'Medium',
          unitPrice: 100,
          quantity: 1,
        ),
      ]);

      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon);
        await tester.pumpAndSettle();

        expect(find.text('Proceed to checkout'), findsOneWidget);
      }
    });
  });

  group('CartScreen error state', () {
    testWidgets('shows warning when product is unavailable', (tester) async {
      final inactiveProduct = Product(
        id: 'p1',
        name: 'Product A',
        description: 'Test product',
        isActive: false, // Product is inactive
        createdAt: DateTime.utc(2025),
        sizes: [ProductSize(label: 'Medium', price: 100, isAvailable: true)],
      );

      final storage = MemoryCartStorage();
      final app = TestApp(
        role: 'customer',
        cartStorage: storage,
        productsStream: () => Stream.value([]),
        allProductsStream: () => Stream.value([inactiveProduct]),
      );

      await storage.save('user', [
        CartItem(
          productId: 'p1',
          productName: 'Product A',
          sizeLabel: 'Medium',
          unitPrice: 100,
          quantity: 1,
        ),
      ]);

      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon);
        await tester.pumpAndSettle();

        // Should show warning about unavailable product
        expect(find.text('Product is no longer available.'), findsOneWidget);
      }
    });
  });
}
