import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:refillhub/core/router/app_router.dart';
import 'package:refillhub/core/theme/app_theme.dart';
import 'package:refillhub/features/auth/auth_controller.dart';
import 'package:refillhub/features/cart/data/cart_item.dart';
import 'package:refillhub/features/cart/data/cart_provider.dart';
import 'package:refillhub/features/cart/data/cart_storage.dart';
import 'package:refillhub/features/products/data/product.dart';
import 'package:refillhub/features/products/data/product_providers.dart';
import 'package:refillhub/features/products/data/product_repository.dart';
import 'package:refillhub/features/info/data/business_info.dart';
import 'package:refillhub/features/info/data/business_info_providers.dart';

class MemoryCartStorage implements CartStorage {
  final carts = <String, List<CartItem>>{};
  Object? loadError;
  Object? saveError;

  @override
  Future<List<CartItem>> load(String userId) async {
    if (loadError case final error?) throw error;
    return List.of(carts[userId] ?? []);
  }

  @override
  Future<void> save(String userId, List<CartItem> items) async {
    if (saveError case final error?) throw error;
    carts[userId] = List.of(items);
  }
}

class FakeAuthBackend implements AuthBackend {
  FakeAuthBackend({String? role}) {
    if (role != null) {
      currentUserId = 'user';
      profiles['user'] = {'role': role, 'isActive': true};
    }
  }

  @override
  String? currentUserId;
  final profiles = <String, Map<String, dynamic>?>{};
  final _authChanges = StreamController<String?>.broadcast();
  final _profileChanges = StreamController<UserProfile>.broadcast();
  int signOutCount = 0;
  Object? updateError;

  @override
  Stream<String?> get authChanges async* {
    yield currentUserId;
    yield* _authChanges.stream;
  }

  @override
  Stream<UserProfile> watchProfile(String uid) async* {
    yield UserProfile(profiles[uid]);
    yield* _profileChanges.stream;
  }

  @override
  Future<UserProfile> getProfile(String uid) async =>
      UserProfile(profiles[uid]);

  @override
  Future<void> updateProfile(
    String uid, {
    required String name,
    required String phone,
    required String address,
  }) async {
    if (updateError case final error?) throw error;
    if (currentUserId != uid || profiles[uid] == null) {
      throw StateError('The signed-in profile is unavailable.');
    }
    final profile = {
      ...profiles[uid]!,
      'fullName': name,
      'name': name,
      'phone': phone,
      'address': address,
    };
    profiles[uid] = profile;
    _profileChanges.add(UserProfile(profile));
  }

  @override
  Future<String> signIn(String email, String password) async {
    currentUserId = 'user';
    profiles.putIfAbsent('user', () => {'role': 'customer', 'isActive': true});
    _authChanges.add(currentUserId);
    return 'user';
  }

  @override
  Future<String> registerCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    currentUserId = 'user';
    profiles['user'] = {
      'role': 'customer',
      'isActive': true,
      'fullName': name,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
    };
    _authChanges.add(currentUserId);
    return 'user';
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    currentUserId = null;
    _authChanges.add(null);
  }

  void setProfile(Map<String, dynamic>? profile) {
    profiles['user'] = profile;
    _profileChanges.add(UserProfile(profile));
  }

  void emitProfile(UserProfile profile) {
    _profileChanges.add(profile);
  }

  Future<void> dispose() async {
    await _authChanges.close();
    await _profileChanges.close();
  }
}

class TestApp {
  TestApp({
    String? role,
    String initialLocation = '/',
    this.productsStream,
    this.allProductsStream,
    this.productRepository,
    CartStorage? cartStorage,
    this.productCheck,
    this.businessInfoStream,
    this.extraOverrides = const [],
  }) : cartStorage = cartStorage ?? MemoryCartStorage(),
       backend = FakeAuthBackend(role: role) {
    auth = AuthController(backend);
    router = createAppRouter(auth: auth, initialLocation: initialLocation);
    addTearDown(() async {
      router.dispose();
      auth.dispose();
      await backend.dispose();
    });
  }

  final FakeAuthBackend backend;
  final Stream<List<Product>> Function()? productsStream;
  final Stream<List<Product>> Function()? allProductsStream;
  final ProductRepository? productRepository;
  final CartStorage cartStorage;
  final Future<List<Product>> Function()? productCheck;
  final Stream<BusinessInfo> Function()? businessInfoStream;
  final List<Override> extraOverrides;
  late final AuthController auth;
  late final GoRouter router;

  Widget get widget => ProviderScope(
    overrides: [
      activeProductsProvider.overrideWith(
        (ref) => productsStream?.call() ?? Stream.value([]),
      ),
      allProductsProvider.overrideWith(
        (ref) => allProductsStream?.call() ?? Stream.value([]),
      ),
      cartStorageProvider.overrideWithValue(cartStorage),
      cartProductCheckProvider.overrideWith(
        (ref) => productCheck?.call() ?? Future.value([]),
      ),
      businessInfoProvider.overrideWith(
        (ref) =>
            businessInfoStream?.call() ?? Stream.value(const BusinessInfo()),
      ),
      if (productRepository != null)
        productRepositoryProvider.overrideWithValue(productRepository!),
      ...extraOverrides,
    ],
    child: AuthScope(
      controller: auth,
      child: MaterialApp.router(theme: appTheme, routerConfig: router),
    ),
  );
}
