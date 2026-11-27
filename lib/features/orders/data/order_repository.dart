import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../cart/data/cart_item.dart';
import '../../checkout/data/checkout.dart';
import '../../products/data/product.dart';
import 'order_item.dart';
import 'order.dart';
import 'order_status.dart';

/// Reads and writes customer/admin orders in Firestore.
class OrderRepository {
  /// Creates a repository backed by [firestore].
  OrderRepository(FirebaseFirestore firestore)
    : _firestore = firestore,
      _orders = firestore.collection('orders');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _orders;

  /// Watches [orderId], emitting `null` when the order does not exist.
  Stream<CustomerOrder?> watchOrder(String orderId) => _orders
      .doc(orderId)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? CustomerOrder.fromMap(snapshot.id, snapshot.data()!)
            : null,
      );

  /// Watches the orders belonging to [customerId].
  Stream<List<CustomerOrder>> watchCustomerOrders(String customerId) => _orders
      .where('customerId', isEqualTo: customerId)
      .snapshots()
      .map(_toOrders)
      .map(_sortByCreatedAtDescending);

  /// Fetches [orderId] from the server, or returns `null` if it does not exist.
  Future<CustomerOrder?> getOrder(String orderId) async {
    final snapshot = await _orders
        .doc(orderId)
        .get(const GetOptions(source: Source.server));
    return snapshot.exists
        ? CustomerOrder.fromMap(snapshot.id, snapshot.data()!)
        : null;
  }

  /// Fetches all orders belonging to [customerId] from the server.
  Future<List<CustomerOrder>> getCustomerOrders(String customerId) async =>
      _toOrders(
        await _orders
            .where('customerId', isEqualTo: customerId)
            .get(const GetOptions(source: Source.server)),
      )..sort((first, second) => second.createdAt.compareTo(first.createdAt));

  /// Creates a purchase order directly in Firestore using current catalog data.
  Future<CustomerOrder> placeOrder(CheckoutRequest checkoutRequest) async {
    _validateCheckoutRequest(checkoutRequest);
    final uid = _requireCurrentUserId();
    final orderRef = _orders.doc();
    final profileRef = _firestore.collection('users').doc(uid);
    final productRefs = <String, DocumentReference<Map<String, dynamic>>>{};
    for (final item in checkoutRequest.items) {
      productRefs.putIfAbsent(
        item.productId,
        () => _firestore.collection('products').doc(item.productId),
      );
    }

    return _firestore.runTransaction((transaction) async {
      final profileSnapshot = await transaction.get(profileRef);
      if (!profileSnapshot.exists) {
        throw StateError('Your customer profile could not be found.');
      }
      final profile = profileSnapshot.data()!;
      final customerName = profile['name'];
      if (customerName is! String || customerName.trim().isEmpty) {
        throw StateError('Your customer profile is missing a name.');
      }

      final products = <String, Product>{};
      for (final entry in productRefs.entries) {
        final snapshot = await transaction.get(entry.value);
        if (!snapshot.exists) {
          throw const CheckoutException(
            'A product in your cart is no longer available.',
          );
        }
        final product = Product.fromMap(snapshot.id, snapshot.data()!);
        if (!product.isActive) {
          throw const CheckoutException(
            'A product in your cart is no longer available.',
          );
        }
        products[entry.key] = product;
      }

      final orderItems = <OrderItem>[];
      for (final item in checkoutRequest.items) {
        final product = products[item.productId]!;
        final matchingSizes = product.sizes
            .where((size) => size.label == item.sizeLabel)
            .toList();
        if (matchingSizes.length != 1) {
          throw const CheckoutException(
            'A product size in your cart is no longer available.',
          );
        }
        final size = matchingSizes.single;
        if (!size.isAvailable ||
            size.price != item.unitPrice ||
            product.name != item.productName ||
            product.waterType != item.waterType) {
          throw const CheckoutException(
            'A cart item changed. Review your cart before placing the order.',
          );
        }
        orderItems.add(
          OrderItem(
            productName: product.name,
            waterType: product.waterType,
            sizeLabel: size.label,
            unitPrice: size.price,
            quantity: item.quantity,
          ),
        );
      }

      final subtotal = cartTotal(checkoutRequest.items);
      final totalAmount = checkoutRequest.deliveryFee == null
          ? subtotal
          : addDecimals(subtotal, checkoutRequest.deliveryFee!);
      final now = DateTime.now();
      final utcNow = now.toUtc();
      final orderNumber = _newOrderNumber(now);
      final order = CustomerOrder(
        id: orderRef.id,
        orderNumber: orderNumber,
        customerId: uid,
        customerName: customerName.trim(),
        phone: checkoutRequest.phone.trim(),
        address: checkoutRequest.address.trim(),
        notes: checkoutRequest.notes.trim(),
        items: orderItems,
        totalAmount: totalAmount,
        paymentMethod: 'Cash on Delivery',
        status: OrderStatus.pending.label,
        statusHistory: [
          OrderStatusHistory(
            status: OrderStatus.pending.label,
            timestamp: utcNow,
            changedBy: uid,
          ),
        ],
        createdAt: utcNow,
        updatedAt: utcNow,
        orderType: 'purchase',
        deliveryRequestedAt: checkoutRequest.deliveryRequestedAt!.toUtc(),
      );
      transaction.set(orderRef, {
        ...order.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return order;
    });
  }

  /// Creates a refill order directly in Firestore using the catalog refill price.
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
    if (productId.trim().isEmpty ||
        waterType.trim().isEmpty ||
        sizeLabel.trim().isEmpty ||
        quantity < 1 ||
        quantity > 99 ||
        address.trim().isEmpty ||
        phone.trim().isEmpty ||
        pickupRequestedAt.isBefore(DateTime.now()) ||
        !deliveryRequestedAt.isAfter(pickupRequestedAt)) {
      throw ArgumentError('Refill order details are invalid.');
    }
    final uid = _requireCurrentUserId();
    final orderRef = _orders.doc();
    final profileRef = _firestore.collection('users').doc(uid);
    final productRef = _firestore.collection('products').doc(productId);

    return _firestore.runTransaction((transaction) async {
      final profileSnapshot = await transaction.get(profileRef);
      final productSnapshot = await transaction.get(productRef);
      if (!profileSnapshot.exists) {
        throw StateError('Your customer profile could not be found.');
      }
      if (!productSnapshot.exists) {
        throw const CheckoutException(
          'This refill size is no longer available.',
        );
      }
      final profile = profileSnapshot.data()!;
      final customerName = profile['name'];
      if (customerName is! String || customerName.trim().isEmpty) {
        throw StateError('Your customer profile is missing a name.');
      }
      final product = Product.fromMap(
        productSnapshot.id,
        productSnapshot.data()!,
      );
      if (!product.isActive || product.waterType != waterType.trim()) {
        throw const CheckoutException(
          'This refill option is no longer available.',
        );
      }
      final matchingSizes = product.sizes
          .where((candidate) => candidate.label == sizeLabel.trim())
          .toList();
      if (matchingSizes.length != 1 || !matchingSizes.single.isAvailable) {
        throw const CheckoutException(
          'This refill size is no longer available.',
        );
      }
      final size = matchingSizes.single;
      final unitPrice = size.refillPrice;
      final now = DateTime.now();
      final utcNow = now.toUtc();
      final orderNumber = _newOrderNumber(now);
      final item = OrderItem(
        productName: product.name,
        waterType: product.waterType,
        sizeLabel: size.label,
        unitPrice: unitPrice,
        quantity: quantity,
      );
      final totalAmount = unitPrice == null
          ? 'Price to be confirmed'
          : (unitPrice * quantity).toString();
      final order = CustomerOrder(
        id: orderRef.id,
        orderNumber: orderNumber,
        customerId: uid,
        customerName: customerName.trim(),
        phone: phone.trim(),
        address: address.trim(),
        notes: notes.trim(),
        items: [item],
        totalAmount: totalAmount,
        paymentMethod: 'Cash on Delivery',
        status: OrderStatus.pending.label,
        statusHistory: [
          OrderStatusHistory(
            status: OrderStatus.pending.label,
            timestamp: utcNow,
            changedBy: uid,
          ),
        ],
        createdAt: utcNow,
        updatedAt: utcNow,
        orderType: 'refill',
        waterType: product.waterType,
        pickupRequestedAt: pickupRequestedAt.toUtc(),
        deliveryRequestedAt: deliveryRequestedAt.toUtc(),
        containerSize: size.label,
        containerCount: quantity,
      );
      transaction.set(orderRef, {
        ...order.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return order;
    });
  }

  /// Requests a status transition and appends an entry to its history.
  ///
  /// Firestore rules authorize the caller and validate the transition.
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
    String changedBy, {
    String? cancellationReason,
  }) async {
    final order = await getOrder(orderId);
    if (order == null ||
        changedBy.trim().isEmpty ||
        !canTransitionOrderStatus(
          orderType: order.orderType,
          current: order.status,
          next: newStatus,
        ) ||
        (newStatus != OrderStatus.cancelled.label &&
            cancellationReason != null)) {
      throw ArgumentError('Invalid order status transition.');
    }
    final now = DateTime.now().toUtc();
    final statusEntry = OrderStatusHistory(
      status: newStatus,
      timestamp: now,
      changedBy: changedBy,
    );

    await _orders.doc(orderId).update({
      'status': newStatus,
      'statusHistory': FieldValue.arrayUnion([statusEntry.toJson()]),
      'updatedAt': Timestamp.fromDate(now),
      if (cancellationReason != null)
        'cancellationReason': cancellationReason.trim(),
    });
  }

  /// Confirms an order with accepted or admin-edited requested schedules.
  Future<void> confirmOrder({
    required CustomerOrder order,
    required String changedBy,
    required DateTime deliveryScheduledAt,
    DateTime? pickupScheduledAt,
    String? totalAmount,
  }) async {
    final parsedTotal = totalAmount == null ? null : num.tryParse(totalAmount);
    if (!canTransitionOrderStatus(
          orderType: order.orderType,
          current: order.status,
          next: OrderStatus.confirmed.label,
        ) ||
        changedBy.trim().isEmpty ||
        !deliveryScheduledAt.isAfter(DateTime.now()) ||
        (order.isRefill &&
            (pickupScheduledAt == null ||
                !pickupScheduledAt.isAfter(DateTime.now()) ||
                !deliveryScheduledAt.isAfter(pickupScheduledAt))) ||
        ((order.totalAmount == 'Price to be confirmed') !=
            (totalAmount != null)) ||
        (totalAmount != null &&
            (parsedTotal == null ||
                !parsedTotal.isFinite ||
                parsedTotal <= 0))) {
      throw ArgumentError('Confirmation details are invalid.');
    }
    final now = DateTime.now().toUtc();
    final statusEntry = OrderStatusHistory(
      status: OrderStatus.confirmed.label,
      timestamp: now,
      changedBy: changedBy,
    );
    final scheduledPickup = order.isRefill ? pickupScheduledAt : null;
    final updates = <String, Object?>{
      'status': OrderStatus.confirmed.label,
      'statusHistory': FieldValue.arrayUnion([statusEntry.toJson()]),
      'updatedAt': Timestamp.fromDate(now),
      'deliveryScheduledAt': Timestamp.fromDate(deliveryScheduledAt),
    };
    if (scheduledPickup != null) {
      updates['pickupScheduledAt'] = Timestamp.fromDate(scheduledPickup);
    }
    if (totalAmount != null) updates['totalAmount'] = totalAmount.trim();
    await _orders.doc(order.id).update(updates);
  }

  /// Watches all orders, intended for active administrators.
  Stream<List<CustomerOrder>> watchAllOrders() =>
      _orders.snapshots().map(_toOrders).map(_sortByCreatedAtDescending);

  /// Fetches all orders from the server, intended for active administrators.
  Future<List<CustomerOrder>> getAllOrders() async => _toOrders(
    await _orders
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.server)),
  );

  /// Searches order numbers and customer names case-insensitively.
  Future<List<CustomerOrder>> searchOrders(String query) async {
    if (query.trim().isEmpty) {
      return getAllOrders();
    }

    final orders = await getAllOrders();
    final lowerQuery = query.toLowerCase();

    return orders
        .where(
          (order) =>
              order.orderNumber.toLowerCase().contains(lowerQuery) ||
              order.customerName.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// Fetches orders whose current status equals [status].
  Future<List<CustomerOrder>> getOrdersByStatus(String status) async {
    final orders = await getAllOrders();
    return orders.where((order) => order.status == status).toList();
  }

  /// Assigns [deliveryPerson] to [orderId].
  Future<void> updateDeliveryPerson(
    String orderId,
    String deliveryPerson,
  ) async {
    await _orders.doc(orderId).update({
      'deliveryPerson': deliveryPerson,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Validate checkout request
  void _validateCheckoutRequest(CheckoutRequest request) {
    if (request.items.isEmpty) {
      throw ArgumentError('Order must contain at least one item.');
    }
    if (request.phone.trim().isEmpty) {
      throw ArgumentError('Phone number is required.');
    }
    if (request.address.trim().isEmpty) {
      throw ArgumentError('Address is required.');
    }
    if (request.deliveryRequestedAt == null ||
        !request.deliveryRequestedAt!.isAfter(DateTime.now())) {
      throw ArgumentError('Requested delivery must be in the future.');
    }
    if (request.deliveryFee != null &&
        parseDeliveryFee(request.deliveryFee) == null) {
      throw ArgumentError('Delivery fee is invalid.');
    }
    for (final item in request.items) {
      if (item.productId.trim().isEmpty ||
          item.quantity < 1 ||
          item.quantity > CartItem.maxQuantity) {
        throw ArgumentError('Order items are invalid.');
      }
    }
  }

  String _requireCurrentUserId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('You must be signed in to place an order.');
    }
    return uid;
  }

  String _newOrderNumber(DateTime dateTime) {
    final day =
        '${dateTime.year.toString().padLeft(4, '0')}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}';
    final suffix = Random.secure().nextInt(10000).toString().padLeft(4, '0');
    return 'RH-$day-$suffix';
  }

  List<CustomerOrder> _toOrders(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map(
            (document) => CustomerOrder.fromMap(document.id, document.data()),
          )
          .toList();

  List<CustomerOrder> _sortByCreatedAtDescending(List<CustomerOrder> orders) =>
      orders
        ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
}
