import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/core/router/app_router.dart';
import 'package:refillhub/features/auth/auth_controller.dart';
import 'package:refillhub/features/cart/data/cart_item.dart';
import 'package:refillhub/features/products/data/product.dart';

import 'support/auth_test_support.dart';

Product _product({
  String id = 'test',
  num price = 10,
  bool available = true,
  List<ProductSize>? sizes,
}) => Product(
  id: id,
  name: 'TEST product',
  description: 'TEST description',
  isActive: true,
  createdAt: DateTime.utc(2025),
  sizes:
      sizes ??
      [ProductSize(label: 'TEST size', price: price, isAvailable: available)],
);

const _item = CartItem(
  productId: 'test',
  productName: 'TEST product',
  sizeLabel: 'TEST size',
  unitPrice: 10,
  quantity: 1,
);

void main() {
  testWidgets('add, badge, quantity, subtotal, removal and empty state', (
    tester,
  ) async {
    final storage = MemoryCartStorage();
    final product = _product();
    final app = TestApp(
      role: 'customer',
      initialLocation: '/products/test',
      productsStream: () => Stream.value([product]),
      productCheck: () async => [product],
      cartStorage: storage,
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('TEST size'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(storage.carts['user']!.single.quantity, 1);
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byTooltip('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Subtotal: 10'), findsOneWidget);
    final decrease = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Decrease quantity',
    );
    expect(tester.widget<IconButton>(decrease).onPressed, isNull);
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();
    expect(find.text('Subtotal: 20'), findsOneWidget);
    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pumpAndSettle();
    expect(find.text('Subtotal: 10'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove item'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(storage.carts['user'], isEmpty);
  });

  testWidgets('rechecks when opened and warns about price and availability', (
    tester,
  ) async {
    final storage = MemoryCartStorage()..carts['user'] = [_item];
    var checks = 0;
    var products = [_product(price: 15)];
    final app = TestApp(
      role: 'customer',
      initialLocation: '/products/test',
      productsStream: () => Stream.value([_product()]),
      productCheck: () async {
        checks++;
        return products;
      },
      cartStorage: storage,
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cart'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Price changed from 10 to 15'), findsOneWidget);
    expect(find.text('Subtotal: 10'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    products = [_product(price: 12, available: false)];
    await tester.tap(find.byTooltip('Cart'));
    await tester.pumpAndSettle();
    expect(checks, 2);
    expect(find.textContaining('Size is no longer available.'), findsOneWidget);
    expect(find.textContaining('Price changed from 10 to 12'), findsOneWidget);
    products = [_product(sizes: [])];
    await tester.tap(find.text('Refresh product details'));
    await tester.pumpAndSettle();
    expect(find.text('Size is no longer available.'), findsOneWidget);
    products = [];
    await tester.tap(find.text('Refresh product details'));
    await tester.pumpAndSettle();
    expect(find.text('Product is no longer available.'), findsOneWidget);
  });

  testWidgets('server check failure warns and can be retried', (tester) async {
    final storage = MemoryCartStorage()..carts['user'] = [_item];
    var fail = true;
    final app = TestApp(
      role: 'customer',
      initialLocation: '/cart',
      cartStorage: storage,
      productCheck: () async {
        if (fail) throw StateError('TEST offline');
        return [_product()];
      },
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not verify current product details'),
      findsOneWidget,
    );
    expect(find.text('TEST product'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry product check'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not verify current product details'),
      findsNothing,
    );
    expect(find.text('Refresh product details'), findsOneWidget);
  });

  testWidgets('clear requires confirmation', (tester) async {
    final storage = MemoryCartStorage()..carts['user'] = [_item];
    final app = TestApp(
      role: 'customer',
      initialLocation: '/cart',
      cartStorage: storage,
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(storage.carts['user'], hasLength(1));
    await tester.tap(find.text('Clear cart'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Clear cart'),
      ),
    );
    await tester.pumpAndSettle();
    expect(storage.carts['user'], isEmpty);
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('cart load and save failures are visible and recoverable', (
    tester,
  ) async {
    final storage = MemoryCartStorage()
      ..carts['user'] = [_item]
      ..loadError = StateError('TEST load failure');
    final app = TestApp(
      role: 'customer',
      initialLocation: '/cart',
      cartStorage: storage,
      productCheck: () async => [_product()],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not load your saved cart'),
      findsOneWidget,
    );
    storage.loadError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Subtotal: 10'), findsOneWidget);
    storage.saveError = StateError('TEST save failure');
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save your cart. Please try again.'),
      findsOneWidget,
    );
    expect(storage.carts['user']!.single.quantity, 1);
    expect(find.text('Subtotal: 10'), findsOneWidget);
  });

  test('cart route remains customer-only', () {
    final path = Uri.parse('/cart');
    expect(authRedirect(AuthStatus.customer, path), isNull);
    expect(authRedirect(AuthStatus.signedOut, path), '/login');
    expect(authRedirect(AuthStatus.admin, path), '/admin/dashboard');
  });
}
