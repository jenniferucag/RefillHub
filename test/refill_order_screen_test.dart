import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/products/data/product.dart';

import 'support/auth_test_support.dart';

Product _product({
  required String id,
  required String name,
  required String waterType,
  required ProductSize size,
}) => Product(
  id: id,
  name: name,
  waterType: waterType,
  description: '',
  isActive: true,
  createdAt: DateTime.utc(2025),
  sizes: [size],
);

void main() {
  testWidgets('refill selects water type before showing its sizes', (
    tester,
  ) async {
    final app = TestApp(
      role: 'customer',
      initialLocation: '/refill',
      productsStream: () => Stream.value([
        _product(
          id: 'purified',
          name: 'Purified product',
          waterType: 'Purified',
          size: const ProductSize(label: '5 L', price: 20, isAvailable: true),
        ),
        _product(
          id: 'mineral',
          name: 'Mineral product',
          waterType: 'Mineral',
          size: const ProductSize(label: '10 L', price: 30, isAvailable: true),
        ),
      ]),
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mineral').last);
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    expect(find.text('10 L'), findsOneWidget);
    expect(find.text('5 L'), findsNothing);
  });

  testWidgets('refill reports when a selected type has no available sizes', (
    tester,
  ) async {
    final app = TestApp(
      role: 'customer',
      initialLocation: '/refill',
      productsStream: () => Stream.value([
        _product(
          id: 'mineral',
          name: 'Mineral product',
          waterType: 'Mineral',
          size: const ProductSize(label: '10 L', price: 30, isAvailable: false),
        ),
      ]),
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mineral').last);
    await tester.pumpAndSettle();

    expect(find.text('No products available for this type'), findsOneWidget);
  });
}
