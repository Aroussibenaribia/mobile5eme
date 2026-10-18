enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'En attente';
      case BookingStatus.confirmed:
        return 'Confirmée';
      case BookingStatus.inProgress:
        return 'En cours';
      case BookingStatus.completed:
        return 'Terminée';
      case BookingStatus.cancelled:
        return 'Annulée';
    }
  }
}

class BookingModel {
  final String id;
  final String clientId;
  final String clientName;
  final String proId;
  final String proName;
  final String proSpecialty;
  final String serviceTitle;
  final DateTime scheduledDate;
  final String timeSlot;
  final String address;
  final double estimatedPrice;
  final BookingStatus status;
  final String? clientNotes;

  const BookingModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.proId,
    required this.proName,
    required this.proSpecialty,
    required this.serviceTitle,
    required this.scheduledDate,
    required this.timeSlot,
    required this.address,
    required this.estimatedPrice,
    this.status = BookingStatus.pending,
    this.clientNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'proId': proId,
      'proName': proName,
      'proSpecialty': proSpecialty,
      'serviceTitle': serviceTitle,
      'scheduledDate': scheduledDate.toIso8601String(),
      'timeSlot': timeSlot,
      'address': address,
      'estimatedPrice': estimatedPrice,
      'status': status.name,
      'clientNotes': clientNotes,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return BookingModel(
      id: docId ?? map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      proId: map['proId'] ?? '',
      proName: map['proName'] ?? '',
      proSpecialty: map['proSpecialty'] ?? '',
      serviceTitle: map['serviceTitle'] ?? '',
      scheduledDate: DateTime.tryParse(map['scheduledDate'] ?? '') ?? DateTime.now(),
      timeSlot: map['timeSlot'] ?? '',
      address: map['address'] ?? '',
      estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      clientNotes: map['clientNotes'],
    );
  }
}
