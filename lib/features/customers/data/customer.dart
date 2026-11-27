/// Represents a customer user profile
class Customer {
  /// Creates a customer profile snapshot.
  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.isActive,
    required this.createdAt,
  });

  /// Firebase Authentication UID and Firestore document ID.
  final String id;

  /// Customer's display name.
  final String name;

  /// Customer's email address.
  final String email;

  /// Customer's contact phone number.
  final String phone;

  /// Customer's delivery address.
  final String address;

  /// Whether the account is enabled by an administrator.
  final bool isActive;

  /// Profile creation time.
  final DateTime createdAt;

  /// Builds a profile from a Firestore user document.
  factory Customer.fromMap(String id, Map<String, dynamic> data) {
    return Customer(
      id: id,
      name: data['fullName'] as String? ?? data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Serializes this profile's fields for Firestore.
  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'isActive': isActive,
    'createdAt': createdAt,
  };
}
