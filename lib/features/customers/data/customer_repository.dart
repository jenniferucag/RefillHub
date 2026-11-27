import 'package:cloud_firestore/cloud_firestore.dart';

import 'customer.dart';

/// Reads customer profiles and updates their active status in Firestore.
class CustomerRepository {
  /// Creates a repository backed by [firestore].
  CustomerRepository(FirebaseFirestore firestore)
    : _users = firestore.collection('users'),
      _orders = firestore.collection('orders');

  final CollectionReference<Map<String, dynamic>> _users;
  final CollectionReference<Map<String, dynamic>> _orders;

  /// Gets all profiles whose role is `customer`.
  Future<List<Customer>> getAllCustomers() async {
    final snapshot = await _users
        .where('role', isEqualTo: 'customer')
        .get(const GetOptions(source: Source.server));

    return _sortByFullName(_toCustomers(snapshot));
  }

  /// Watches customer profiles in real time.
  Stream<List<Customer>> watchAllCustomers() => _users
      .where('role', isEqualTo: 'customer')
      .snapshots()
      .map(_toCustomers)
      .map(_sortByFullName);

  /// Searches customers by name, phone, or email.
  Future<List<Customer>> searchCustomers(String query) async {
    if (query.trim().isEmpty) {
      return getAllCustomers();
    }

    final allCustomers = await getAllCustomers();
    final lowerQuery = query.toLowerCase();

    return allCustomers
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(lowerQuery) ||
              customer.email.toLowerCase().contains(lowerQuery) ||
              customer.phone.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// Gets [customerId] from the server, or returns `null` if it does not exist.
  Future<Customer?> getCustomer(String customerId) async {
    final snapshot = await _users
        .doc(customerId)
        .get(const GetOptions(source: Source.server));

    if (!snapshot.exists) return null;

    return Customer.fromMap(snapshot.id, snapshot.data()!);
  }

  /// Watches [customerId], emitting `null` if the profile is deleted.
  Stream<Customer?> watchCustomer(String customerId) => _users
      .doc(customerId)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? Customer.fromMap(snapshot.id, snapshot.data()!)
            : null,
      );

  /// Sets a customer's active status.
  Future<void> toggleCustomerStatus(String customerId, bool isActive) async {
    await _users.doc(customerId).update({'isActive': isActive});
  }

  /// Counts orders owned by [customerId] without fetching order documents.
  Future<int> getCustomerOrderCount(String customerId) async {
    final snapshot = await _orders
        .where('customerId', isEqualTo: customerId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Returns the number of profiles with the `customer` role.
  Future<int> getCustomerCount() async {
    final snapshot = await _users
        .where('role', isEqualTo: 'customer')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Convert QuerySnapshot to list of customers
  List<Customer> _toCustomers(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((doc) => Customer.fromMap(doc.id, doc.data())).toList();

  List<Customer> _sortByFullName(List<Customer> customers) =>
      customers..sort((first, second) {
        final byName = first.name.toLowerCase().compareTo(
          second.name.toLowerCase(),
        );
        return byName == 0 ? first.id.compareTo(second.id) : byName;
      });
}
