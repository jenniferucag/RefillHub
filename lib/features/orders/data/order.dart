import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_item.dart';
import 'order_status.dart';

/// Customer order snapshot stored in the `orders` Firestore collection.
///
/// The order number uses the format `RH-YYYYMMDD-####`.
class CustomerOrder {
  /// Creates an order with immutable item and status-history lists.
  CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.notes,
    this.cancellationReason,
    required List<OrderItem> items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required List<OrderStatusHistory> statusHistory,
    required this.createdAt,
    required this.updatedAt,
    this.deliveryPerson,
    this.orderType = 'purchase',
    this.pickupRequestedAt,
    this.pickupScheduledAt,
    this.deliveryRequestedAt,
    this.deliveryScheduledAt,
    this.containerSize,
    this.containerCount,
    this.waterType = 'Unspecified',
  }) : items = List.unmodifiable(items),
       statusHistory = List.unmodifiable(statusHistory);

  /// Firestore document ID.
  final String id;

  /// Human-readable order reference.
  final String orderNumber;

  /// UID of the customer who owns this order.
  final String customerId;

  /// Customer name copied from the profile when the order is placed.
  final String customerName;

  /// Delivery contact phone number.
  final String phone;

  /// Delivery address.
  final String address;

  /// Optional customer instructions.
  final String notes;

  /// Reason provided by an administrator when rejecting the order.
  final String? cancellationReason;

  /// Product and size snapshots priced when the order was placed.
  final List<OrderItem> items;

  /// Total stored as a decimal string to avoid floating-point formatting loss.
  final String totalAmount; // Stored as string to avoid floating-point issues

  /// Payment method selected for the order.
  final String paymentMethod;

  /// Current order lifecycle status.
  final String status;

  /// Ordered history of status changes.
  final List<OrderStatusHistory> statusHistory;

  /// Order creation time.
  final DateTime createdAt;

  /// Most recent update time.
  final DateTime updatedAt;

  /// Optional assigned delivery person.
  final String? deliveryPerson; // Optional: assigned delivery person

  /// `purchase` delivers newly purchased water; `refill` collects containers.
  final String orderType;

  final DateTime? pickupRequestedAt;
  final DateTime? pickupScheduledAt;
  final DateTime? deliveryRequestedAt;
  final DateTime? deliveryScheduledAt;
  final String? containerSize;
  final int? containerCount;

  /// Water type for refill orders; purchase types are stored on each item.
  final String waterType;

  bool get isRefill => orderType == 'refill';

  /// Serializes this order to Firestore-compatible values.
  Map<String, Object?> toMap() => {
    'orderNumber': orderNumber,
    'customerId': customerId,
    'customerName': customerName,
    'phone': phone,
    'address': address,
    'notes': notes,
    if (cancellationReason != null) 'cancellationReason': cancellationReason,
    'orderType': orderType,
    if (isRefill) 'waterType': waterType,
    'pickupRequestedAt': pickupRequestedAt == null
        ? null
        : Timestamp.fromDate(pickupRequestedAt!),
    'pickupScheduledAt': pickupScheduledAt == null
        ? null
        : Timestamp.fromDate(pickupScheduledAt!),
    'deliveryRequestedAt': Timestamp.fromDate(deliveryRequestedAt ?? createdAt),
    'deliveryScheduledAt': deliveryScheduledAt == null
        ? null
        : Timestamp.fromDate(deliveryScheduledAt!),
    if (containerSize != null) 'containerSize': containerSize,
    if (containerCount != null) 'containerCount': containerCount,
    'items': [for (final item in items) item.toJson()],
    'totalAmount': totalAmount == 'Price to be confirmed' ? null : totalAmount,
    'paymentMethod': paymentMethod,
    'status': status,
    'statusHistory': [for (final history in statusHistory) history.toJson()],
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    if (deliveryPerson != null) 'deliveryPerson': deliveryPerson,
  };

  /// Parses an order document and validates its nested items and history.
  ///
  /// Throws [FormatException] when the document contains malformed data.
  factory CustomerOrder.fromMap(String id, Map<String, dynamic> data) {
    final orderNumber = data['orderNumber'];
    final customerId = data['customerId'];
    final customerName = data['customerName'];
    final phone = data['phone'];
    final address = data['address'];
    final notes = data['notes'];
    final cancellationReason = data['cancellationReason'];
    final items = data['items'];
    final totalAmount = data['totalAmount'];
    final paymentMethod = data['paymentMethod'];
    final status = data['status'];
    final statusHistory = data['statusHistory'];
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    final deliveryPerson = data['deliveryPerson'] as String?;
    final orderType = data['orderType'] ?? 'purchase';
    final pickupRequestedAt = data['pickupRequestedAt'];
    final pickupScheduledAt = data['pickupScheduledAt'];
    final deliveryRequestedAt = data['deliveryRequestedAt'];
    final deliveryScheduledAt = data['deliveryScheduledAt'];
    final containerSize = data['containerSize'];
    final containerCount = data['containerCount'];
    final rawWaterType = data['waterType'];

    if (orderNumber is! String ||
        orderNumber.trim().isEmpty ||
        customerId is! String ||
        customerId.trim().isEmpty ||
        customerName is! String ||
        customerName.trim().isEmpty ||
        phone is! String ||
        phone.trim().isEmpty ||
        address is! String ||
        address.trim().isEmpty ||
        notes is! String ||
        (cancellationReason != null &&
            (cancellationReason is! String ||
                cancellationReason.trim().isEmpty)) ||
        items is! List ||
        (totalAmount != null &&
            (totalAmount is! String || totalAmount.trim().isEmpty)) ||
        paymentMethod is! String ||
        paymentMethod.trim().isEmpty ||
        status is! String ||
        status.trim().isEmpty ||
        statusHistory is! List ||
        createdAt is! Timestamp ||
        updatedAt is! Timestamp ||
        (orderType != 'refill' && orderType != 'purchase') ||
        (orderType == 'purchase' && totalAmount == null) ||
        (pickupRequestedAt != null && pickupRequestedAt is! Timestamp) ||
        (pickupScheduledAt != null && pickupScheduledAt is! Timestamp) ||
        (deliveryRequestedAt != null && deliveryRequestedAt is! Timestamp) ||
        (deliveryScheduledAt != null && deliveryScheduledAt is! Timestamp) ||
        (containerSize != null && containerSize is! String) ||
        (rawWaterType != null &&
            (rawWaterType is! String || rawWaterType.trim().isEmpty)) ||
        (containerCount != null &&
            (containerCount is! int || containerCount < 1)) ||
        (orderType == 'refill' &&
            (pickupRequestedAt is! Timestamp ||
                containerSize is! String ||
                containerSize.trim().isEmpty ||
                containerCount is! int ||
                containerCount < 1))) {
      throw FormatException('Invalid order document: $id.');
    }

    final parsedItems = <OrderItem>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        throw FormatException('Invalid item in order document: $id.');
      }
      try {
        parsedItems.add(OrderItem.fromJson(item));
      } on FormatException catch (error) {
        throw FormatException(
          'Invalid item in order document $id: ${error.message}',
        );
      }
    }

    final parsedStatusHistory = <OrderStatusHistory>[];
    for (final history in statusHistory) {
      if (history is! Map<String, dynamic>) {
        throw FormatException('Invalid status history in order document: $id.');
      }
      try {
        parsedStatusHistory.add(OrderStatusHistory.fromJson(history));
      } on FormatException catch (error) {
        throw FormatException(
          'Invalid status history in order document $id: ${error.message}',
        );
      }
    }

    return CustomerOrder(
      id: id,
      orderNumber: orderNumber,
      customerId: customerId,
      customerName: customerName,
      phone: phone,
      address: address,
      notes: notes,
      cancellationReason: cancellationReason as String?,
      items: parsedItems,
      totalAmount: totalAmount is String
          ? totalAmount
          : 'Price to be confirmed',
      paymentMethod: paymentMethod,
      status: status,
      statusHistory: parsedStatusHistory,
      createdAt: createdAt.toDate().toUtc(),
      updatedAt: updatedAt.toDate().toUtc(),
      deliveryPerson: deliveryPerson,
      orderType: orderType as String,
      pickupRequestedAt: (pickupRequestedAt as Timestamp?)?.toDate().toUtc(),
      pickupScheduledAt: (pickupScheduledAt as Timestamp?)?.toDate().toUtc(),
      deliveryRequestedAt:
          (deliveryRequestedAt as Timestamp?)?.toDate().toUtc() ??
          createdAt.toDate().toUtc(),
      deliveryScheduledAt: (deliveryScheduledAt as Timestamp?)
          ?.toDate()
          .toUtc(),
      containerSize: containerSize as String?,
      containerCount: containerCount as int?,
      waterType: orderType == 'refill'
          ? (rawWaterType as String?)?.trim().isNotEmpty == true
                ? (rawWaterType as String).trim()
                : 'Unspecified'
          : 'Unspecified',
    );
  }
}
