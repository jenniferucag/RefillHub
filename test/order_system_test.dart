import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/cart/data/cart_item.dart';
import 'package:refillhub/features/checkout/data/checkout.dart';
import 'package:refillhub/features/orders/data/order.dart';
import 'package:refillhub/features/orders/data/order_item.dart';
import 'package:refillhub/features/orders/data/order_status.dart';

void main() {
  group('Order System', () {
    group('OrderItem', () {
      test('creates order item with required fields', () {
        final item = OrderItem(
          productName: 'Test Product',
          sizeLabel: '500ml',
          unitPrice: 10.5,
          quantity: 2,
        );

        expect(item.productName, 'Test Product');
        expect(item.sizeLabel, '500ml');
        expect(item.unitPrice, 10.5);
        expect(item.quantity, 2);
        expect(item.lineTotal, 21.0);
      });

      test('handles decimal precision in line total', () {
        final item = OrderItem(
          productName: 'Test',
          sizeLabel: '1L',
          unitPrice: 9.99,
          quantity: 3,
        );

        expect(item.lineTotal, 29.97);
      });

      test('converts to and from JSON', () {
        final original = OrderItem(
          productName: 'Test Product',
          waterType: 'Purified',
          sizeLabel: '1L',
          unitPrice: 15.50,
          quantity: 2,
        );

        final json = original.toJson();
        final restored = OrderItem.fromJson(json);

        expect(restored.productName, original.productName);
        expect(restored.waterType, original.waterType);
        expect(restored.sizeLabel, original.sizeLabel);
        expect(restored.unitPrice, original.unitPrice);
        expect(restored.quantity, original.quantity);
        expect(json['lineTotal'], 31.0);
      });

      test('preserves an unpriced refill line without inventing a total', () {
        final item = OrderItem(
          productName: 'Test Product',
          sizeLabel: 'Large',
          unitPrice: null,
          quantity: 2,
        );

        expect(item.lineTotal, isNull);
        expect(item.toJson()['unitPrice'], isNull);
        expect(item.toJson()['lineTotal'], isNull);
        expect(
          OrderItem.fromJson(item.toJson()).lineTotal,
          isNull,
        );
      });

      test('validates required fields on creation from JSON', () {
        expect(() => OrderItem.fromJson({}), throwsFormatException);

        expect(
          () => OrderItem.fromJson({'productName': 'Test'}),
          throwsFormatException,
        );
      });

      test('rejects invalid quantity', () {
        expect(
          () => OrderItem.fromJson({
            'productName': 'Test',
            'sizeLabel': '500ml',
            'unitPrice': 10.5,
            'quantity': 0, // Invalid: must be >= 1
          }),
          throwsFormatException,
        );

        expect(
          () => OrderItem.fromJson({
            'productName': 'Test',
            'sizeLabel': '500ml',
            'unitPrice': 10.5,
            'quantity': 100, // Invalid: must be <= 99
          }),
          throwsFormatException,
        );
      });

      test('rejects invalid price', () {
        expect(
          () => OrderItem.fromJson({
            'productName': 'Test',
            'sizeLabel': '500ml',
            'unitPrice': -10, // Invalid: must be > 0
            'quantity': 2,
          }),
          throwsFormatException,
        );
      });
    });

    group('OrderStatusHistory', () {
      test('creates status history entry', () {
        final now = DateTime.utc(2025, 1, 1, 12, 0, 0);
        final history = OrderStatusHistory(
          status: 'Pending',
          timestamp: now,
          changedBy: 'customer-123',
        );

        expect(history.status, 'Pending');
        expect(history.timestamp, now);
        expect(history.changedBy, 'customer-123');
      });

      test('converts to and from JSON', () {
        final now = DateTime.utc(2025, 1, 1);
        final original = OrderStatusHistory(
          status: 'Shipped',
          timestamp: now,
          changedBy: 'admin-456',
        );

        final json = original.toJson();
        final restored = OrderStatusHistory.fromJson(json);

        expect(restored.status, original.status);
        expect(restored.timestamp.toUtc(), original.timestamp);
        expect(restored.changedBy, original.changedBy);
      });

      test('validates required fields on creation from JSON', () {
        expect(() => OrderStatusHistory.fromJson({}), throwsFormatException);
      });

      test('rejects empty status or changedBy', () {
        expect(
          () => OrderStatusHistory.fromJson({
            'status': '', // Empty
            'timestamp': DateTime.now(),
            'changedBy': 'admin',
          }),
          throwsFormatException,
        );
      });
    });

    group('CustomerOrder', () {
      final now = DateTime.utc(2025, 1, 1, 12, 0, 0);
      final items = [
        OrderItem(
          productName: 'Product 1',
          sizeLabel: '500ml',
          unitPrice: 10.00,
          quantity: 2,
        ),
        OrderItem(
          productName: 'Product 2',
          sizeLabel: '1L',
          unitPrice: 15.00,
          quantity: 1,
        ),
      ];

      final history = [
        OrderStatusHistory(
          status: 'Pending',
          timestamp: now,
          changedBy: 'customer-123',
        ),
      ];

      test('creates customer order with all required fields', () {
        final order = CustomerOrder(
          id: 'order-1',
          orderNumber: 'RH-20250101-0001',
          customerId: 'customer-123',
          customerName: 'John Doe',
          phone: '+1234567890',
          address: '123 Main St',
          notes: 'Please ring doorbell',
          items: items,
          totalAmount: '35.00',
          paymentMethod: 'Cash on Delivery',
          status: 'Pending',
          statusHistory: history,
          createdAt: now,
          updatedAt: now,
        );

        expect(order.id, 'order-1');
        expect(order.orderNumber, 'RH-20250101-0001');
        expect(order.customerId, 'customer-123');
        expect(order.customerName, 'John Doe');
        expect(order.phone, '+1234567890');
        expect(order.address, '123 Main St');
        expect(order.notes, 'Please ring doorbell');
        expect(order.items.length, 2);
        expect(order.totalAmount, '35.00');
        expect(order.paymentMethod, 'Cash on Delivery');
        expect(order.status, 'Pending');
        expect(order.statusHistory.length, 1);
      });

      test('converts to map with all fields', () {
        final order = CustomerOrder(
          id: 'order-1',
          orderNumber: 'RH-20250101-0001',
          customerId: 'customer-123',
          customerName: 'John Doe',
          phone: '+1234567890',
          address: '123 Main St',
          notes: 'Test notes',
          items: items,
          totalAmount: '35.00',
          paymentMethod: 'Cash on Delivery',
          status: 'Pending',
          statusHistory: history,
          createdAt: now,
          updatedAt: now,
        );

        final map = order.toMap();

        expect(map['orderNumber'], 'RH-20250101-0001');
        expect(map['customerId'], 'customer-123');
        expect(map['customerName'], 'John Doe');
        expect(map['phone'], '+1234567890');
        expect(map['address'], '123 Main St');
        expect(map['notes'], 'Test notes');
        expect(map['items'], isA<List>());
        expect((map['items'] as List).length, 2);
        expect(map.containsKey('waterType'), isFalse);
        expect(
          ((map['items'] as List).first as Map<String, Object?>)['waterType'],
          'Unspecified',
        );
        expect(map['totalAmount'], '35.00');
        expect(map['paymentMethod'], 'Cash on Delivery');
        expect(map['status'], 'Pending');
        expect(map['statusHistory'], isA<List>());
        // Timestamps come from Firestore serialization
        expect(map['createdAt'], isNotNull);
        expect(map['updatedAt'], isNotNull);
      });

      test('restores from map preserving all data', () {
        final order = CustomerOrder(
          id: 'order-1',
          orderNumber: 'RH-20250101-0001',
          customerId: 'customer-123',
          customerName: 'John Doe',
          phone: '+1234567890',
          address: '123 Main St',
          notes: 'Test notes',
          items: items,
          totalAmount: '35.00',
          paymentMethod: 'Cash on Delivery',
          status: 'Pending',
          statusHistory: history,
          createdAt: now,
          updatedAt: now,
        );

        final map = order.toMap();
        final restored = CustomerOrder.fromMap('order-1', map);

        expect(restored.id, 'order-1');
        expect(restored.orderNumber, 'RH-20250101-0001');
        expect(restored.customerId, 'customer-123');
        expect(restored.customerName, 'John Doe');
        expect(restored.phone, '+1234567890');
        expect(restored.address, '123 Main St');
        expect(restored.notes, 'Test notes');
        expect(restored.items.length, 2);
        expect(restored.items[0].productName, 'Product 1');
        expect(restored.items[0].waterType, 'Unspecified');
        expect(restored.items[1].productName, 'Product 2');
        expect(restored.totalAmount, '35.00');
        expect(restored.paymentMethod, 'Cash on Delivery');
        expect(restored.status, 'Pending');
        expect(restored.statusHistory.length, 1);
        expect(restored.statusHistory[0].status, 'Pending');
        // Compare timestamps at UTC precision (seconds)
        expect(restored.createdAt.toUtc(), now.toUtc());
        expect(restored.updatedAt.toUtc(), now.toUtc());
      });

      test('round trips order type and requested and scheduled times', () {
        final pickupRequested = now.add(const Duration(days: 1));
        final pickupScheduled = now.add(const Duration(days: 2));
        final deliveryRequested = now.add(const Duration(days: 3));
        final deliveryScheduled = now.add(const Duration(days: 4));
        final order = CustomerOrder(
          id: 'refill-order',
          orderNumber: 'RH-20250101-0003',
          customerId: 'customer-123',
          customerName: 'John Doe',
          phone: '+1234567890',
          address: '123 Main St',
          notes: '',
          items: const [],
          totalAmount: 'Price to be confirmed',
          paymentMethod: 'Cash on Delivery',
          status: 'Pending',
          statusHistory: history,
          createdAt: now,
          updatedAt: now,
          orderType: 'refill',
          waterType: 'Mineral',
          pickupRequestedAt: pickupRequested,
          pickupScheduledAt: pickupScheduled,
          deliveryRequestedAt: deliveryRequested,
          deliveryScheduledAt: deliveryScheduled,
          containerSize: 'Large',
          containerCount: 2,
        );
        final restored = CustomerOrder.fromMap('refill-order', order.toMap());

        expect(order.toMap()['totalAmount'], isNull);
        expect(restored.orderType, 'refill');
        expect(restored.waterType, 'Mineral');
        expect(restored.pickupRequestedAt, pickupRequested);
        expect(restored.pickupScheduledAt, pickupScheduled);
        expect(restored.deliveryRequestedAt, deliveryRequested);
        expect(restored.deliveryScheduledAt, deliveryScheduled);
        expect(restored.containerSize, 'Large');
        expect(restored.containerCount, 2);
        expect(restored.totalAmount, 'Price to be confirmed');
      });

      test('validates required fields on creation', () {
        expect(
          () => CustomerOrder.fromMap('order-1', {}),
          throwsFormatException,
        );
      });

      test('order immutability - items is unmodifiable list', () {
        final order = CustomerOrder(
          id: 'order-1',
          orderNumber: 'RH-20250101-0001',
          customerId: 'customer-123',
          customerName: 'John Doe',
          phone: '+1234567890',
          address: '123 Main St',
          notes: '',
          items: items,
          totalAmount: '35.00',
          paymentMethod: 'Cash on Delivery',
          status: 'Pending',
          statusHistory: history,
          createdAt: now,
          updatedAt: now,
        );

        expect(
          () => order.items.add(
            OrderItem(
              productName: 'New',
              sizeLabel: '500ml',
              unitPrice: 10.00,
              quantity: 1,
            ),
          ),
          throwsUnsupportedError,
        );
      });

      test('order immutability - statusHistory is unmodifiable list', () {
        final order = CustomerOrder(
          id: 'order-1',
          orderNumber: 'RH-20250101-0001',
          customerId: 'customer-123',
          customerName: 'John Doe',
          phone: '+1234567890',
          address: '123 Main St',
          notes: '',
          items: items,
          totalAmount: '35.00',
          paymentMethod: 'Cash on Delivery',
          status: 'Pending',
          statusHistory: history,
          createdAt: now,
          updatedAt: now,
        );

        expect(
          () => order.statusHistory.add(
            OrderStatusHistory(
              status: 'Shipped',
              timestamp: now,
              changedBy: 'admin',
            ),
          ),
          throwsUnsupportedError,
        );
      });
    });

    group('CheckoutRequest validation', () {
      test('valid checkout request has all required fields', () {
        final items = [
          CartItem(
            productId: 'prod1',
            productName: 'Test',
            sizeLabel: '500ml',
            unitPrice: 10.5,
            quantity: 1,
          ),
        ];

        final request = CheckoutRequest(
          items: items,
          phone: '+1234567890',
          address: '123 Main St',
          deliveryFee: null,
          notes: 'Test',
        );

        expect(request.phone, '+1234567890');
        expect(request.address, '123 Main St');
        expect(request.deliveryFee, isNull);
        expect(request.notes, 'Test');
        expect(request.paymentMethod, 'Cash on Delivery');
      });
    });
  });
}
