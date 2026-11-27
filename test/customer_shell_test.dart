import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/products/data/product.dart';
import 'package:refillhub/features/orders/data/order_providers.dart';
import 'package:refillhub/features/info/data/business_info.dart';
import 'support/auth_test_support.dart';

Product _homeProduct({
  required String id,
  required String name,
  List<ProductSize> sizes = const [
    ProductSize(label: 'Small', price: 25, isAvailable: true),
  ],
}) => Product(
  id: id,
  name: name,
  waterType: 'Purified',
  description: 'Drinking water',
  isActive: true,
  createdAt: DateTime.utc(2025),
  sizes: sizes,
);

void _useLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('customer tabs show their placeholder destinations', (
    tester,
  ) async {
    final app = TestApp(
      role: 'customer',
      initialLocation: '/home',
      extraOverrides: [
        customerOrdersProvider.overrideWith(
          (ref, customerId) => Stream.value([]),
        ),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Products', 'My Orders', 'Profile']) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    expect(find.text('No products available yet'), findsOneWidget);
    expect(find.text('Search products'), findsOneWidget);

    await tester.tap(find.text('My Orders'));
    await tester.pumpAndSettle();
    expect(find.text('You have no orders yet'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);
  });

  testWidgets('home hides empty available water and info links navigate back', (
    tester,
  ) async {
    final app = TestApp(role: 'customer', initialLocation: '/home');
    app.backend.profiles['user'] = {
      'role': 'customer',
      'isActive': true,
      'name': 'Legacy profile name',
    };
    final router = app.router;
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Hello there'), findsNothing);
    expect(find.text('Refill my container'), findsWidgets);
    expect(find.text('Buy water'), findsWidgets);
    expect(find.text('Available water'), findsNothing);
    expect(find.textContaining('Sample product'), findsNothing);

    await tester.tap(find.text('Buy water').first);
    await tester.pumpAndSettle();
    expect(find.text('No products available yet'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('View pricing and other information.'), findsOneWidget);
    for (final title in [
      'Pricing',
      'How to Order',
      'Delivery Information',
      'About/Contact',
    ]) {
      await tester.ensureVisible(find.text(title));
      expect(find.text(title), findsOneWidget);
    }

    await tester.ensureVisible(find.text('Pricing'));
    await tester.tap(find.text('Pricing'));
    await tester.pumpAndSettle();
    expect(find.text('No prices available yet'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    await tester.drag(find.byType(ListView).first, const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.text('Refill my container'), findsWidgets);
  });

  testWidgets(
    'home shows live products, lowest available price, and name updates',
    (tester) async {
      _useLargeViewport(tester);
      final app = TestApp(
        role: 'customer',
        initialLocation: '/home',
        productsStream: () => Stream.value([
          _homeProduct(
            id: 'product-1',
            name: 'TEST Water One',
            sizes: const [
              ProductSize(label: 'Unavailable', price: 5, isAvailable: false),
              ProductSize(label: 'Large', price: 20, isAvailable: true),
              ProductSize(label: 'Small', price: 12, isAvailable: true),
            ],
          ),
          for (var index = 2; index <= 5; index++)
            _homeProduct(id: 'product-$index', name: 'TEST Water $index'),
        ]),
      );
      app.backend.profiles['user'] = {
        'role': 'customer',
        'isActive': true,
        'fullName': 'Jordan Rivera',
        'name': 'Legacy name',
      };

      await tester.pumpWidget(app.widget);
      await tester.pumpAndSettle();

      expect(find.text('Hello, Jordan Rivera'), findsOneWidget);
      expect(find.text('Available water'), findsOneWidget);
      expect(find.text('TEST Water One'), findsOneWidget);
      expect(find.text('Lowest size: ₱12'), findsOneWidget);
      expect(find.text('TEST Water 5'), findsNothing);

      app.backend.setProfile({
        'role': 'customer',
        'isActive': true,
        'fullName': 'Jordan Updated',
        'name': 'Legacy name',
      });
      await tester.pumpAndSettle();
      expect(find.text('Hello, Jordan Updated'), findsOneWidget);

      await tester.tap(find.text('TEST Water One'));
      await tester.pumpAndSettle();
      expect(find.text('Product details'), findsOneWidget);
      expect(find.text('Water type: Purified'), findsOneWidget);
    },
  );

  testWidgets('home shows catalog loading and hides the section when empty', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final events = StreamController<List<Product>>();
    addTearDown(events.close);
    final app = TestApp(
      role: 'customer',
      initialLocation: '/home',
      productsStream: () => events.stream,
    );
    await tester.pumpWidget(app.widget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Available water'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    events.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Available water'), findsNothing);
  });

  testWidgets('home displays the real product stream error and retry action', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final app = TestApp(
      role: 'customer',
      initialLocation: '/home',
      productsStream: () => Stream.error(StateError('catalog unavailable')),
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Bad state: catalog unavailable'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('information routes display saved business information', (
    tester,
  ) async {
    final info = BusinessInfo(
      businessName: 'TEST Business',
      about: 'TEST about',
      contactPhone: '',
      contactEmail: '',
      address: 'TEST address',
      operatingHours: 'TEST hours',
      deliveryCoverage: 'TEST coverage',
      deliveryPolicy: 'TEST policy',
      scheduleNotes: 'TEST schedule notes',
      orderingGuideSteps: const ['TEST order step'],
      exists: true,
    );
    final app = TestApp(
      role: 'customer',
      initialLocation: '/home',
      businessInfoStream: () => Stream.value(info),
      extraOverrides: [
        customerOrdersProvider.overrideWith(
          (ref, customerId) => Stream.value([]),
        ),
      ],
    );
    final router = app.router;
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    const infoRoutes = {
      '/info/how-to-order': 'How to Order',
      '/info/delivery-information': 'Delivery Information',
      '/info/about-contact': 'About/Contact',
    };

    for (final entry in infoRoutes.entries) {
      router.push(entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      if (entry.key == '/info/how-to-order') {
        expect(find.text('TEST order step'), findsOneWidget);
      } else if (entry.key == '/info/delivery-information') {
        expect(find.text('TEST coverage'), findsOneWidget);
        expect(find.text('TEST policy'), findsOneWidget);
        expect(find.text('TEST hours'), findsOneWidget);
        expect(find.text('TEST schedule notes'), findsOneWidget);
      } else {
        expect(find.text('TEST Business'), findsOneWidget);
        expect(find.text('TEST about'), findsOneWidget);
        expect(find.text('TEST address'), findsOneWidget);
        await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
        await tester.pumpAndSettle();
        expect(find.text('Not yet provided by RefillHub'), findsNWidgets(2));
        expect(find.text('Call'), findsNothing);
        expect(find.text('Email'), findsNothing);
      }
      router.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('How to Order uses default steps and starts ordering', (
    tester,
  ) async {
    final app = TestApp(role: 'customer', initialLocation: '/home');
    final router = app.router;
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    router.push('/info/how-to-order');
    await tester.pumpAndSettle();

    expect(
      find.text('Choose "Refill my container" or "Buy water".'),
      findsOneWidget,
    );
    expect(
      find.textContaining('the station will confirm your schedule'),
      findsOneWidget,
    );
    expect(
      find.text('Track your order status under My Orders.'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start ordering'));
    await tester.tap(find.text('Start ordering'));
    await tester.pumpAndSettle();
    expect(find.text('Refill my container'), findsWidgets);
  });

  testWidgets('information screen displays real stream errors and retries', (
    tester,
  ) async {
    var subscriptions = 0;
    final events = StreamController<BusinessInfo>.broadcast();
    addTearDown(events.close);
    final streamError = StateError('business info unavailable');
    final app = TestApp(
      role: 'customer',
      initialLocation: '/home',
      businessInfoStream: () {
        subscriptions++;
        return events.stream;
      },
    );
    final router = app.router;
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    router.push('/info/delivery-information');
    for (var index = 0; index < 5 && !events.hasListener; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(events.hasListener, isTrue);
    events.addError(streamError);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.textContaining('Bad state: business info unavailable'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    final previousSubscriptions = subscriptions;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(subscriptions, greaterThan(previousSubscriptions));
  });

  testWidgets('products search value survives switching tabs', (tester) async {
    final app = TestApp(
      role: 'customer',
      initialLocation: '/home',
      extraOverrides: [
        customerOrdersProvider.overrideWith(
          (ref, customerId) => Stream.value([]),
        ),
      ],
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    final searchField = find.byKey(const ValueKey('products-search'));
    await tester.enterText(searchField, 'sample query');

    await tester.tap(find.text('My Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'sample query',
    );
  });
}
