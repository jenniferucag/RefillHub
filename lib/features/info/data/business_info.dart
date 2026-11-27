class BusinessInfo {
  const BusinessInfo({
    this.businessName = '',
    this.about = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.address = '',
    this.operatingHours = '',
    this.deliveryCoverage = '',
    this.deliveryPolicy = '',
    this.scheduleNotes = '',
    this.orderingGuideSteps = const [],
    this.exists = false,
  });

  factory BusinessInfo.fromMap(
    Map<String, dynamic> data, {
    bool exists = true,
  }) {
    final steps = data['orderingGuideSteps'];
    return BusinessInfo(
      businessName: _stringValue(data['businessName']),
      about: _stringValue(data['about']),
      contactPhone: _stringValue(data['contactPhone']),
      contactEmail: _stringValue(data['contactEmail']),
      address: _stringValue(data['address']),
      operatingHours: _stringValue(data['operatingHours']),
      deliveryCoverage: _stringValue(data['deliveryCoverage']),
      deliveryPolicy: _stringValue(data['deliveryPolicy']),
      scheduleNotes: _stringValue(data['scheduleNotes']),
      orderingGuideSteps: steps is List
          ? steps.whereType<String>().toList(growable: false)
          : const [],
      exists: exists,
    );
  }

  final String businessName;
  final String about;
  final String contactPhone;
  final String contactEmail;
  final String address;
  final String operatingHours;
  final String deliveryCoverage;
  final String deliveryPolicy;
  final String scheduleNotes;
  final List<String> orderingGuideSteps;
  final bool exists;

  Map<String, dynamic> toMap() => {
    'businessName': businessName,
    'about': about,
    'contactPhone': contactPhone,
    'contactEmail': contactEmail,
    'address': address,
    'operatingHours': operatingHours,
    'deliveryCoverage': deliveryCoverage,
    'deliveryPolicy': deliveryPolicy,
    'scheduleNotes': scheduleNotes,
    'orderingGuideSteps': orderingGuideSteps,
  };

  static String _stringValue(Object? value) => value is String ? value : '';
}
