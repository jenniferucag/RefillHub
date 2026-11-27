import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/orders/data/order.dart';
import 'package:refillhub/features/orders/data/order_item.dart';
import 'package:refillhub/features/orders/data/order_status.dart';

void main() {
  group('OrderStatusHistory', () {
    test('creates a valid status history entry', () {
      final timestamp = DateTime.utc(2025, 1, 1);
      final history = OrderStatusHistory(
        status: 'pending',
        timestamp: timestamp,
        changedBy: 'system',
      );

      expect(history.status, 'pending');
      expect(history.timestamp, timestamp);
      expect(history.changedBy, 'system');
    });

    test('converts to JSON and back', () {
      final timestamp = DateTime.utc(2025, 1, 1);
      final original = OrderStatusHistory(
        status: 'confirmed',
        timestamp: timestamp,
        changedBy: 'admin_user_123',
      );

      final json = original.toJson();
      final restored = OrderStatusHistory.fromJson(json);

      expect(restored.status, original.status);
      expect(
        restored.timestamp.millisecondsSinceEpoch,
        original.timestamp.millisecondsSinceEpoch,
      );
      expect(restored.changedBy, original.changedBy);
    });

    test('rejects invalid JSON', () {
      expect(
        () => OrderStatusHistory.fromJson('not a map'),
        throwsFormatException,
      );
      expect(
        () =>
            OrderStatusHistory.fromJson({'status': '', 'timestamp': 'invalid'}),
        throwsFormatException,
      );
      expect(
        () => OrderStatusHistory.fromJson({'status': 'pending'}),
        throwsFormatException,
      );
    });

    test('rejects empty status or changedBy', () {
      final timestamp = DateTime.utc(2025, 1, 1);
      expect(
        () => OrderStatusHistory.fromJson({
          'status': '  ',
          'timestamp': timestamp,
          'changedBy': 'admin',
        }),
        throwsFormatException,
      );
      expect(
        () => OrderStatusHistory.fromJson({
          'status': 'pending',
          'timestamp': timestamp,
          'changedBy': '  ',
        }),
        throwsFormatException,
      );
    });
  });

  group('OrderStatus transitions', () {
    test('purchase follows its own status path', () {
      expect(orderStatusPath(isRefill: false).map((status) => status.label), [
        'Pending',
        'Confirmed',
        'Preparing',
        'Out for Delivery',
        'Delivered',
      ]);
      expect(
        canTransitionOrderStatus(
          orderType: 'purchase',
          current: 'Confirmed',
          next: 'Preparing',
        ),
        isTrue,
      );
      expect(
        canTransitionOrderStatus(
          orderType: 'purchase',
          current: 'Confirmed',
          next: 'Picked Up',
        ),
        isFalse,
      );
    });

    test('refill includes pickup and can only cancel before Preparing', () {
      expect(orderStatusPath(isRefill: true).map((status) => status.label), [
        'Pending',
        'Confirmed',
        'Picked Up',
        'Preparing',
        'Out for Delivery',
        'Delivered',
      ]);
      expect(
        canTransitionOrderStatus(
          orderType: 'refill',
          current: 'Confirmed',
          next: 'Picked Up',
        ),
        isTrue,
      );
      expect(
        canTransitionOrderStatus(
          orderType: 'refill',
          current: 'Confirmed',
          next: 'Preparing',
        ),
        isFalse,
      );
      expect(
        canTransitionOrderStatus(
          orderType: 'refill',
          current: 'Picked Up',
          next: 'Cancelled',
        ),
        isTrue,
      );
      expect(
        canTransitionOrderStatus(
          orderType: 'refill',
          current: 'Preparing',
          next: 'Cancelled',
        ),
        isFalse,
      );
    });

    test('tracks status lifecycle from pending to delivered', () {
      final now = DateTime.utc(2025, 1, 1);
      final history = <OrderStatusHistory>[
        OrderStatusHistory(
          status: 'pending',
          timestamp: now,
          changedBy: 'system',
        ),
        OrderStatusHistory(
          status: 'confirmed',
          timestamp: now.add(Duration(hours: 1)),
          changedBy: 'admin',
        ),
        OrderStatusHistory(
          status: 'ready',
          timestamp: now.add(Duration(hours: 2)),
          changedBy: 'system',
        ),
        OrderStatusHistory(
          status: 'in_transit',
          timestamp: now.add(Duration(hours: 3)),
          changedBy: 'delivery_person_1',
        ),
        OrderStatusHistory(
          status: 'delivered',
          timestamp: now.add(Duration(hours: 4)),
          changedBy: 'delivery_person_1',
        ),
      ];

      expect(history.length, 5);
      expect(history.first.status, 'pending');
      expect(history.last.status, 'delivered');
      expect(history[1].changedBy, 'admin');
      expect(history[3].changedBy, 'delivery_person_1');
    });

    test('detects cancelled order status', () {
      final now = DateTime.utc(2025, 1, 1);
      final history = <OrderStatusHistory>[
        OrderStatusHistory(
          status: 'pending',
          timestamp: now,
          changedBy: 'system',
        ),
        OrderStatusHistory(
          status: 'cancelled',
          timestamp: now.add(Duration(minutes: 30)),
          changedBy: 'customer_123',
        ),
      ];

      expect(history.last.status, 'cancelled');
      expect(history.length, 2);
    });

    test('records who changed the status', () {
      final now = DateTime.utc(2025, 1, 1);
      final histories = [
        OrderStatusHistory(
          status: 'pending',
          timestamp: now,
          changedBy: 'system',
        ),
        OrderStatusHistory(
          status: 'confirmed',
          timestamp: now,
          changedBy: 'admin_1',
        ),
        OrderStatusHistory(
          status: 'ready',
          timestamp: now,
          changedBy: 'system',
        ),
        OrderStatusHistory(
          status: 'in_transit',
          timestamp: now,
          changedBy: 'delivery_person_1',
        ),
      ];

      expect(histories.map((h) => h.changedBy), [
        'system',
        'admin_1',
        'system',
        'delivery_person_1',
      ]);
    });
  });

  group('CustomerOrder with status history', () {
    test('maintains immutable status history', () {
      final now = DateTime.utc(2025, 1, 1);
      final histories = <OrderStatusHistory>[
        OrderStatusHistory(
          status: 'pending',
          timestamp: now,
          changedBy: 'system',
        ),
      ];

      final order = CustomerOrder(
        id: 'order_123',
        orderNumber: 'RH-20250101-0001',
        customerId: 'customer_1',
        customerName: 'John Doe',
        phone: '09171234567',
        address: '123 Main St',
        notes: '',
        items: [
          OrderItem(
            productName: 'Product A',
            sizeLabel: 'Medium',
            unitPrice: 100,
            quantity: 2,
          ),
        ],
        totalAmount: '200',
        paymentMethod: 'Cash on Delivery',
        status: 'pending',
        statusHistory: histories,
        createdAt: now,
        updatedAt: now,
      );

      // Verify immutability
      expect(
        () => order.statusHistory.add(
          OrderStatusHistory(
            status: 'confirmed',
            timestamp: now,
            changedBy: 'admin',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('preserves order status from latest history', () {
      final now = DateTime.utc(2025, 1, 1);
      const finalStatus = 'delivered';
      final histories = <OrderStatusHistory>[
        OrderStatusHistory(
          status: 'pending',
          timestamp: now,
          changedBy: 'system',
        ),
        OrderStatusHistory(
          status: 'confirmed',
          timestamp: now,
          changedBy: 'admin',
        ),
        OrderStatusHistory(
          status: 'ready',
          timestamp: now,
          changedBy: 'system',
        ),
        OrderStatusHistory(
          status: 'delivered',
          timestamp: now,
          changedBy: 'delivery_person',
        ),
      ];

      final order = CustomerOrder(
        id: 'order_456',
        orderNumber: 'RH-20250101-0002',
        customerId: 'customer_2',
        customerName: 'Jane Smith',
        phone: '09171234568',
        address: '456 Oak Ave',
        notes: 'Handle with care',
        items: [
          OrderItem(
            productName: 'Product B',
            sizeLabel: 'Large',
            unitPrice: 250,
            quantity: 1,
          ),
        ],
        totalAmount: '250',
        paymentMethod: 'Cash on Delivery',
        status: finalStatus,
        statusHistory: histories,
        createdAt: now,
        updatedAt: now,
      );

      expect(order.status, finalStatus);
      expect(order.statusHistory.last.status, finalStatus);
    });
  });
}
