class ReviewModel {
  final String id;
  final String proId;
  final String clientId;
  final String clientName;
  final String? clientAvatarUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? serviceCategory;

  const ReviewModel({
    required this.id,
    required this.proId,
    required this.clientId,
    required this.clientName,
    this.clientAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.serviceCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proId': proId,
      'clientId': clientId,
      'clientName': clientName,
      'clientAvatarUrl': clientAvatarUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'serviceCategory': serviceCategory,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ReviewModel(
      id: docId ?? map['id'] ?? '',
      proId: map['proId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientAvatarUrl: map['clientAvatarUrl'],
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      serviceCategory: map['serviceCategory'],
    );
  }
}
