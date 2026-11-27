import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refillhub/features/cart/data/cart_item.dart';
import 'package:refillhub/features/cart/data/cart_provider.dart';
import 'package:refillhub/features/cart/data/cart_storage.dart';
import 'package:refillhub/features/products/data/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/auth_test_support.dart';

class _Preferences extends Fake implements SharedPreferencesAsync {
  final data = <String, String>{};

  @override
  Future<String?> getString(String key) async => data[key];

  @override
  Future<void> setString(String key, String value) async {
    data[key] = value;
  }
}

Product _product({num price = 10, String waterType = 'Purified'}) => Product(
  id: 'TEST product',
  name: 'TEST name',
  waterType: waterType,
  description: '',
  isActive: true,
  createdAt: DateTime.utc(2025),
  sizes: [ProductSize(label: 'TEST size', price: price, isAvailable: true)],
);

void main() {
  test('persists cart data across containers and isolates accounts', () async {
    final preferences = _Preferences();
    final storage = SharedPreferencesCartStorage(preferences);
    final first = ProviderContainer(
      overrides: [cartStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(first.dispose);
    await first.read(cartProvider('one').future);
    final product = _product();
    final controller = first.read(cartProvider('one').notifier);
    await Future.wait([
      controller.add(product, product.sizes.single),
      controller.add(product, product.sizes.single),
    ]);
    expect(first.read(cartProvider('one')).requireValue.single.quantity, 2);

    final restarted = ProviderContainer(
      overrides: [
        cartStorageProvider.overrideWithValue(
          SharedPreferencesCartStorage(preferences),
        ),
      ],
    );
    addTearDown(restarted.dispose);
    final items = await restarted.read(cartProvider('one').future);
    expect(items.single.productId, product.id);
    expect(items.single.productName, product.name);
    expect(items.single.waterType, product.waterType);
    expect(items.single.sizeLabel, 'TEST size');
    expect(items.single.unitPrice, 10);
    expect(items.single.quantity, 2);
    expect(cartTotal(items), '20');
    expect(await restarted.read(cartProvider('two').future), isEmpty);
  });

  test('enforces quantity limits, remove, clear and changed prices', () async {
    final storage = MemoryCartStorage();
    final container = ProviderContainer(
      overrides: [cartStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    await container.read(cartProvider('user').future);
    final cart = container.read(cartProvider('user').notifier);
    final product = _product();
    await cart.add(product, product.sizes.single);
    await expectLater(
      cart.changeQuantity(product.id, 'TEST size', -1),
      throwsA(isA<CartException>()),
    );
    await cart.changeQuantity(product.id, 'TEST size', 98);
    expect(
      container.read(cartProvider('user')).requireValue.single.quantity,
      CartItem.maxQuantity,
    );
    await expectLater(
      cart.add(product, product.sizes.single),
      throwsA(isA<CartException>()),
    );
    await expectLater(
      cart.changeQuantity(product.id, 'TEST size', 1),
      throwsA(isA<CartException>()),
    );
    await cart.changeQuantity(product.id, 'TEST size', -1);
    final changed = _product(price: 12);
    await expectLater(
      cart.add(changed, changed.sizes.single),
      throwsA(isA<CartException>()),
    );
    expect(
      container.read(cartProvider('user')).requireValue.single.unitPrice,
      10,
    );
    await cart.remove(product.id, 'TEST size');
    expect(container.read(cartProvider('user')).requireValue, isEmpty);
    await cart.add(changed, changed.sizes.single);
    await cart.clear();
    expect(storage.carts['user'], isEmpty);
  });

  test(
    'failed saves leave state unchanged and later writes can succeed',
    () async {
      final storage = MemoryCartStorage()
        ..saveError = StateError('TEST failure');
      final container = ProviderContainer(
        overrides: [cartStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      await container.read(cartProvider('user').future);
      final product = _product();
      final cart = container.read(cartProvider('user').notifier);
      await expectLater(
        cart.add(product, product.sizes.single),
        throwsStateError,
      );
      expect(container.read(cartProvider('user')).requireValue, isEmpty);
      storage.saveError = null;
      await cart.add(product, product.sizes.single);
      expect(
        container.read(cartProvider('user')).requireValue.single.quantity,
        1,
      );
    },
  );

  test('rejects ambiguous duplicate size labels', () async {
    final storage = MemoryCartStorage();
    final container = ProviderContainer(
      overrides: [cartStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    await container.read(cartProvider('user').future);
    const size = ProductSize(label: 'TEST size', price: 10, isAvailable: true);
    final product = Product(
      id: 'test',
      name: 'TEST product',
      description: '',
      isActive: true,
      createdAt: DateTime.utc(2025),
      sizes: [size, size],
    );
    await expectLater(
      container.read(cartProvider('user').notifier).add(product, size),
      throwsA(isA<CartException>()),
    );
    expect(container.read(cartProvider('user')).requireValue, isEmpty);
  });

  test('invalid stored cart data is reported instead of discarded', () async {
    final preferences = _Preferences();
    final storage = SharedPreferencesCartStorage(preferences);
    await preferences.setString(
      'cart.v1.user',
      '[{"productId":"x","quantity":0}]',
    );
    await expectLater(storage.load('user'), throwsFormatException);
    expect(await preferences.getString('cart.v1.user'), isNotNull);
  });

  test('legacy cart entries default to unspecified water type', () {
    final item = CartItem.fromJson({
      'productId': 'legacy',
      'productName': 'Legacy product',
      'sizeLabel': 'Standard',
      'unitPrice': 10,
      'quantity': 1,
    });
    expect(item.waterType, 'Unspecified');
    expect(item.toJson()['waterType'], 'Unspecified');
  });

  test('total preserves decimal prices without floating-point artifacts', () {
    expect(
      cartTotal([
        const CartItem(
          productId: 'a',
          productName: 'A',
          sizeLabel: 'S',
          unitPrice: 0.1,
          quantity: 3,
        ),
        const CartItem(
          productId: 'b',
          productName: 'B',
          sizeLabel: 'S',
          unitPrice: 0.0000001,
          quantity: 1,
        ),
      ]),
      '0.3000001',
    );
  });
}
