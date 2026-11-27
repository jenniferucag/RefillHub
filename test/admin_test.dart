import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/customers/data/customer_providers.dart';
import 'package:refillhub/features/orders/data/order_providers.dart';

import 'support/auth_test_support.dart';

void main() {
  testWidgets('/admin redirects signed-out users to login', (tester) async {
    final app = TestApp(initialLocation: '/admin');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('admin login rejects customer accounts', (tester) async {
    final app = TestApp(initialLocation: '/admin/login');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('This field is required.'), findsNWidgets(2));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'not-an-email');
    await tester.enterText(fields.at(1), 'short');
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );

    await tester.enterText(fields.at(0), 'demo@example.com');
    await tester.enterText(fields.at(1), 'demo-password');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(
      find.text('This account does not have admin access.'),
      findsOneWidget,
    );
    expect(app.backend.currentUserId, isNull);
    expect(find.text('Operations overview'), findsNothing);
  });

  testWidgets('admin login accepts an active admin', (tester) async {
    final app = TestApp(
      initialLocation: '/admin/login',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith((ref) => Stream.value([])),
        watchAllCustomersProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
    app.backend.profiles['user'] = {'role': 'admin', 'isActive': true};
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'admin@example.com');
    await tester.enterText(fields.at(1), 'demo-password');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Operations overview'), findsOneWidget);
  });

  testWidgets('dashboard includes live order summaries and schedule', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = TestApp(
      role: 'admin',
      initialLocation: '/admin/dashboard',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith((ref) => Stream.value([])),
        watchAllCustomersProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    for (final label in [
      'Total Orders',
      'Pending',
      'In Progress',
      'Delivered',
      'Refill Orders',
      'Purchase Orders',
      'Upcoming schedule',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text("Today's Orders"), findsNWidgets(2));
    expect(find.text('No orders yet.'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('narrow admin navigation uses a drawer with all menu routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = TestApp(
      role: 'admin',
      initialLocation: '/admin/customers',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith((ref) => Stream.value([])),
        watchAllCustomersProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    for (final label in [
      'Dashboard',
      'Products',
      'Customers',
      'Orders',
      'Delivery',
      'Business Info',
    ]) {
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text(label)),
        findsOneWidget,
      );
    }

    await tester.tap(find.text('Delivery'));
    await tester.pumpAndSettle();
    expect(find.text('Delivery Management'), findsOneWidget);
    expect(find.text('No orders to deliver'), findsOneWidget);
  });

  testWidgets('wide admin navigation switches placeholder routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = TestApp(
      role: 'admin',
      initialLocation: '/admin/orders',
      extraOverrides: [
        watchAllOrdersProvider.overrideWith((ref) => Stream.value([])),
        watchAllCustomersProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    for (final label in [
      'Dashboard',
      'Products',
      'Customers',
      'Orders',
      'Delivery',
      'Business Info',
    ]) {
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }

    for (final section in [
      'Dashboard',
      'Products',
      'Customers',
      'Orders',
      'Delivery',
    ]) {
      await tester.tap(find.text(section).first);
      await tester.pumpAndSettle();
      if (section == 'Dashboard') {
        expect(find.text('Operations overview'), findsOneWidget);
      } else if (section == 'Products') {
        expect(find.text('Product Management'), findsOneWidget);
      } else if (section == 'Orders') {
        expect(find.text('No orders yet'), findsOneWidget);
      } else if (section == 'Delivery') {
        expect(find.text('Delivery Management'), findsOneWidget);
        expect(find.text('No orders to deliver'), findsOneWidget);
      } else if (section == 'Customers') {
        expect(find.text('Customer Management'), findsOneWidget);
      } else if (section == 'Business Info') {
        expect(find.text('Business Information'), findsOneWidget);
      } else {
        expect(find.text('$section details not yet provided'), findsOneWidget);
      }
    }
  });
}
