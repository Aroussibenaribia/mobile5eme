class ServiceModel {
  final String id;
  final String proId;
  final String title;
  final String description;
  final double price;
  final String duration;
  final bool isActive;
  final int durationMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceModel(
      {this.id = '',
      this.proId = '',
      required this.title,
      required this.description,
      required this.price,
      this.duration = '1h',
      this.isActive = true,
      this.durationMinutes = 60,
      this.createdAt,
      this.updatedAt});

  Map<String, dynamic> toMap() => {
        'id': id,
        'proId': proId,
        'title': title,
        'description': description,
        'price': price,
        'duration': duration,
        'isActive': isActive ? 1 : 0,
        'durationMinutes': durationMinutes,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String()
      };

  factory ServiceModel.fromMap(Map<String, dynamic> map) => ServiceModel(
      id: map['id'] as String? ?? '',
      proId: map['proId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      duration: map['duration'] as String? ?? '1h',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      isActive: map['isActive'] != 0 && map['isActive'] != false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''));
}
