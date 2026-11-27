import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/core/router/app_router.dart';
import 'package:refillhub/features/auth/auth_controller.dart';
import 'package:refillhub/features/products/data/product.dart';
import 'package:refillhub/features/products/data/product_repository.dart';

import 'support/auth_test_support.dart';

Product _product({
  String id = 'one',
  String name = 'TEST product',
  String waterType = 'Purified',
  bool active = true,
  List<ProductSize> sizes = const [
    ProductSize(label: 'TEST small', price: 10, isAvailable: true),
  ],
}) => Product(
  id: id,
  name: name,
  waterType: waterType,
  description: 'TEST description',
  isActive: active,
  createdAt: DateTime.utc(2025),
  sizes: sizes,
);

class _Repository extends Fake implements ProductRepository {
  _Repository(this.products);
  List<Product> products;
  final events = StreamController<List<Product>>.broadcast();
  Object? failure;
  int writes = 0;

  @override
  Stream<List<Product>> watchAllProducts() async* {
    yield products;
    yield* events.stream;
  }

  void _notify() => events.add(products);
  void _checkFailure() {
    if (failure case final error?) throw error;
    writes++;
  }

  @override
  Future<void> createProduct({
    required String name,
    required String waterType,
    required String description,
    required String? imageBase64,
    required List<ProductSize> sizes,
  }) async {
    _checkFailure();
    products = [
      ...products,
      _product(
        id: 'new',
        name: name,
        waterType: waterType,
        active: false,
        sizes: sizes,
      ),
    ];
    _notify();
  }

  @override
  Future<void> updateProduct(
    String id, {
    required String name,
    required String waterType,
    required String description,
    required String? imageBase64,
    required bool removeImage,
    required List<ProductSize> sizes,
  }) async {
    _checkFailure();
    products = [
      for (final product in products)
        if (product.id == id)
          _product(
            id: id,
            name: name,
            waterType: waterType,
            active: product.isActive,
            sizes: sizes,
          )
        else
          product,
    ];
    _notify();
  }

  @override
  Future<void> setActive(String id, bool isActive) async {
    _checkFailure();
    products = [
      for (final product in products)
        if (product.id == id)
          _product(
            id: id,
            name: product.name,
            waterType: product.waterType,
            active: isActive,
            sizes: product.sizes,
          )
        else
          product,
    ];
    _notify();
  }
}

Future<void> _pumpAdmin(WidgetTester tester, _Repository repository) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(repository.events.close);
  final app = TestApp(
    role: 'admin',
    initialLocation: '/admin/products',
    allProductsStream: repository.watchAllProducts,
    productRepository: repository,
  );
  await tester.pumpWidget(app.widget);
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('shows product stream errors and retries loading', (
    tester,
  ) async {
    final repository = _Repository([_product()]);
    await _pumpAdmin(tester, repository);

    repository.events.addError(
      StateError('TEST product stream failure'),
      StackTrace.current,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('TEST product stream failure'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('TEST product'), findsOneWidget);
  });

  testWidgets(
    'searches all products and confirms deactivation without deleting',
    (tester) async {
      final repository = _Repository([
        _product(),
        _product(id: 'two', name: 'TEST inactive', active: false),
      ]);
      await _pumpAdmin(tester, repository);
      expect(find.text('TEST product'), findsOneWidget);
      expect(find.text('TEST inactive'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('admin-products-search')),
        'INACTIVE',
      );
      await tester.pumpAndSettle();
      expect(find.text('TEST product'), findsNothing);
      expect(find.text('TEST inactive'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('admin-products-search')),
        '',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();
      expect(find.text('Deactivate product?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.writes, 0);
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();
      expect(repository.products, hasLength(2));
      expect(repository.products.first.isActive, isFalse);
      expect(find.text('TEST product'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();
      expect(repository.products.first.isActive, isTrue);
    },
  );

  testWidgets('shows and edits legacy products with unspecified water type', (
    tester,
  ) async {
    final repository = _Repository([
      _product(id: 'legacy', name: 'TEST legacy', waterType: 'Unspecified'),
      _product(id: 'typed', name: 'TEST typed', waterType: 'Purified'),
    ]);
    await _pumpAdmin(tester, repository);

    expect(find.text('Water type: Unspecified'), findsOneWidget);
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.text('Purified').last);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Save product'));

    expect(repository.products.first.waterType, 'Purified');
  });

  testWidgets('creates an inactive product after validating name and sizes', (
    tester,
  ) async {
    final repository = _Repository([]);
    await _pumpAdmin(tester, repository);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add product'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Add size'));
    await _tapVisible(tester, find.text('Save product'));
    expect(find.text('This field is required.'), findsNWidgets(2));
    expect(find.text('Choose a water type.'), findsOneWidget);
    expect(find.text('Enter a price greater than 0.'), findsOneWidget);

    await tester.enterText(_field('Product name'), 'TEST new');
    await tester.enterText(_field('Size label'), 'TEST size');
    await tester.enterText(_field('Price'), '0');
    await _tapVisible(tester, find.text('Save product'));
    expect(find.text('Enter a price greater than 0.'), findsOneWidget);
    expect(repository.writes, 0);
    await tester.enterText(_field('Price'), '12.5');
    await tester.enterText(_field('Refill price (optional)'), '0');
    await _tapVisible(tester, find.text('Save product'));
    expect(find.text('Enter a price greater than 0.'), findsOneWidget);
    expect(repository.writes, 0);
    await tester.enterText(_field('Refill price (optional)'), '4.5');
    await _tapVisible(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.text('Add new type').last);
    await tester.pumpAndSettle();
    await tester.enterText(_field('New water type'), 'Purified');
    await _tapVisible(tester, find.text('Save product'));
    expect(repository.products.single.name, 'TEST new');
    expect(repository.products.single.waterType, 'Purified');
    expect(repository.products.single.isActive, isFalse);
    expect(repository.products.single.sizes.single.price, 12.5);
    expect(repository.products.single.sizes.single.refillPrice, 4.5);
    expect(find.text('TEST new'), findsOneWidget);
  });

  testWidgets('edits purchase and refill prices and reports save errors', (
    tester,
  ) async {
    final repository = _Repository([
      _product(
        sizes: const [
          ProductSize(
            label: 'TEST small',
            price: 10,
            refillPrice: 3,
            isAvailable: true,
          ),
        ],
      ),
    ]);
    await _pumpAdmin(tester, repository);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Size label'), 'TEST large');
    await tester.enterText(_field('Price'), '25');
    await tester.enterText(_field('Refill price (optional)'), '6');
    await _tapVisible(tester, find.widgetWithText(SwitchListTile, 'Available'));
    await _tapVisible(tester, find.text('Add size'));
    await tester.enterText(_field('Size label').last, 'TEST extra');
    await tester.enterText(_field('Price').last, '15');
    repository.failure = StateError('TEST failure');
    await _tapVisible(tester, find.text('Save product'));
    expect(
      find.text('Could not save product. Please try again.'),
      findsOneWidget,
    );
    expect(repository.products.single.sizes.single.label, 'TEST small');
    repository.failure = null;
    await _tapVisible(tester, find.text('Save product'));
    final size = repository.products.single.sizes.first;
    expect(size.label, 'TEST large');
    expect(size.price, 25);
    expect(size.refillPrice, 6);
    expect(size.isAvailable, isFalse);
    expect(repository.products.single.sizes.last.label, 'TEST extra');
    expect(repository.products.single.sizes.last.price, 15);
    expect(repository.products.single.sizes.last.refillPrice, isNull);
  });

  test('customer cannot access product management', () {
    expect(
      authRedirect(AuthStatus.customer, Uri.parse('/admin/products')),
      '/home',
    );
  });
}
