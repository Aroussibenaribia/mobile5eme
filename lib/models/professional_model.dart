class ProServiceItem {
  final String title;
  final String description;
  final double price;
  final String duration;

  const ProServiceItem({
    required this.title,
    required this.description,
    required this.price,
    this.duration = '1h - 2h',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'duration': duration,
    };
  }

  factory ProServiceItem.fromMap(Map<String, dynamic> map) {
    return ProServiceItem(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      duration: map['duration'] ?? '1h',
    );
  }
}

class ProfessionalModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String coverImageUrl;
  final String specialty;
  final String bio;
  final String city;
  final String address;
  final double hourlyRate;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isAvailable;
  final List<String> skills;
  final List<String> availableDays;
  final List<ProServiceItem> services;

  const ProfessionalModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.coverImageUrl,
    required this.specialty,
    required this.bio,
    this.city = 'Tunis',
    this.address = '',
    required this.hourlyRate,
    this.experienceYears = 5,
    this.rating = 4.8,
    this.reviewCount = 0,
    this.isVerified = true,
    this.isAvailable = true,
    this.skills = const [],
    this.availableDays = const ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'],
    this.services = const [],
  });

  ProfessionalModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? coverImageUrl,
    String? specialty,
    String? bio,
    String? city,
    String? address,
    double? hourlyRate,
    int? experienceYears,
    double? rating,
    int? reviewCount,
    bool? isVerified,
    bool? isAvailable,
    List<String>? skills,
    List<String>? availableDays,
    List<ProServiceItem>? services,
  }) {
    return ProfessionalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      specialty: specialty ?? this.specialty,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      address: address ?? this.address,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      experienceYears: experienceYears ?? this.experienceYears,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      skills: skills ?? this.skills,
      availableDays: availableDays ?? this.availableDays,
      services: services ?? this.services,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'coverImageUrl': coverImageUrl,
      'specialty': specialty,
      'bio': bio,
      'city': city,
      'address': address,
      'hourlyRate': hourlyRate,
      'experienceYears': experienceYears,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'skills': skills,
      'availableDays': availableDays,
      'services': services.map((s) => s.toMap()).toList(),
    };
  }

  factory ProfessionalModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ProfessionalModel(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      coverImageUrl: map['coverImageUrl'] ?? '',
      specialty: map['specialty'] ?? '',
      bio: map['bio'] ?? '',
      city: map['city'] ?? 'Tunis',
      address: map['address'] ?? '',
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 30.0,
      experienceYears: (map['experienceYears'] as num?)?.toInt() ?? 1,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      isVerified: map['isVerified'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      skills: (map['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      availableDays: (map['availableDays'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      services: (map['services'] as List<dynamic>?)
              ?.map((s) => ProServiceItem.fromMap(Map<String, dynamic>.from(s)))
              .toList() ??
          [],
    );
  }
}
