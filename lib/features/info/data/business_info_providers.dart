import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'business_info.dart';
import 'business_info_repository.dart';

String businessInfoErrorMessage(Object error) {
  if (error is FirebaseException) {
    final message = error.message;
    return message == null || message.isEmpty
        ? 'Firebase error (${error.code}).'
        : message;
  }
  return error.toString();
}

final businessInfoRepositoryProvider = Provider<BusinessInfoRepository>((ref) {
  return BusinessInfoRepository(FirebaseFirestore.instance);
});

final businessInfoProvider = StreamProvider.autoDispose<BusinessInfo>((ref) {
  return ref.watch(businessInfoRepositoryProvider).watch().handleError((
    Object error,
    StackTrace stackTrace,
  ) {
    if (error is FirebaseException) {
      debugPrint(
        'Business info stream failed: FirebaseException '
        'code=${error.code}, message=${error.message}\n$stackTrace',
      );
    } else {
      debugPrint('Business info stream failed: $error\n$stackTrace');
    }
    Error.throwWithStackTrace(error, stackTrace);
  });
});
