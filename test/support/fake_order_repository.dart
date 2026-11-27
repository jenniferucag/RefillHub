import 'dart:async';

import 'package:refillhub/features/cart/data/cart_item.dart';
import 'package:refillhub/features/checkout/data/checkout.dart';
import 'package:refillhub/features/orders/data/order.dart';
import 'package:refillhub/features/orders/data/order_item.dart';
import 'package:refillhub/features/orders/data/order_repository.dart';
import 'package:refillhub/features/orders/data/order_status.dart';

/// Fake in-memory implementation of OrderRepository for testing
/// Stores orders in memory without Firebase
class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository() : _orders = {};

  final Map<String, CustomerOrder> _orders;
  final _streamControllers =
      <String, List<StreamController<List<CustomerOrder>>>>{};
  final _allOrdersControllers = <StreamController<List<CustomerOrder>>>[];

  /// Get a specific order by ID
  @override
  Future<CustomerOrder?> getOrder(String orderId) async {
    return _orders[orderId];
  }

  /// Get customer orders
  @override
  Future<List<CustomerOrder>> getCustomerOrders(String customerId) async {
    return _sorted(
      _orders.values.where((order) => order.customerId == customerId),
    );
  }

  /// Place a new order
  @override
  Future<CustomerOrder> placeOrder(CheckoutRequest checkoutRequest) async {
    // Simulate order placement
    final now = DateTime.now().toUtc();
    final orderId = 'order_${DateTime.now().microsecondsSinceEpoch}';
    final orderNumber =
        'RH-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-0001';

    final items = [
      for (final item in checkoutRequest.items)
        OrderItem(
          productName: item.productName,
          waterType: item.waterType,
          sizeLabel: item.sizeLabel,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
        ),
    ];
    var totalAmount = cartTotal(checkoutRequest.items);
    if (checkoutRequest.deliveryFee != null) {
      totalAmount = addDecimals(totalAmount, checkoutRequest.deliveryFee!);
    }

    final order = CustomerOrder(
      id: orderId,
      orderNumber: orderNumber,
      customerId: 'test-customer',
      customerName: 'Test Customer',
      phone: checkoutRequest.phone,
      address: checkoutRequest.address,
      notes: checkoutRequest.notes,
      items: items,
      totalAmount: totalAmount,
      paymentMethod: checkoutRequest.paymentMethod,
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
      deliveryRequestedAt: checkoutRequest.deliveryRequestedAt,
    );

    _orders[orderId] = order;

    // Notify listeners
    _notifyCustomerOrdersChanged(order.customerId);

    return order;
  }

  @override
  Future<CustomerOrder> placeRefillOrder({
    required String productId,
    required String waterType,
    required String sizeLabel,
    required int quantity,
    required String address,
    required String phone,
    required String notes,
    required DateTime pickupRequestedAt,
    required DateTime deliveryRequestedAt,
  }) async {
    final now = DateTime.now().toUtc();
    final orderId = 'order_${DateTime.now().microsecondsSinceEpoch}';
    final order = CustomerOrder(
      id: orderId,
      orderNumber:
          'RH-${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}-0001',
      customerId: 'test-customer',
      customerName: 'Test Customer',
      phone: phone,
      address: address,
      notes: notes,
      items: const [],
      totalAmount: 'Price to be confirmed',
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
      orderType: 'refill',
      waterType: waterType,
      pickupRequestedAt: pickupRequestedAt,
      deliveryRequestedAt: deliveryRequestedAt,
      containerSize: sizeLabel,
      containerCount: quantity,
    );
    _orders[orderId] = order;
    _notifyCustomerOrdersChanged(order.customerId);
    return order;
  }

  @override
  Future<void> confirmOrder({
    required CustomerOrder order,
    required String changedBy,
    required DateTime deliveryScheduledAt,
    DateTime? pickupScheduledAt,
    String? totalAmount,
  }) async {
    final now = DateTime.now().toUtc();
    _orders[order.id] = _copyOrder(
      order,
      status: 'Confirmed',
      statusHistory: [
        ...order.statusHistory,
        OrderStatusHistory(
          status: 'Confirmed',
          timestamp: now,
          changedBy: changedBy,
        ),
      ],
      updatedAt: now,
      deliveryScheduledAt: deliveryScheduledAt,
      pickupScheduledAt: pickupScheduledAt,
      totalAmount: totalAmount,
    );
    _notifyCustomerOrdersChanged(order.customerId);
  }

  /// Watch a specific order by ID
  @override
  Stream<CustomerOrder?> watchOrder(String orderId) {
    final controller = StreamController<CustomerOrder?>();

    // Emit current value if exists
    if (_orders.containsKey(orderId)) {
      controller.add(_orders[orderId]);
    } else {
      controller.add(null);
    }

    return controller.stream;
  }

  /// Watch all orders for a customer
  @override
  Stream<List<CustomerOrder>> watchCustomerOrders(String customerId) {
    final controller = StreamController<List<CustomerOrder>>();

    // Emit current orders
    final orders =
        _orders.values.where((order) => order.customerId == customerId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    controller.add(orders);

    // Register for future updates
    if (!_streamControllers.containsKey(customerId)) {
      _streamControllers[customerId] = [];
    }
    _streamControllers[customerId]!.add(controller);

    return controller.stream;
  }

  @override
  Stream<List<CustomerOrder>> watchAllOrders() {
    final controller = StreamController<List<CustomerOrder>>();
    controller.add(_sorted(_orders.values));
    _allOrdersControllers.add(controller);
    return controller.stream;
  }

  @override
  Future<List<CustomerOrder>> getAllOrders() async => _sorted(_orders.values);

  @override
  Future<List<CustomerOrder>> getOrdersByStatus(String status) async =>
      _sorted(_orders.values.where((order) => order.status == status));

  @override
  Future<List<CustomerOrder>> searchOrders(String query) async {
    final normalized = query.toLowerCase();
    return _sorted(
      _orders.values.where(
        (order) =>
            order.orderNumber.toLowerCase().contains(normalized) ||
            order.customerName.toLowerCase().contains(normalized),
      ),
    );
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
    String changedBy, {
    String? cancellationReason,
  }) async {
    final order = _orders[orderId];
    if (order == null) throw StateError('Order not found.');
    if (changedBy.trim().isEmpty ||
        !canTransitionOrderStatus(
          orderType: order.orderType,
          current: order.status,
          next: newStatus,
        ) ||
        (newStatus != 'Cancelled' && cancellationReason != null)) {
      throw ArgumentError('Invalid order status transition.');
    }
    final now = DateTime.now().toUtc();
    _orders[orderId] = _copyOrder(
      order,
      status: newStatus,
      statusHistory: [
        ...order.statusHistory,
        OrderStatusHistory(
          status: newStatus,
          timestamp: now,
          changedBy: changedBy,
        ),
      ],
      updatedAt: now,
      cancellationReason: cancellationReason,
    );
    _notifyCustomerOrdersChanged(order.customerId);
  }

  @override
  Future<void> updateDeliveryPerson(
    String orderId,
    String deliveryPerson,
  ) async {
    final order = _orders[orderId];
    if (order == null) throw StateError('Order not found.');
    _orders[orderId] = _copyOrder(
      order,
      deliveryPerson: deliveryPerson,
      updatedAt: DateTime.now().toUtc(),
    );
    _notifyCustomerOrdersChanged(order.customerId);
  }

  /// Notify all watchers of customer orders
  void _notifyCustomerOrdersChanged(String customerId) {
    if (_streamControllers.containsKey(customerId)) {
      final orders =
          _orders.values
              .where((order) => order.customerId == customerId)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (final controller in _streamControllers[customerId]!) {
        controller.add(orders);
      }
    }
    for (final controller in _allOrdersControllers) {
      controller.add(_sorted(_orders.values));
    }
  }

  List<CustomerOrder> _sorted(Iterable<CustomerOrder> orders) =>
      orders.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  CustomerOrder _copyOrder(
    CustomerOrder order, {
    String? status,
    List<OrderStatusHistory>? statusHistory,
    String? deliveryPerson,
    String? cancellationReason,
    DateTime? updatedAt,
    DateTime? pickupScheduledAt,
    DateTime? deliveryScheduledAt,
    String? totalAmount,
  }) => CustomerOrder(
    id: order.id,
    orderNumber: order.orderNumber,
    customerId: order.customerId,
    customerName: order.customerName,
    phone: order.phone,
    address: order.address,
    notes: order.notes,
    cancellationReason: cancellationReason ?? order.cancellationReason,
    items: order.items,
    totalAmount: totalAmount ?? order.totalAmount,
    paymentMethod: order.paymentMethod,
    status: status ?? order.status,
    statusHistory: statusHistory ?? order.statusHistory,
    createdAt: order.createdAt,
    updatedAt: updatedAt ?? order.updatedAt,
    deliveryPerson: deliveryPerson ?? order.deliveryPerson,
    orderType: order.orderType,
    pickupRequestedAt: order.pickupRequestedAt,
    pickupScheduledAt: pickupScheduledAt ?? order.pickupScheduledAt,
    deliveryRequestedAt: order.deliveryRequestedAt,
    deliveryScheduledAt: deliveryScheduledAt ?? order.deliveryScheduledAt,
    containerSize: order.containerSize,
    containerCount: order.containerCount,
  );

  void seedOrder(CustomerOrder order) {
    _orders[order.id] = order;
  }

  /// Clear all orders (for testing)
  void clear() {
    _orders.clear();
  }

  /// Dispose all stream controllers
  void dispose() {
    for (final controllers in _streamControllers.values) {
      for (final controller in controllers) {
        controller.close();
      }
    }
    for (final controller in _allOrdersControllers) {
      controller.close();
    }
    _streamControllers.clear();
    _allOrdersControllers.clear();
  }
}
