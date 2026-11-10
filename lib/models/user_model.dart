enum UserRole {
  client,
  professional,
  admin;

  String get label {
    switch (this) {
      case UserRole.client:
        return 'Client';
      case UserRole.professional:
        return 'Professionnel';
      case UserRole.admin:
        return 'Administrateur';
    }
  }

  static UserRole fromString(String? role) {
    if (role == 'admin') return UserRole.admin;
    if (role == 'professional' || role == 'pro') {
      return UserRole.professional;
    }
    return UserRole.client;
  }
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final String city;
  final String address;
  final DateTime createdAt;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone = '',
    required this.role,
    this.avatarUrl,
    this.city = 'Tunis',
    this.address = '',
    required this.createdAt,
    this.isActive = true,
  });

  bool get isAdmin => role == UserRole.admin;

  bool get isProfessional => role == UserRole.professional;

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    UserRole? role,
    String? avatarUrl,
    String? city,
    String? address,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role.name,
      'avatarUrl': avatarUrl,
      'city': city,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return UserModel(
      id: docId ?? map['id'] ?? '',
      isActive: map['isActive'] != 0 && map['isActive'] != false,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.fromString(map['role']),
      avatarUrl: map['avatarUrl'],
      city: map['city'] ?? 'Tunis',
      address: map['address'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
