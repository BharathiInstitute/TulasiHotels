/// Reservation model for table bookings
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Reservation lifecycle status
enum ReservationStatus {
  pending('Pending', '🕐'),
  confirmed('Confirmed', '✅'),
  seated('Seated', '🪑'),
  cancelled('Cancelled', '❌'),
  noShow('No Show', '👻');

  final String displayName;
  final String emoji;

  const ReservationStatus(this.displayName, this.emoji);

  static ReservationStatus fromString(String value) {
    return ReservationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReservationStatus.pending,
    );
  }
}

class ReservationModel {
  final String id;
  final String? tableId;
  final String guestName;
  final String phone;
  final int partySize;
  final DateTime dateTime;
  final int durationMinutes;
  final ReservationStatus status;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReservationModel({
    required this.id,
    required this.guestName,
    required this.phone,
    required this.partySize,
    required this.dateTime,
    this.tableId,
    this.durationMinutes = 90,
    this.status = ReservationStatus.pending,
    this.specialRequests,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReservationModel(
      id: doc.id,
      tableId: data['tableId'] as String?,
      guestName: (data['guestName'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      partySize: (data['partySize'] as int?) ?? 1,
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: (data['durationMinutes'] as int?) ?? 90,
      status: ReservationStatus.fromString(
        (data['status'] as String?) ?? 'pending',
      ),
      specialRequests: data['specialRequests'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tableId': tableId,
      'guestName': guestName,
      'phone': phone,
      'partySize': partySize,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'status': status.name,
      'specialRequests': specialRequests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ReservationModel copyWith({
    String? tableId,
    String? guestName,
    String? phone,
    int? partySize,
    DateTime? dateTime,
    int? durationMinutes,
    ReservationStatus? status,
    String? specialRequests,
  }) {
    return ReservationModel(
      id: id,
      tableId: tableId ?? this.tableId,
      guestName: guestName ?? this.guestName,
      phone: phone ?? this.phone,
      partySize: partySize ?? this.partySize,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      specialRequests: specialRequests ?? this.specialRequests,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
