import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../checkout/data/checkout.dart';
import 'order.dart';
import 'order_repository.dart';

String _orderErrorDetails(Object error) {
  if (error is FirebaseException) {
    return 'FirebaseException code: ${error.code}, message: ${error.message}';
  }
  return error.toString();
}

Stream<T> _logOrderStreamErrors<T>(Stream<T> stream, String queryName) =>
    stream.handleError((Object error, StackTrace stackTrace) {
      debugPrint(
        '$queryName order stream failed (${_orderErrorDetails(error)}): '
        '$stackTrace',
      );
      Error.throwWithStackTrace(error, stackTrace);
    });

Future<T> _logOrderFutureErrors<T>(Future<T> future, String queryName) async {
  try {
    return await future;
  } catch (error, stackTrace) {
    debugPrint(
      '$queryName order request failed (${_orderErrorDetails(error)}): '
      '$stackTrace',
    );
    Error.throwWithStackTrace(error, stackTrace);
  }
}

/// Provides access to the OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(FirebaseFirestore.instance);
});

/// Implements the placeOrderProvider from checkout.dart
/// This is the actual implementation that was left unimplemented before
/// Usage: Inject this into the checkout screen via ref.read()
final placeOrderProvider = Provider<PlaceOrder>((ref) {
  return (request) async {
    final repository = ref.read(orderRepositoryProvider);
    await repository.placeOrder(request);
  };
});

/// Watch a specific order
final watchOrderProvider = StreamProvider.autoDispose
    .family<CustomerOrder?, String>((ref, orderId) {
      final repository = ref.watch(orderRepositoryProvider);
      return _logOrderStreamErrors(repository.watchOrder(orderId), 'Single');
    });

/// Watch all orders for a specific customer
final customerOrdersProvider = StreamProvider.autoDispose
    .family<List<CustomerOrder>, String>((ref, customerId) {
      final repository = ref.watch(orderRepositoryProvider);
      return _logOrderStreamErrors(
        repository.watchCustomerOrders(customerId),
        'Customer',
      );
    });

/// Get a specific order
final getOrderProvider = FutureProvider.autoDispose
    .family<CustomerOrder?, String>((ref, orderId) async {
      final repository = ref.watch(orderRepositoryProvider);
      return _logOrderFutureErrors(repository.getOrder(orderId), 'Single');
    });

/// Get all orders for a specific customer (server source)
final getCustomerOrdersProvider = FutureProvider.autoDispose
    .family<List<CustomerOrder>, String>((ref, customerId) async {
      final repository = ref.watch(orderRepositoryProvider);
      return _logOrderFutureErrors(
        repository.getCustomerOrders(customerId),
        'Customer',
      );
    });

/// Get all orders (admin view, server source)
final getAllOrdersProvider = FutureProvider<List<CustomerOrder>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return _logOrderFutureErrors(repository.getAllOrders(), 'All');
});

/// Watch all orders in real-time (admin view)
final watchAllOrdersProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return _logOrderStreamErrors(repository.watchAllOrders(), 'All');
});

// ============================================================================
// Dashboard Statistics Providers
// ============================================================================

/// Get total count of all orders
final totalOrdersCountProvider = FutureProvider<int>((ref) async {
  final orders = await ref.watch(getAllOrdersProvider.future);
  return orders.length;
});

/// Get count of pending orders
final pendingOrdersCountProvider = FutureProvider<int>((ref) async {
  final orders = await ref.watch(getAllOrdersProvider.future);
  return orders.where((o) => o.status == 'Pending').length;
});

/// Get count of in-progress orders (Confirmed + Preparing + Out for Delivery)
final inProgressOrdersCountProvider = FutureProvider<int>((ref) async {
  final orders = await ref.watch(getAllOrdersProvider.future);
  return orders.where((o) {
    return o.status == 'Confirmed' ||
        o.status == 'Preparing' ||
        o.status == 'Out for Delivery';
  }).length;
});

/// Get count of delivered orders
final deliveredOrdersCountProvider = FutureProvider<int>((ref) async {
  final orders = await ref.watch(getAllOrdersProvider.future);
  return orders.where((o) => o.status == 'Delivered').length;
});

/// Get today's orders list
final todayOrdersListProvider = FutureProvider<List<CustomerOrder>>((
  ref,
) async {
  final orders = await ref.watch(getAllOrdersProvider.future);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return orders.where((o) {
    return o.createdAt.isAfter(startOfDay) && o.createdAt.isBefore(endOfDay);
  }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Get count of today's orders
final todayOrdersCountProvider = FutureProvider<int>((ref) async {
  final todayOrders = await ref.watch(todayOrdersListProvider.future);
  return todayOrders.length;
});
