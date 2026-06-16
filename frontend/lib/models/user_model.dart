class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String role;
  final DateTime createdAt;
  final String? shopName;
  final String? pincode;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    this.role = 'Customer',
    required this.createdAt,
    this.shopName,
    this.pincode,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'shopName': shopName,
      'pincode': pincode,
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      role: map['role'] ?? 'Customer',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      shopName: map['shopName'],
      pincode: map['pincode'],
    );
  }
}
