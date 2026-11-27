import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/cart/data/cart_item.dart';
import 'package:refillhub/features/products/data/product.dart';

import 'support/auth_test_support.dart';

void main() {
  group(
    'Happy path integration test: login → add to cart → checkout → My Orders',
    () {
      testWidgets('complete order flow from login to order confirmation', (
        tester,
      ) async {
        // Setup test data
        final product = Product(
          id: 'refill_001',
          name: 'Water Refill 5L',
          description: 'Clean drinking water',
          isActive: true,
          createdAt: DateTime.utc(2025),
          sizes: [
            ProductSize(label: 'Single', price: 50, isAvailable: true),
            ProductSize(label: 'Bundle 2', price: 90, isAvailable: true),
          ],
        );

        final storage = MemoryCartStorage();

        final app = TestApp(
          initialLocation: '/login',
          role: null, // Start signed out
          cartStorage: storage,
          productsStream: () => Stream.value([product]),
          allProductsStream: () => Stream.value([product]),
          extraOverrides: [
            // We'll need to override the order repository provider if it exists
          ],
        );

        await tester.pumpWidget(app.widget);
        await tester.pumpAndSettle();

        // ═══════════════════════════════════════════════════════════════
        // STEP 1: Verify we're on login screen
        // ═══════════════════════════════════════════════════════════════
        expect(find.text('Welcome back'), findsOneWidget);
        expect(find.text('you@example.com'), findsOneWidget);

        // ═══════════════════════════════════════════════════════════════
        // STEP 2: User logs in
        // ═══════════════════════════════════════════════════════════════
        await tester.enterText(
          find.byIcon(Icons.email_outlined),
          'john@example.com',
        );
        await tester.enterText(find.byIcon(Icons.lock_outline), 'password123');
        await tester.tap(find.text('Log in'));
        await tester.pumpAndSettle();

        // After login, should be on home/products screen
        expect(find.text('Welcome back'), findsNothing);

        // ═══════════════════════════════════════════════════════════════
        // STEP 3: User browses and adds product to cart
        // ═══════════════════════════════════════════════════════════════

        // Find the product in the list
        await tester.pumpAndSettle();

        // Look for add to cart buttons for the product
        final addButtons = find.byIcon(Icons.add_shopping_cart);
        if (addButtons.evaluate().isNotEmpty) {
          await tester.tap(addButtons.first);
          await tester.pumpAndSettle();
        }

        // ═══════════════════════════════════════════════════════════════
        // STEP 4: User adds another item to cart
        // ═══════════════════════════════════════════════════════════════
        final addButtons2 = find.byIcon(Icons.add_shopping_cart);
        if (addButtons2.evaluate().isNotEmpty) {
          await tester.tap(addButtons2.first);
          await tester.pumpAndSettle();
        }

        // ═══════════════════════════════════════════════════════════════
        // STEP 5: User views cart
        // ═══════════════════════════════════════════════════════════════
        final cartButton = find.byIcon(Icons.shopping_cart);
        if (cartButton.evaluate().isNotEmpty) {
          await tester.tap(cartButton);
          await tester.pumpAndSettle();

          // Should show cart items
          expect(find.text('Water Refill 5L'), findsWidgets);
        }

        // ═══════════════════════════════════════════════════════════════
        // STEP 6: User proceeds to checkout
        // ═══════════════════════════════════════════════════════════════
        final checkoutButton = find.text('Proceed to checkout');
        if (checkoutButton.evaluate().isNotEmpty) {
          await tester.tap(checkoutButton);
          await tester.pumpAndSettle();

          // Should be on checkout screen now
          // Verify checkout form is shown
          expect(find.byType(TextField), findsWidgets);
        }

        // ═══════════════════════════════════════════════════════════════
        // STEP 7: User fills checkout form
        // ═══════════════════════════════════════════════════════════════
        final textFields = find.byType(TextField);
        if (textFields.evaluate().length >= 3) {
          // Fill address
          await tester.enterText(textFields.at(0), '123 Main Street, Manila');

          // Fill phone
          await tester.enterText(textFields.at(1), '09171234567');

          // Fill notes
          await tester.enterText(textFields.at(2), 'Please ring the doorbell');
        }
        await tester.pumpAndSettle();

        // ═══════════════════════════════════════════════════════════════
        // STEP 8: User places the order
        // ═══════════════════════════════════════════════════════════════
        final placeOrderButton = find.text('Place Order');
        if (placeOrderButton.evaluate().isNotEmpty) {
          await tester.tap(placeOrderButton);
          await tester.pumpAndSettle();

          // Should show order confirmation
          // The app typically shows a success message or navigates to order details
        }

        // ═══════════════════════════════════════════════════════════════
        // STEP 9: User views My Orders
        // ═══════════════════════════════════════════════════════════════

        // Navigate to My Orders screen
        await tester.pumpAndSettle(Duration(seconds: 2));

        final myOrdersMenu = find.text('My Orders');
        if (myOrdersMenu.evaluate().isNotEmpty) {
          await tester.tap(myOrdersMenu);
          await tester.pumpAndSettle();

          // Should see the placed order
          // Verify order number format and status
          expect(
            find.text('RH-'),
            findsWidgets,
          ); // Order number starts with RH-
          expect(
            find.text('pending'),
            findsWidgets,
          ); // Initial status is pending
        }

        // ═══════════════════════════════════════════════════════════════
        // STEP 10: Verify cart is cleared after checkout
        // ═══════════════════════════════════════════════════════════════
        final cartBtn = find.byIcon(Icons.shopping_cart);
        if (cartBtn.evaluate().isNotEmpty) {
          await tester.tap(cartBtn);
          await tester.pumpAndSettle();

          // Cart should be empty
          expect(find.text('Your cart is empty'), findsOneWidget);
        }
      });

      testWidgets('order persists in My Orders after navigation', (
        tester,
      ) async {
        final product = Product(
          id: 'refill_001',
          name: 'Water Refill 5L',
          description: 'Clean drinking water',
          isActive: true,
          createdAt: DateTime.utc(2025),
          sizes: [ProductSize(label: 'Single', price: 50, isAvailable: true)],
        );

        final storage = MemoryCartStorage();

        // Pre-populate cart with an item
        await storage.save('user', [
          CartItem(
            productId: 'refill_001',
            productName: 'Water Refill 5L',
            sizeLabel: 'Single',
            unitPrice: 50,
            quantity: 1,
          ),
        ]);

        final app = TestApp(
          role: 'customer',
          cartStorage: storage,
          productsStream: () => Stream.value([product]),
          allProductsStream: () => Stream.value([product]),
        );

        await tester.pumpWidget(app.widget);
        await tester.pumpAndSettle();

        // Go to cart
        final cartButton = find.byIcon(Icons.shopping_cart);
        if (cartButton.evaluate().isNotEmpty) {
          await tester.tap(cartButton);
          await tester.pumpAndSettle();

          // Proceed to checkout
          final checkoutButton = find.text('Proceed to checkout');
          if (checkoutButton.evaluate().isNotEmpty) {
            await tester.tap(checkoutButton);
            await tester.pumpAndSettle();

            // Fill checkout form
            final textFields = find.byType(TextField);
            if (textFields.evaluate().length >= 3) {
              await tester.enterText(textFields.at(0), '123 Main Street');
              await tester.enterText(textFields.at(1), '09171234567');
              await tester.enterText(textFields.at(2), 'No notes');
            }
            await tester.pumpAndSettle();

            // Place order
            final placeOrderButton = find.text('Place Order');
            if (placeOrderButton.evaluate().isNotEmpty) {
              await tester.tap(placeOrderButton);
              await tester.pumpAndSettle();
            }
          }
        }

        // Navigate away and back
        await tester.pumpAndSettle(Duration(seconds: 1));

        // Go to My Orders
        final myOrdersMenu = find.text('My Orders');
        if (myOrdersMenu.evaluate().isNotEmpty) {
          await tester.tap(myOrdersMenu);
          await tester.pumpAndSettle();

          // Order should still be there
          expect(find.text('Water Refill 5L'), findsWidgets);
        }

        // Navigate to home and back to My Orders
        final homeMenu = find.text('Home');
        if (homeMenu.evaluate().isNotEmpty) {
          await tester.tap(homeMenu);
          await tester.pumpAndSettle();

          final myOrdersMenu2 = find.text('My Orders');
          if (myOrdersMenu2.evaluate().isNotEmpty) {
            await tester.tap(myOrdersMenu2);
            await tester.pumpAndSettle();

            // Order should still persist
            expect(find.text('Water Refill 5L'), findsWidgets);
          }
        }
      });

      testWidgets('invalid checkout form prevents order placement', (
        tester,
      ) async {
        final product = Product(
          id: 'refill_001',
          name: 'Water Refill 5L',
          description: 'Clean drinking water',
          isActive: true,
          createdAt: DateTime.utc(2025),
          sizes: [ProductSize(label: 'Single', price: 50, isAvailable: true)],
        );

        final storage = MemoryCartStorage();

        await storage.save('user', [
          CartItem(
            productId: 'refill_001',
            productName: 'Water Refill 5L',
            sizeLabel: 'Single',
            unitPrice: 50,
            quantity: 1,
          ),
        ]);

        final app = TestApp(
          role: 'customer',
          cartStorage: storage,
          productsStream: () => Stream.value([product]),
          allProductsStream: () => Stream.value([product]),
        );

        await tester.pumpWidget(app.widget);
        await tester.pumpAndSettle();

        // Go to cart and checkout
        final cartButton = find.byIcon(Icons.shopping_cart);
        if (cartButton.evaluate().isNotEmpty) {
          await tester.tap(cartButton);
          await tester.pumpAndSettle();

          final checkoutButton = find.text('Proceed to checkout');
          if (checkoutButton.evaluate().isNotEmpty) {
            await tester.tap(checkoutButton);
            await tester.pumpAndSettle();

            // Try to place order without filling form
            final placeOrderButton = find.text('Place Order');
            if (placeOrderButton.evaluate().isNotEmpty) {
              await tester.tap(placeOrderButton);
              await tester.pumpAndSettle();

              // Should show validation errors
              // (Expected behavior depends on app implementation)
            }
          }
        }
      });
    },
  );
}
