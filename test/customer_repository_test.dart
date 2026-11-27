// Firestore's sealed interfaces are implemented here only as test doubles.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/customers/data/customer_repository.dart';

class _Firestore extends Fake implements FirebaseFirestore {
  final users = _Collection();
  final orders = _Collection();
  final paths = <String>[];

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    paths.add(collectionPath);
    return switch (collectionPath) {
      'users' => users,
      'orders' => orders,
      _ => throw StateError('Unexpected collection: $collectionPath'),
    };
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final query = _Query();
  final documents = <String, _Document>{};
  final filters = <Object?>[];

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    filters.addAll([field, isEqualTo]);
    return query;
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      documents.putIfAbsent(path ?? 'new', () => _Document());
}

class _Query extends Fake implements Query<Map<String, dynamic>> {
  final events = StreamController<QuerySnapshot<Map<String, dynamic>>>();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => events.stream;
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class _CustomerDocument extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _CustomerDocument(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final updates = <Map<Object, Object?>>[];

  @override
  Future<void> update(Map<Object, Object?> data) async {
    updates.add(data);
  }
}

void main() {
  test('queries customer users and sorts by fullName in Dart', () async {
    final firestore = _Firestore();
    final repository = CustomerRepository(firestore);
    final names = expectLater(
      repository.watchAllCustomers().map(
        (customers) => customers.map((customer) => customer.name).toList(),
      ),
      emits(['Avery Stone', 'Jordan Rivera']),
    );
    final createdAt = Timestamp.fromDate(DateTime.utc(2025));
    firestore.users.query.events.add(
      _Snapshot([
        _CustomerDocument('jordan', {
          'fullName': 'Jordan Rivera',
          'role': 'customer',
          'createdAt': createdAt,
        }),
        _CustomerDocument('avery', {
          'fullName': 'Avery Stone',
          'role': 'customer',
          'createdAt': createdAt,
        }),
      ]),
    );
    await firestore.users.query.events.close();
    await names;

    expect(firestore.paths.first, 'users');
    expect(firestore.users.filters, ['role', 'customer']);
  });

  test('customer status updates modify only isActive', () async {
    final firestore = _Firestore();
    final repository = CustomerRepository(firestore);

    await repository.toggleCustomerStatus('customer-id', false);

    expect(firestore.paths, ['users', 'orders']);
    expect(firestore.users.documents['customer-id']!.updates.single, {
      'isActive': false,
    });
  });
}
