/// Attendance model for staff clock-in/clock-out tracking
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Attendance status
enum AttendanceStatus {
  clockedIn('Clocked In'),
  clockedOut('Clocked Out'),
  absent('Absent');

  final String displayName;
  const AttendanceStatus(this.displayName);

  static AttendanceStatus fromString(String value) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AttendanceStatus.absent,
    );
  }
}

class AttendanceModel {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime date;
  final DateTime clockIn;
  final DateTime? clockOut;
  final AttendanceStatus status;

  const AttendanceModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.date,
    required this.clockIn,
    this.clockOut,
    this.status = AttendanceStatus.clockedIn,
  });

  /// Hours worked (returns 0 if still clocked in)
  double get hoursWorked {
    if (clockOut == null) return 0;
    return clockOut!.difference(clockIn).inMinutes / 60.0;
  }

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      staffId: (data['staffId'] as String?) ?? '',
      staffName: (data['staffName'] as String?) ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clockIn: (data['clockIn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clockOut: (data['clockOut'] as Timestamp?)?.toDate(),
      status: AttendanceStatus.fromString(
        (data['status'] as String?) ?? 'clockedIn',
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'staffId': staffId,
      'staffName': staffName,
      'date': Timestamp.fromDate(date),
      'clockIn': Timestamp.fromDate(clockIn),
      'clockOut': clockOut != null ? Timestamp.fromDate(clockOut!) : null,
      'status': status.name,
    };
  }

  AttendanceModel copyWith({
    DateTime? clockOut,
    AttendanceStatus? status,
  }) {
    return AttendanceModel(
      id: id,
      staffId: staffId,
      staffName: staffName,
      date: date,
      clockIn: clockIn,
      clockOut: clockOut ?? this.clockOut,
      status: status ?? this.status,
    );
  }
}
