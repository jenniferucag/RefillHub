import 'package:cloud_firestore/cloud_firestore.dart';

import 'business_info.dart';

/// Reads and updates the public business-information document.
class BusinessInfoRepository {
  static const String _docId = 'business_info';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the business-information document or an empty default value.
  Future<BusinessInfo> getBusinessInfo() async {
    try {
      final doc = await _firestore.collection('config').doc(_docId).get();
      if (doc.exists && doc.data() != null) {
        return BusinessInfo.fromMap(doc.data()!);
      }
      return BusinessInfo(
        businessName: '',
        about: '',
        contactPhone: '',
        contactEmail: '',
        address: '',
        operatingHours: '',
        deliveryCoverage: '',
        deliveryPolicy: '',
        orderingGuideSteps: [],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Watches the business-information document, emitting empty defaults if absent.
  Stream<BusinessInfo> watchBusinessInfo() {
    return _firestore.collection('config').doc(_docId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return BusinessInfo.fromMap(doc.data()!);
      }
      return BusinessInfo(
        businessName: '',
        about: '',
        contactPhone: '',
        contactEmail: '',
        address: '',
        operatingHours: '',
        deliveryCoverage: '',
        deliveryPolicy: '',
        orderingGuideSteps: [],
      );
    });
  }

  /// Merges [info] into the business-information document.
  Future<void> updateBusinessInfo(BusinessInfo info) async {
    try {
      await _firestore
          .collection('config')
          .doc(_docId)
          .set(info.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}
