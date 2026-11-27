import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'business_info.dart';
import 'business_info_repository.dart';

String _businessInfoErrorDetails(Object error) {
  if (error is FirebaseException) {
    return 'FirebaseException code: ${error.code}, message: ${error.message}';
  }
  return error.toString();
}

Stream<T> _logBusinessInfoStreamErrors<T>(Stream<T> stream) =>
    stream.handleError((Object error, StackTrace stackTrace) {
      debugPrint(
        'Business info stream failed (${_businessInfoErrorDetails(error)}): '
        '$stackTrace',
      );
      Error.throwWithStackTrace(error, stackTrace);
    });

Future<T> _logBusinessInfoFutureErrors<T>(Future<T> future) async {
  try {
    return await future;
  } catch (error, stackTrace) {
    debugPrint(
      'Business info request failed '
      '(${_businessInfoErrorDetails(error)}): $stackTrace',
    );
    Error.throwWithStackTrace(error, stackTrace);
  }
}

final businessInfoRepositoryProvider = Provider((ref) {
  return BusinessInfoRepository();
});

final businessInfoProvider = FutureProvider<BusinessInfo>((ref) async {
  final repository = ref.watch(businessInfoRepositoryProvider);
  return _logBusinessInfoFutureErrors(repository.getBusinessInfo());
});

final businessInfoStreamProvider = StreamProvider<BusinessInfo>((ref) {
  final repository = ref.watch(businessInfoRepositoryProvider);
  return _logBusinessInfoStreamErrors(repository.watchBusinessInfo());
});
