import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'customer.dart';
import 'customer_repository.dart';

/// Provides access to the CustomerRepository
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(FirebaseFirestore.instance);
});

/// Watch all customers in real-time
final watchAllCustomersProvider = StreamProvider<List<Customer>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.watchAllCustomers();
});

/// Get a specific customer
final getCustomerProvider = FutureProvider.autoDispose
    .family<Customer?, String>((ref, customerId) async {
      final repository = ref.watch(customerRepositoryProvider);
      return repository.getCustomer(customerId);
    });

/// Watch a specific customer
final watchCustomerProvider = StreamProvider.autoDispose
    .family<Customer?, String>((ref, customerId) {
      final repository = ref.watch(customerRepositoryProvider);
      return repository.watchCustomer(customerId);
    });

/// Get total customer count
final customerCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getCustomerCount();
});

/// Get order count for a specific customer
final customerOrderCountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, customerId) async {
      final repository = ref.watch(customerRepositoryProvider);
      return repository.getCustomerOrderCount(customerId);
    });
