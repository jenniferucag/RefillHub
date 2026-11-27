import 'package:cloud_firestore/cloud_firestore.dart';

import 'business_info.dart';

class BusinessInfoRepository {
  BusinessInfoRepository(FirebaseFirestore firestore)
    : _document = firestore.collection('business_info').doc('main');

  final DocumentReference<Map<String, dynamic>> _document;

  Stream<BusinessInfo> watch() => _document.snapshots().map((snapshot) {
    return BusinessInfo.fromMap(
      snapshot.data() ?? const <String, dynamic>{},
      exists: snapshot.exists,
    );
  });

  Future<void> save(BusinessInfo info) =>
      _document.set(info.toMap(), SetOptions(merge: true));
}
