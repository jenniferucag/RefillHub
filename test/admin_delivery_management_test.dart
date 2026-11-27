import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/orders/data/order.dart';
import 'package:refillhub/features/orders/data/order_item.dart';
import 'package:refillhub/features/orders/data/order_providers.dart';
import 'package:refillhub/features/orders/data/order_status.dart';

import 'support/auth_test_support.dart';
import 'support/fake_order_repository.dart';

void _useLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

CustomerOrder _order({
  required String id,
  required String status,
  required String orderType,
  required DateTime scheduledAt,
  DateTime? deliveryScheduledAt,
  String? deliveryPerson,
}) {
  final createdAt = DateTime.utc(2027, 1, 1);
  return CustomerOrder(
    id: id,
    orderNumber: 'RH-$id',
    customerId: 'customer',
    customerName: 'Test Customer',
    phone: '09123456789',
    address: '12 Sample Street',
    notes: '',
    items: orderType == 'refill'
        ? const []
        : const [
            OrderItem(
              productName: 'Purified water',
              waterType: 'Purified',
              sizeLabel: 'Large',
              unitPrice: 20,
              quantity: 1,
            ),
          ],
    totalAmount: orderType == 'refill' ? 'Price to be confirmed' : '20',
    paymentMethod: 'Cash on Delivery',
    status: status,
    statusHistory: [
      OrderStatusHistory(
        status: status,
        timestamp: createdAt,
        changedBy: 'system',
      ),
    ],
    createdAt: createdAt,
    updatedAt: createdAt,
    orderType: orderType,
    pickupRequestedAt: orderType == 'refill' ? createdAt : null,
    pickupScheduledAt: orderType == 'refill' ? scheduledAt : null,
    deliveryRequestedAt: createdAt,
    deliveryScheduledAt:
        deliveryScheduledAt ?? (orderType == 'purchase' ? scheduledAt : null),
    containerSize: orderType == 'refill' ? 'Large' : null,
    containerCount: orderType == 'refill' ? 1 : null,
    waterType: orderType == 'refill' ? 'Mineral' : 'Unspecified',
    deliveryPerson: deliveryPerson,
  );
}

void main() {
  testWidgets('delivery orders are grouped by scheduled day and time', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final orders = [
      _order(
        id: 'later-refill',
        status: 'Confirmed',
        orderType: 'refill',
        scheduledAt: DateTime(2027, 1, 5, 15),
        deliveryScheduledAt: DateTime(2027, 1, 6, 12),
        deliveryPerson: 'Sam Driver',
      ),
      _order(
        id: 'later-purchase',
        status: 'Out for Delivery',
        orderType: 'purchase',
        scheduledAt: DateTime(2027, 1, 4, 9),
      ),
      _order(
        id: 'early-refill',
        status: 'Picked Up',
        orderType: 'refill',
        scheduledAt: DateTime(2027, 1, 4, 8),
        deliveryScheduledAt: DateTime(2027, 1, 5, 12),
      ),
      _order(
        id: 'preparing',
        status: 'Preparing',
        orderType: 'purchase',
        scheduledAt: DateTime(2027, 1, 4, 11),
      ),
      _order(
        id: 'pending',
        status: 'Pending',
        orderType: 'purchase',
        scheduledAt: DateTime(2027, 1, 4, 7),
      ),
    ];
    final app = TestApp(
      role: 'admin',
      initialLocation: '/admin/delivery',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith((ref) => Stream.value(orders)),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.text('2027-01-04'), findsOneWidget);
    expect(find.text('2027-01-05'), findsOneWidget);
    expect(find.text('RH-pending'), findsNothing);
    expect(find.text('RH-early-refill'), findsOneWidget);
    expect(find.text('RH-later-purchase'), findsOneWidget);
    expect(find.text('Refill'), findsNWidgets(2));
    expect(find.text('Purchase'), findsNWidgets(2));
    expect(find.text('12 Sample Street'), findsNWidgets(4));
    expect(find.text('09123456789'), findsNWidgets(4));
    expect(find.text('2027-01-04 08:00'), findsOneWidget);
    expect(find.text('2027-01-04 09:00'), findsOneWidget);
    expect(find.text('2027-01-04 11:00'), findsOneWidget);
    expect(find.text('Sam Driver'), findsNWidgets(2));
    expect(find.text('1'), findsNWidgets(4));

    final earlyRefillY = tester.getTopLeft(find.text('RH-early-refill')).dy;
    final laterPurchaseY = tester.getTopLeft(find.text('RH-later-purchase')).dy;
    expect(earlyRefillY, lessThan(laterPurchaseY));
  });

  testWidgets('delivery actions use type-aware transitions and save assignee', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repository = FakeOrderRepository();
    final refill = _order(
      id: 'refill',
      status: 'Confirmed',
      orderType: 'refill',
      scheduledAt: DateTime(2027, 1, 5, 10),
      deliveryScheduledAt: DateTime(2027, 1, 6, 10),
    );
    final purchase = _order(
      id: 'purchase',
      status: 'Preparing',
      orderType: 'purchase',
      scheduledAt: DateTime(2027, 1, 5, 11),
    );
    repository
      ..seedOrder(refill)
      ..seedOrder(purchase);
    final app = TestApp(
      role: 'admin',
      initialLocation: '/admin/delivery',
      extraOverrides: [
        orderRepositoryProvider.overrideWithValue(repository),
        watchAllOrdersProvider.overrideWith(
          (ref) => ref.watch(orderRepositoryProvider).watchAllOrders(),
        ),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.text('Mark Picked Up'), findsOneWidget);
    expect(find.text('Mark Out for Delivery'), findsOneWidget);
    expect(find.text('Start Preparing'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Ava Driver');
    await tester.tap(find.text('Assign').first);
    await tester.pumpAndSettle();
    expect(
      (await repository.getOrder(refill.id))?.deliveryPerson,
      'Ava Driver',
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark Picked Up'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect((await repository.getOrder(refill.id))?.status, 'Picked Up');

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Mark Out for Delivery'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(
      (await repository.getOrder(purchase.id))?.status,
      'Out for Delivery',
    );

    repository.dispose();
  });

  testWidgets('delivery empty state uses the live stream result', (
    tester,
  ) async {
    final emptyApp = TestApp(
      role: 'admin',
      initialLocation: '/admin/delivery',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
    await tester.pumpWidget(emptyApp.widget);
    await tester.pumpAndSettle();
    expect(find.text('No orders to deliver'), findsOneWidget);
  });

  testWidgets('delivery stream errors show Firebase message and retry', (
    tester,
  ) async {
    final errorApp = TestApp(
      role: 'admin',
      initialLocation: '/admin/delivery',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith(
          (ref) => Stream.error(
            FirebaseException(
              plugin: 'cloud_firestore',
              message: 'Delivery read failed',
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(errorApp.widget);
    await tester.pumpAndSettle();
    expect(find.textContaining('Delivery read failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
