/// Public business details displayed by the information screens.
class BusinessInfo {
  /// Business name shown in the app.
  final String businessName;

  /// Short description of the business.
  final String about;

  /// Public contact phone number.
  final String contactPhone;

  /// Public contact email address.
  final String contactEmail;

  /// Business or pickup location.
  final String address;

  /// Business operating hours.
  final String operatingHours;

  /// Locations or regions covered by delivery.
  final String deliveryCoverage;

  /// Delivery terms shown to customers.
  final String deliveryPolicy;

  /// Ordered steps explaining how to place an order.
  final List<String> orderingGuideSteps;

  /// Creates business information for display or persistence.
  BusinessInfo({
    required this.businessName,
    required this.about,
    required this.contactPhone,
    required this.contactEmail,
    required this.address,
    required this.operatingHours,
    required this.deliveryCoverage,
    required this.deliveryPolicy,
    required this.orderingGuideSteps,
  });

  /// Parses business information from a Firestore map.
  factory BusinessInfo.fromMap(Map<String, dynamic> map) {
    return BusinessInfo(
      businessName: map['businessName'] as String? ?? '',
      about: map['about'] as String? ?? '',
      contactPhone: map['contactPhone'] as String? ?? '',
      contactEmail: map['contactEmail'] as String? ?? '',
      address: map['address'] as String? ?? '',
      operatingHours: map['operatingHours'] as String? ?? '',
      deliveryCoverage: map['deliveryCoverage'] as String? ?? '',
      deliveryPolicy: map['deliveryPolicy'] as String? ?? '',
      orderingGuideSteps: List<String>.from(
        map['orderingGuideSteps'] as List? ?? [],
      ),
    );
  }

  /// Serializes this information to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'about': about,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'address': address,
      'operatingHours': operatingHours,
      'deliveryCoverage': deliveryCoverage,
      'deliveryPolicy': deliveryPolicy,
      'orderingGuideSteps': orderingGuideSteps,
    };
  }

  /// Returns a copy with the provided fields replaced.
  BusinessInfo copyWith({
    String? businessName,
    String? about,
    String? contactPhone,
    String? contactEmail,
    String? address,
    String? operatingHours,
    String? deliveryCoverage,
    String? deliveryPolicy,
    List<String>? orderingGuideSteps,
  }) {
    return BusinessInfo(
      businessName: businessName ?? this.businessName,
      about: about ?? this.about,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      address: address ?? this.address,
      operatingHours: operatingHours ?? this.operatingHours,
      deliveryCoverage: deliveryCoverage ?? this.deliveryCoverage,
      deliveryPolicy: deliveryPolicy ?? this.deliveryPolicy,
      orderingGuideSteps: orderingGuideSteps ?? this.orderingGuideSteps,
    );
  }
}
