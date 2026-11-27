import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../products/data/product.dart';
import 'cart_item.dart';
import 'cart_storage.dart';

final cartStorageProvider = Provider<CartStorage>(
  (ref) => SharedPreferencesCartStorage(SharedPreferencesAsync()),
);

final cartProvider =
    AsyncNotifierProvider.family<CartController, List<CartItem>, String>(
      CartController.new,
    );

class CartException implements Exception {
  const CartException(this.message);
  final String message;
}

class CartController extends AsyncNotifier<List<CartItem>> {
  CartController(this.userId);

  final String userId;
  Future<void> _tail = Future.value();

  @override
  Future<List<CartItem>> build() async =>
      List.unmodifiable(await ref.watch(cartStorageProvider).load(userId));

  Future<void> _change(List<CartItem> Function(List<CartItem>) change) {
    final operation = _tail.then((_) async {
      final current = await future;
      final next = List<CartItem>.unmodifiable(change(current));
      await ref.read(cartStorageProvider).save(userId, next);
      state = AsyncData(next);
    });
    // Keep later operations usable after a failed write; the caller receives the error.
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  Future<void> add(Product product, ProductSize size) => _change((items) {
    final matches = product.sizes
        .where((entry) => entry.label == size.label)
        .toList();
    if (!product.isActive ||
        product.id.isEmpty ||
        product.name.trim().isEmpty ||
        !size.isAvailable ||
        size.label.trim().isEmpty ||
        product.waterType.trim().isEmpty ||
        !size.price.isFinite ||
        size.price <= 0 ||
        matches.length != 1 ||
        !matches.single.isAvailable ||
        matches.single.price != size.price) {
      throw const CartException('This size cannot be added to the cart.');
    }
    final index = items.indexWhere(
      (item) => item.productId == product.id && item.sizeLabel == size.label,
    );
    if (index < 0) {
      return [
        ...items,
        CartItem(
          productId: product.id,
          productName: product.name,
          sizeLabel: size.label,
          unitPrice: size.price,
          quantity: 1,
          waterType: product.waterType,
        ),
      ];
    }
    final existing = items[index];
    if (existing.unitPrice != size.price ||
        existing.waterType != product.waterType) {
      throw const CartException(
        'The product details have changed. Remove this item from your cart before adding it again.',
      );
    }
    if (existing.quantity >= CartItem.maxQuantity) {
      throw const CartException('Maximum quantity is 99 per size.');
    }
    return [
      for (var i = 0; i < items.length; i++)
        if (i == index)
          existing.withQuantity(existing.quantity + 1)
        else
          items[i],
    ];
  });

  Future<void> changeQuantity(String productId, String sizeLabel, int delta) =>
      _change((items) {
        final index = items.indexWhere(
          (item) => item.productId == productId && item.sizeLabel == sizeLabel,
        );
        if (index < 0) {
          throw const CartException('This cart item no longer exists.');
        }
        final quantity = items[index].quantity + delta;
        if (quantity < 1 || quantity > CartItem.maxQuantity) {
          throw const CartException('Quantity must be between 1 and 99.');
        }
        return [
          for (var i = 0; i < items.length; i++)
            if (i == index) items[i].withQuantity(quantity) else items[i],
        ];
      });

  Future<void> remove(String productId, String sizeLabel) => _change(
    (items) => items
        .where(
          (item) => item.productId != productId || item.sizeLabel != sizeLabel,
        )
        .toList(),
  );

  Future<void> clear() => _change((items) => []);
}
