import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'product.dart';
import 'product_repository.dart';

Stream<List<Product>> _logProductStreamErrors(
  Stream<List<Product>> stream,
  String queryName,
) => stream.handleError((Object error, StackTrace stackTrace) {
  debugPrint(
    '$queryName product stream failed: ${_productErrorDetails(error)}'
    '\n$stackTrace',
  );
  Error.throwWithStackTrace(error, stackTrace);
});

String _productErrorDetails(Object error) {
  if (error is FirebaseException) {
    return 'FirebaseException code: ${error.code}, message: ${error.message}';
  }
  return error.toString();
}

Future<T> _logProductFutureErrors<T>(Future<T> future) async {
  try {
    return await future;
  } catch (error, stackTrace) {
    debugPrint(
      'Product request failed: ${_productErrorDetails(error)}\n$stackTrace',
    );
    Error.throwWithStackTrace(error, stackTrace);
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(FirebaseFirestore.instance);
});

final activeProductsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  return _logProductStreamErrors(
    ref.watch(productRepositoryProvider).watchActiveProducts(),
    'Active',
  );
});

final allProductsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  return _logProductStreamErrors(
    ref.watch(productRepositoryProvider).watchAllProducts(),
    'All',
  );
});

final cartProductCheckProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) {
  return _logProductFutureErrors(
    ref.watch(productRepositoryProvider).getActiveProductsFromServer(),
  );
});
