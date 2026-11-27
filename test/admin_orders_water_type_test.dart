import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/core/widgets/status_chip.dart' as status_presentation;
import 'package:refillhub/features/orders/data/order.dart';
import 'package:refillhub/features/orders/data/order_item.dart';
import 'package:refillhub/features/orders/data/order_providers.dart';
import 'package:refillhub/features/orders/data/order_status.dart';

import 'support/auth_test_support.dart';

CustomerOrder _order({
  required String id,
  required String orderType,
  String waterType = 'Unspecified',
  List<OrderItem> items = const [],
  DateTime? deliveryScheduledAt,
}) {
  final now = DateTime.utc(2025, 1, 1);
  return CustomerOrder(
    id: id,
    orderNumber: id,
    customerId: 'customer',
    customerName: 'Customer',
    phone: '09123456789',
    address: 'Address',
    notes: '',
    items: items,
    totalAmount: '10',
    paymentMethod: 'Cash on Delivery',
    status: 'Pending',
    statusHistory: [
      OrderStatusHistory(
        status: 'Pending',
        timestamp: now,
        changedBy: 'system',
      ),
    ],
    createdAt: now,
    updatedAt: now,
    orderType: orderType,
    waterType: waterType,
    pickupRequestedAt: orderType == 'refill' ? now : null,
    containerSize: orderType == 'refill' ? 'Large' : null,
    containerCount: orderType == 'refill' ? 1 : null,
    deliveryRequestedAt: now.add(const Duration(days: 1)),
    deliveryScheduledAt: deliveryScheduledAt,
  );
}

void main() {
  testWidgets('empty admin order stream shows the empty state', (tester) async {
    final app = TestApp(
      role: 'admin',
      initialLocation: '/admin/orders',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.text('No orders yet'), findsOneWidget);
  });

  testWidgets('admin order stream error shows the Firebase message and retry', (
    tester,
  ) async {
    final app = TestApp(
      role: 'admin',
      initialLocation: '/admin/orders',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith(
          (ref) => Stream.error(
            FirebaseException(
              plugin: 'cloud_firestore',
              message: 'Permission denied',
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.textContaining('Permission denied'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('admin water type filter matches refill and purchase orders', (
    tester,
  ) async {
    final orders = [
      _order(id: 'RH-REFILL', orderType: 'refill', waterType: 'Mineral'),
      _order(
        id: 'RH-PURCHASE',
        orderType: 'purchase',
        deliveryScheduledAt: DateTime.utc(2025, 1, 3),
        items: const [
          OrderItem(
            productName: 'Purified water',
            waterType: 'Purified',
            sizeLabel: 'Large',
            unitPrice: 10,
            quantity: 1,
          ),
        ],
      ),
    ];
    final app = TestApp(
      role: 'admin',
      initialLocation: '/admin/orders',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith((ref) => Stream.value(orders)),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.text('RH-REFILL'), findsOneWidget);
    expect(find.text('RH-PURCHASE'), findsOneWidget);
    expect(find.text('Water type: Mineral'), findsOneWidget);
    expect(find.text('Water type: Purified'), findsOneWidget);
    expect(find.textContaining('Requested delivery:'), findsOneWidget);
    expect(find.textContaining('Scheduled delivery:'), findsOneWidget);
    expect(find.byType(status_presentation.StatusChip), findsNWidgets(2));
    await tester.tap(find.widgetWithText(FilterChip, 'Mineral'));
    await tester.pumpAndSettle();
    expect(find.text('RH-REFILL'), findsOneWidget);
    expect(find.text('RH-PURCHASE'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'All water types'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Purified'));
    await tester.pumpAndSettle();
    expect(find.text('RH-PURCHASE'), findsOneWidget);
    expect(find.text('RH-REFILL'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'All water types'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'RH-PURCHASE');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('RH-PURCHASE'),
      ),
      findsOneWidget,
    );
    expect(find.text('RH-REFILL'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Customer');
    await tester.pumpAndSettle();
    expect(find.text('RH-PURCHASE'), findsOneWidget);
    expect(find.text('RH-REFILL'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Confirmed'));
    await tester.pumpAndSettle();
    expect(find.text('No orders match the selected filters.'), findsOneWidget);
  });
}
