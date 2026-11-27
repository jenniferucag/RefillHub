import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/core/widgets/app_card.dart';
import 'package:refillhub/features/orders/data/order.dart';
import 'package:refillhub/features/orders/data/order_providers.dart';
import 'package:refillhub/features/orders/data/order_status.dart';

import 'support/auth_test_support.dart';

CustomerOrder _order({
  required String id,
  required String status,
  required DateTime createdAt,
  String orderType = 'purchase',
  DateTime? pickupScheduledAt,
  DateTime? deliveryScheduledAt,
}) {
  final isRefill = orderType == 'refill';
  return CustomerOrder(
    id: id,
    orderNumber: 'RH-$id',
    customerId: 'customer-$id',
    customerName: 'Customer $id',
    phone: '09123456789',
    address: '12 Sample Street',
    notes: '',
    items: const [],
    totalAmount: '100',
    paymentMethod: 'Cash on Delivery',
    status: status,
    statusHistory: [
      OrderStatusHistory(
        status: status,
        timestamp: createdAt,
        changedBy: 'test',
      ),
    ],
    createdAt: createdAt,
    updatedAt: createdAt,
    orderType: orderType,
    pickupRequestedAt: isRefill ? createdAt : null,
    pickupScheduledAt: pickupScheduledAt,
    deliveryRequestedAt: createdAt,
    deliveryScheduledAt: deliveryScheduledAt,
    containerSize: isRefill ? 'Large' : null,
    containerCount: isRefill ? 1 : null,
    waterType: isRefill ? 'Purified' : 'Unspecified',
  );
}

void _useLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _metricCount(String label, String count) {
  final card = find
      .ancestor(of: find.text(label), matching: find.byType(AppCard))
      .first;
  return find.descendant(of: card, matching: find.text(count));
}

void main() {
  testWidgets(
    'dashboard aggregates Firestore orders and sorts upcoming events',
    (tester) async {
      _useLargeViewport(tester);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 10);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 8);
      final orders = [
        _order(id: 'PENDING', status: 'Pending', createdAt: today),
        _order(
          id: 'REFILL',
          status: 'Confirmed',
          orderType: 'refill',
          createdAt: today,
          pickupScheduledAt: tomorrow.add(const Duration(minutes: 10)),
          deliveryScheduledAt: tomorrow.add(const Duration(minutes: 20)),
        ),
        _order(
          id: 'PICKED-UP',
          status: 'Picked Up',
          createdAt: yesterday,
          deliveryScheduledAt: tomorrow.add(const Duration(minutes: 30)),
        ),
        _order(
          id: 'PREPARING',
          status: 'Preparing',
          createdAt: yesterday,
          deliveryScheduledAt: tomorrow.add(const Duration(minutes: 40)),
        ),
        _order(
          id: 'OUT',
          status: 'Out for Delivery',
          createdAt: yesterday,
          deliveryScheduledAt: tomorrow.add(const Duration(minutes: 50)),
        ),
        _order(
          id: 'SIXTH',
          status: 'Confirmed',
          createdAt: yesterday,
          deliveryScheduledAt: tomorrow.add(const Duration(minutes: 60)),
        ),
        _order(
          id: 'DELIVERED',
          status: 'Delivered',
          createdAt: today,
          deliveryScheduledAt: tomorrow.add(const Duration(minutes: 5)),
        ),
        _order(
          id: 'CANCELLED',
          status: 'Cancelled',
          orderType: 'refill',
          createdAt: today,
          pickupScheduledAt: tomorrow.add(const Duration(minutes: 2)),
          deliveryScheduledAt: tomorrow.add(const Duration(minutes: 3)),
        ),
      ];
      final app = TestApp(
        role: 'admin',
        initialLocation: '/admin/dashboard',
        extraOverrides: [
          watchAllOrdersProvider.overrideWith((ref) => Stream.value(orders)),
        ],
      );
      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      expect(_metricCount('Total Orders', '8'), findsOneWidget);
      expect(_metricCount('Pending', '1'), findsOneWidget);
      expect(_metricCount('In Progress', '5'), findsOneWidget);
      expect(_metricCount('Delivered', '1'), findsOneWidget);
      expect(_metricCount("Today's Orders", '4'), findsOneWidget);
      expect(_metricCount('Refill Orders', '2'), findsOneWidget);
      expect(_metricCount('Purchase Orders', '6'), findsOneWidget);

      expect(find.text('RH-PENDING'), findsOneWidget);
      expect(find.text('Pickup · RH-REFILL'), findsOneWidget);
      expect(find.text('Delivery · RH-REFILL'), findsOneWidget);
      expect(find.text('Delivery · RH-PICKED-UP'), findsOneWidget);
      expect(find.text('Delivery · RH-PREPARING'), findsOneWidget);
      expect(find.text('Delivery · RH-OUT'), findsOneWidget);
      expect(find.text('Delivery · RH-SIXTH'), findsNothing);
      expect(find.text('Pickup · RH-CANCELLED'), findsNothing);
      expect(find.text('Delivery · RH-DELIVERED'), findsNothing);

      final pickupY = tester.getTopLeft(find.text('Pickup · RH-REFILL')).dy;
      final refillDeliveryY = tester
          .getTopLeft(find.text('Delivery · RH-REFILL'))
          .dy;
      final nextDeliveryY = tester
          .getTopLeft(find.text('Delivery · RH-PICKED-UP'))
          .dy;
      expect(pickupY, lessThan(refillDeliveryY));
      expect(refillDeliveryY, lessThan(nextDeliveryY));
    },
  );

  testWidgets('dashboard shows loading and empty states', (tester) async {
    _useLargeViewport(tester);
    final controller = StreamController<List<CustomerOrder>>();
    addTearDown(controller.close);
    final loadingApp = TestApp(
      role: 'admin',
      initialLocation: '/admin/dashboard',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith((ref) => controller.stream),
      ],
    );
    await tester.pumpWidget(loadingApp.widget);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

    controller.add([]);
    await tester.pumpAndSettle();
    expect(find.text('No orders yet.'), findsOneWidget);
    expect(
      find.text('No upcoming scheduled pickups or deliveries.'),
      findsOneWidget,
    );
  });

  testWidgets('dashboard shows real Firestore errors and retry', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final errorApp = TestApp(
      role: 'admin',
      initialLocation: '/admin/dashboard',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith(
          (ref) => Stream.error(
            FirebaseException(
              plugin: 'cloud_firestore',
              message: 'Dashboard read failed',
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(errorApp.widget);
    await tester.pumpAndSettle();
    expect(find.textContaining('Dashboard read failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
