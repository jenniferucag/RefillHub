import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/customers/data/customer.dart';
import 'package:refillhub/features/customers/data/customer_providers.dart';
import 'package:refillhub/features/customers/data/customer_repository.dart';

import 'support/auth_test_support.dart';

Customer _customer({
  required String id,
  required String name,
  bool isActive = true,
}) => Customer(
  id: id,
  name: name,
  email: '$id@example.test',
  phone: '09123456789',
  address: '12 Sample Street',
  isActive: isActive,
  createdAt: DateTime.utc(2025),
);

class _Repository extends Fake implements CustomerRepository {
  _Repository(this.customers);

  List<Customer> customers;
  final updates = <MapEntry<String, bool>>[];
  final events = StreamController<List<Customer>>.broadcast();

  @override
  Stream<List<Customer>> watchAllCustomers() async* {
    yield customers;
    yield* events.stream;
  }

  @override
  Future<void> toggleCustomerStatus(String customerId, bool isActive) async {
    updates.add(MapEntry(customerId, isActive));
    customers = [
      for (final customer in customers)
        if (customer.id == customerId)
          Customer(
            id: customer.id,
            name: customer.name,
            email: customer.email,
            phone: customer.phone,
            address: customer.address,
            isActive: isActive,
            createdAt: customer.createdAt,
          )
        else
          customer,
    ];
    events.add(customers);
  }
}

void _useViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _useLargeViewport(WidgetTester tester) =>
    _useViewport(tester, const Size(1200, 1200));

Future<void> _pumpCustomers(
  WidgetTester tester, {
  required _Repository repository,
  Size viewport = const Size(1200, 1200),
}) async {
  _useViewport(tester, viewport);
  addTearDown(repository.events.close);
  final app = TestApp(
    role: 'admin',
    initialLocation: '/admin/customers',
    extraOverrides: [
      customerRepositoryProvider.overrideWithValue(repository),
      customerOrderCountProvider.overrideWith(
        (ref, customerId) => Future.value(
          customerId == 'avery'
              ? 2
              : customerId == 'zero'
              ? 0
              : 1,
        ),
      ),
    ],
  );
  await tester.pumpWidget(app.widget);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('filters customers and details show contact and order count', (
    tester,
  ) async {
    final repository = _Repository([
      _customer(id: 'jordan', name: 'Jordan Rivera'),
      _customer(id: 'avery', name: 'Avery Stone'),
    ]);
    await _pumpCustomers(tester, repository: repository);

    expect(find.text('Avery Stone'), findsOneWidget);
    expect(find.text('Jordan Rivera'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'JORDAN');
    await tester.pumpAndSettle();
    expect(find.text('Jordan Rivera'), findsOneWidget);
    expect(find.text('Avery Stone'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avery Stone'));
    await tester.pumpAndSettle();
    expect(find.text('avery@example.test'), findsNWidgets(2));
    expect(find.text('09123456789'), findsAtLeastNWidgets(2));
    expect(find.text('12 Sample Street'), findsOneWidget);
    expect(find.text('Total orders: 2'), findsOneWidget);
    expect(find.textContaining('password'), findsNothing);
  });

  testWidgets('active toggle updates customer status', (tester) async {
    final repository = _Repository([
      _customer(id: 'avery', name: 'Avery Stone'),
    ]);
    await _pumpCustomers(tester, repository: repository);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deactivate'));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Customer?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Deactivate'));
    await tester.pumpAndSettle();

    expect(repository.updates, hasLength(1));
    expect(repository.updates.single.key, 'avery');
    expect(repository.updates.single.value, isFalse);
    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('customer cards remain readable at phone width', (tester) async {
    const name = 'Jordan Rivera With A Long Customer Name';
    final repository = _Repository([
      _customer(id: 'zero', name: name, isActive: false),
    ]);
    await _pumpCustomers(
      tester,
      repository: repository,
      viewport: const Size(360, 900),
    );

    expect(find.text(name), findsOneWidget);
    final nameText = tester.widget<Text>(find.text(name));
    expect(nameText.maxLines, 1);
    expect(nameText.overflow, TextOverflow.ellipsis);
    expect(find.text('0 orders'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer list shows loading and empty states', (tester) async {
    _useLargeViewport(tester);
    final events = StreamController<List<Customer>>();
    addTearDown(events.close);
    final app = TestApp(
      role: 'admin',
      initialLocation: '/admin/customers',
      extraOverrides: [
        watchAllCustomersProvider.overrideWith((ref) => events.stream),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    events.add([]);
    await tester.pumpAndSettle();
    expect(find.text('No customers found'), findsOneWidget);
  });

  testWidgets('customer errors show the Firebase message and retry', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final app = TestApp(
      role: 'admin',
      initialLocation: '/admin/customers',
      extraOverrides: [
        watchAllCustomersProvider.overrideWith(
          (ref) => Stream.error(
            FirebaseException(
              plugin: 'cloud_firestore',
              message: 'Customer read failed',
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    expect(find.textContaining('Customer read failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
