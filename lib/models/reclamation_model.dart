enum ReclamationStatus {
  pending,
  inReview,
  resolved,
  rejected;

  String get label => switch (this) {
        pending => 'En attente',
        inReview => 'En cours d’analyse',
        resolved => 'Résolue',
        rejected => 'Rejetée',
      };
}

class ReclamationModel {
  final String id, bookingId, clientId, proId, subject, description;
  final String clientName, proName, serviceTitle;
  final ReclamationStatus status;
  final String? reviewedByAdminId, adminResponse;
  final DateTime createdAt, updatedAt;
  final DateTime? reviewedAt;

  const ReclamationModel(
      {required this.id,
      required this.bookingId,
      required this.clientId,
      required this.proId,
      required this.subject,
      required this.description,
      this.clientName = '',
      this.proName = '',
      this.serviceTitle = '',
      this.status = ReclamationStatus.pending,
      this.reviewedByAdminId,
      this.adminResponse,
      required this.createdAt,
      required this.updatedAt,
      this.reviewedAt});

  factory ReclamationModel.fromMap(Map<String, dynamic> m) => ReclamationModel(
      id: m['id'] as String,
      bookingId: m['bookingId'] as String,
      clientId: m['clientId'] as String,
      proId: m['proId'] as String,
      subject: m['subject'] as String,
      description: m['description'] as String,
      clientName: m['clientName'] as String? ?? '',
      proName: m['proName'] as String? ?? '',
      serviceTitle: m['serviceTitle'] as String? ?? '',
      status: ReclamationStatus.values.byName(m['status'] as String),
      reviewedByAdminId: m['reviewedByAdminId'] as String?,
      adminResponse: m['adminResponse'] as String?,
      createdAt: DateTime.parse(m['createdAt'] as String),
      updatedAt: DateTime.parse(m['updatedAt'] as String),
      reviewedAt: DateTime.tryParse(m['reviewedAt'] as String? ?? ''));
}
