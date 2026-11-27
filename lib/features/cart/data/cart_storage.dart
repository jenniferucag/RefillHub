import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cart_item.dart';

/// Persistence contract for a user's locally stored cart.
abstract interface class CartStorage {
  /// Loads a user's cart, returning an empty list when no cart is saved.
  Future<List<CartItem>> load(String userId);

  /// Persists [items] for [userId].
  Future<void> save(String userId, List<CartItem> items);
}

/// Stores carts as JSON in asynchronous shared preferences.
class SharedPreferencesCartStorage implements CartStorage {
  /// Creates a storage adapter backed by [preferences].
  SharedPreferencesCartStorage(this.preferences);

  final SharedPreferencesAsync preferences;

  String _key(String userId) => 'cart.v1.$userId';

  @override
  Future<List<CartItem>> load(String userId) async {
    final stored = await preferences.getString(_key(userId));
    if (stored == null) return [];
    final decoded = jsonDecode(stored);
    if (decoded is! List) throw const FormatException('Invalid saved cart.');
    final items = decoded.map(CartItem.fromJson).toList();
    final keys = <(String, String)>{};
    for (final item in items) {
      if (!keys.add((item.productId, item.sizeLabel))) {
        throw const FormatException('Duplicate saved cart item.');
      }
    }
    return items;
  }

  @override
  Future<void> save(String userId, List<CartItem> items) =>
      preferences.setString(
        _key(userId),
        jsonEncode(items.map((item) => item.toJson()).toList()),
      );
}
