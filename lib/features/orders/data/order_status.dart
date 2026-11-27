import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  pickedUp('Picked Up'),
  preparing('Preparing'),
  outForDelivery('Out for Delivery'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.label);
  final String label;
}

List<OrderStatus> orderStatusPath({required bool isRefill}) => [
  OrderStatus.pending,
  OrderStatus.confirmed,
  if (isRefill) OrderStatus.pickedUp,
  OrderStatus.preparing,
  OrderStatus.outForDelivery,
  OrderStatus.delivered,
];

bool canTransitionOrderStatus({
  required String orderType,
  required String current,
  required String next,
}) {
  if (next == OrderStatus.cancelled.label &&
      current != OrderStatus.preparing.label &&
      current != OrderStatus.outForDelivery.label &&
      current != OrderStatus.delivered.label &&
      current != OrderStatus.cancelled.label) {
    return true;
  }
  final path = orderStatusPath(isRefill: orderType == 'refill');
  final index = path.indexWhere((status) => status.label == current);
  return index >= 0 && index < path.length - 1 && path[index + 1].label == next;
}

/// One status-change event in an order's lifecycle history.
class OrderStatusHistory {
  /// Creates a status event with its timestamp and actor.
  const OrderStatusHistory({
    required this.status,
    required this.timestamp,
    required this.changedBy,
  });

  /// Status value after the event.
  final String status;

  /// Time the status was changed.
  final DateTime timestamp;

  /// UID of the actor, or `system` for the initial event.
  final String changedBy; // e.g., 'system', 'admin', or user ID

  /// Serializes this event to a Firestore-compatible map.
  Map<String, Object> toJson() => {
    'status': status,
    'timestamp': Timestamp.fromDate(timestamp),
    'changedBy': changedBy,
  };

  /// Parses and validates a status-history map.
  ///
  /// Throws [FormatException] when a required value is missing or malformed.
  factory OrderStatusHistory.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid order status history.');
    }

    final status = value['status'];
    final timestamp = value['timestamp'];
    final changedBy = value['changedBy'];

    if (status is! String ||
        status.trim().isEmpty ||
        timestamp is! Timestamp ||
        changedBy is! String ||
        changedBy.trim().isEmpty) {
      throw const FormatException('Invalid order status history.');
    }

    return OrderStatusHistory(
      status: status,
      timestamp: timestamp.toDate().toUtc(),
      changedBy: changedBy,
    );
  }
}
