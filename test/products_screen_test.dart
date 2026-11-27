import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/core/router/app_router.dart';
import 'package:refillhub/features/auth/auth_controller.dart';
import 'package:refillhub/features/orders/data/order_providers.dart';
import 'package:refillhub/features/products/data/product.dart';

import 'support/auth_test_support.dart';

Product product({
  String id = 'test id & one',
  String name = 'TEST Aqua',
  String waterType = 'Purified',
  List<ProductSize> sizes = const [
    ProductSize(label: 'TEST small', price: 25, isAvailable: true),
    ProductSize(label: 'TEST large', price: 42.5, isAvailable: false),
  ],
}) => Product(
  id: id,
  name: name,
  waterType: waterType,
  description: 'TEST drinking water',
  isActive: true,
  createdAt: DateTime.utc(2025),
  sizes: sizes,
);

Future<void> pumpLoading(WidgetTester tester, TestApp app) async {
  await tester.pumpWidget(app.widget);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('loads, searches, and shows the empty catalogue', (tester) async {
    final events = StreamController<List<Product>>.broadcast();
    addTearDown(events.close);
    final app = TestApp(
      role: 'customer',
      initialLocation: '/products',
      productsStream: () => events.stream,
      extraOverrides: [
        customerOrdersProvider.overrideWith(
          (ref, customerId) => Stream.value([]),
        ),
      ],
    );
    await pumpLoading(tester, app);
    expect(find.text('Loading products...'), findsOneWidget);
    expect(events.hasListener, isTrue);
    events.add([]);
    await tester.pumpAndSettle();
    expect(find.text('No products available yet'), findsOneWidget);

    events.add([product(), product(id: 'test-2', name: 'TEST Other')]);
    await tester.pumpAndSettle();
    expect(find.text('TEST Aqua'), findsOneWidget);
    expect(find.text('TEST Other'), findsOneWidget);

    final search = find.byKey(const ValueKey('products-search'));
    await tester.enterText(search, 'aQuA');
    await tester.pumpAndSettle();
    expect(find.text('TEST Aqua'), findsOneWidget);
    expect(find.text('TEST Other'), findsNothing);
    await tester.enterText(search, 'DRINKING');
    await tester.pumpAndSettle();
    expect(find.text('TEST Aqua'), findsOneWidget);
    expect(find.text('TEST Other'), findsOneWidget);
    await tester.enterText(search, 'not found');
    await tester.pumpAndSettle();
    expect(find.text('No products match your search.'), findsOneWidget);

    await tester.tap(find.text('My Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'not found',
    );
  });

  testWidgets('details disable unavailable sizes and react to live changes', (
    tester,
  ) async {
    final events = StreamController<List<Product>>.broadcast();
    addTearDown(events.close);
    final app = TestApp(
      role: 'customer',
      initialLocation: '/products',
      productsStream: () => events.stream,
    );
    await pumpLoading(tester, app);
    events.add([product()]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('TEST Aqua'));
    await tester.pumpAndSettle();

    expect(find.text('TEST drinking water'), findsOneWidget);
    expect(find.text('Water type: Purified'), findsOneWidget);
    expect(find.text('Price: 25'), findsOneWidget);
    expect(find.text('Price: 42.5'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    final unavailable = find.ancestor(
      of: find.text('TEST large'),
      matching: find.byType(ListTile),
    );
    expect(tester.widget<ListTile>(unavailable).enabled, isFalse);
    expect(tester.widget<ListTile>(unavailable).onTap, isNull);
    final addButton = find.widgetWithText(ElevatedButton, 'Add to cart');
    expect(tester.widget<ElevatedButton>(addButton).onPressed, isNull);
    await tester.tap(find.text('TEST small'));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(addButton).onPressed, isNotNull);
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pump();
    expect(find.text('Added to cart.'), findsOneWidget);

    events.add([
      product(
        sizes: const [
          ProductSize(label: 'TEST small', price: 30, isAvailable: true),
        ],
      ),
    ]);
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(addButton).onPressed, isNull);
    await tester.tap(find.text('TEST small'));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(addButton).onPressed, isNotNull);
    events.add([
      product(
        sizes: const [
          ProductSize(label: 'TEST small', price: 30, isAvailable: false),
        ],
      ),
    ]);
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(addButton).onPressed, isNull);
    events.add([]);
    await tester.pumpAndSettle();
    expect(find.text('This product is no longer available.'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('No products available yet'), findsOneWidget);
  });

  testWidgets('water type chips filter products together with search', (
    tester,
  ) async {
    final app = TestApp(
      role: 'customer',
      initialLocation: '/products',
      productsStream: () => Stream.value([
        product(id: 'purified', name: 'TEST Spring', waterType: 'Purified'),
        product(id: 'mineral', name: 'TEST Mountain', waterType: 'Mineral'),
      ]),
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Purified'), findsOneWidget);
    expect(find.text('Mineral'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Mineral'));
    await tester.pumpAndSettle();
    expect(find.text('TEST Mountain'), findsOneWidget);
    expect(find.text('TEST Spring'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('products-search')),
      'mountain',
    );
    await tester.pumpAndSettle();
    expect(find.text('TEST Mountain'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('products-search')),
      'spring',
    );
    await tester.pumpAndSettle();
    expect(find.text('No products match your search.'), findsOneWidget);
  });

  testWidgets('a different product does not inherit the selected size', (
    tester,
  ) async {
    final app = TestApp(
      role: 'customer',
      initialLocation: '/products/test-1',
      productsStream: () => Stream.value([
        product(id: 'test-1'),
        product(id: 'test-2', name: 'TEST Other'),
      ]),
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('TEST small'));
    await tester.pumpAndSettle();
    final addButton = find.widgetWithText(ElevatedButton, 'Add to cart');
    expect(tester.widget<ElevatedButton>(addButton).onPressed, isNotNull);
    app.router.go('/products/test-2');
    await tester.pumpAndSettle();
    expect(find.text('TEST Other'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(addButton).onPressed, isNull);
  });

  testWidgets('pricing lists every size and handles products without sizes', (
    tester,
  ) async {
    final app = TestApp(
      role: 'customer',
      initialLocation: '/info/pricing',
      productsStream: () => Stream.value([
        product(),
        product(id: 'test-2', name: 'TEST Other', sizes: []),
      ]),
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.rows.length, 3);
    expect(find.text('TEST Aqua'), findsNWidgets(2));
    expect(find.text('TEST Other'), findsOneWidget);
    expect(find.text('TEST small'), findsOneWidget);
    expect(find.text('TEST large'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('42.5'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('No sizes available'), findsOneWidget);
    expect(find.text('Add to cart'), findsNothing);
  });

  testWidgets('pricing shows the empty state', (tester) async {
    final app = TestApp(role: 'customer', initialLocation: '/info/pricing');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    expect(find.text('No prices available yet'), findsOneWidget);
    expect(find.byType(DataTable), findsNothing);
  });

  testWidgets('pricing remains scrollable on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = TestApp(
      role: 'customer',
      initialLocation: '/info/pricing',
      productsStream: () => Stream.value([product()]),
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    final before = tester.getTopLeft(find.text('Unavailable')).dx;
    await tester.dragFrom(const Offset(300, 150), const Offset(-280, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Unavailable')).dx, lessThan(before));
  });

  for (final route in ['/products', '/info/pricing']) {
    testWidgets('$route shows errors and retries', (tester) async {
      var attempts = 0;
      final app = TestApp(
        role: 'customer',
        initialLocation: route,
        productsStream: () {
          attempts++;
          return attempts == 1
              ? Stream.error(StateError('TEST offline'))
              : Stream.value([product()]);
        },
      );
      await tester.pumpWidget(app.widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.textContaining('TEST offline'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(attempts, greaterThanOrEqualTo(2));
      expect(find.text('TEST Aqua'), findsWidgets);
    });
  }

  test('product detail routes remain customer-only', () {
    final path = Uri.parse('/products/test%20id');
    expect(authRedirect(AuthStatus.customer, path), isNull);
    expect(authRedirect(AuthStatus.signedOut, path), '/login');
    expect(authRedirect(AuthStatus.admin, path), '/admin/dashboard');
  });
}
