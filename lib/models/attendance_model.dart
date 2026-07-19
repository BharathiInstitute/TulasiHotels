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

/// Source of the clock-in/out action
enum ClockSource {
  staff, // Staff self-service
  admin, // Admin/Owner manually recorded
  manual; // Manual retroactive entry

  static ClockSource fromString(String? value) {
    if (value == null) return ClockSource.staff;
    return ClockSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClockSource.staff,
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

  // Geo-tag fields (nullable for backward compatibility)
  final double? clockInLat;
  final double? clockInLng;
  final String? clockInAddress;
  final bool? clockInInside; // true = inside office geofence
  final double? clockOutLat;
  final double? clockOutLng;
  final String? clockOutAddress;
  final bool? clockOutInside; // true = inside office geofence

  // Source & audit fields
  final ClockSource clockInSource;
  final ClockSource? clockOutSource;
  final String? editedBy;
  final DateTime? editedAt;
  final String? editNote;

  const AttendanceModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.date,
    required this.clockIn,
    this.clockOut,
    this.status = AttendanceStatus.clockedIn,
    this.clockInLat,
    this.clockInLng,
    this.clockInAddress,
    this.clockInInside,
    this.clockOutLat,
    this.clockOutLng,
    this.clockOutAddress,
    this.clockOutInside,
    this.clockInSource = ClockSource.staff,
    this.clockOutSource,
    this.editedBy,
    this.editedAt,
    this.editNote,
  });

  /// Worked duration (returns zero if still clocked in)
  Duration get workedDuration {
    if (clockOut == null) return Duration.zero;
    return clockOut!.difference(clockIn);
  }

  int get workedMinutes => workedDuration.inMinutes;

  String get workedDurationLabel {
    return formatMinutes(workedMinutes);
  }

  static String formatMinutes(int totalMinutes) {
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Hours worked (returns 0 if still clocked in)
  double get hoursWorked {
    return workedMinutes / 60.0;
  }

  /// Whether this record has a geo-tag for clock-in
  bool get hasClockInLocation => clockInLat != null && clockInLng != null;

  /// Whether this record has a geo-tag for clock-out
  bool get hasClockOutLocation => clockOutLat != null && clockOutLng != null;

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
      clockInLat: (data['clockInLat'] as num?)?.toDouble(),
      clockInLng: (data['clockInLng'] as num?)?.toDouble(),
      clockInAddress: data['clockInAddress'] as String?,
      clockInInside: data['clockInInside'] as bool?,
      clockOutLat: (data['clockOutLat'] as num?)?.toDouble(),
      clockOutLng: (data['clockOutLng'] as num?)?.toDouble(),
      clockOutAddress: data['clockOutAddress'] as String?,
      clockOutInside: data['clockOutInside'] as bool?,
      clockInSource: ClockSource.fromString(data['clockInSource'] as String?),
      clockOutSource: data['clockOutSource'] != null
          ? ClockSource.fromString(data['clockOutSource'] as String?)
          : null,
      editedBy: data['editedBy'] as String?,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      editNote: data['editNote'] as String?,
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
      if (clockInLat != null) 'clockInLat': clockInLat,
      if (clockInLng != null) 'clockInLng': clockInLng,
      if (clockInAddress != null) 'clockInAddress': clockInAddress,
      if (clockInInside != null) 'clockInInside': clockInInside,
      if (clockOutLat != null) 'clockOutLat': clockOutLat,
      if (clockOutLng != null) 'clockOutLng': clockOutLng,
      if (clockOutAddress != null) 'clockOutAddress': clockOutAddress,
      if (clockOutInside != null) 'clockOutInside': clockOutInside,
      'clockInSource': clockInSource.name,
      if (clockOutSource != null) 'clockOutSource': clockOutSource!.name,
      if (editedBy != null) 'editedBy': editedBy,
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
      if (editNote != null) 'editNote': editNote,
    };
  }

  AttendanceModel copyWith({
    DateTime? clockIn,
    DateTime? clockOut,
    AttendanceStatus? status,
    double? clockInLat,
    double? clockInLng,
    String? clockInAddress,
    bool? clockInInside,
    double? clockOutLat,
    double? clockOutLng,
    String? clockOutAddress,
    bool? clockOutInside,
    ClockSource? clockInSource,
    ClockSource? clockOutSource,
    String? editedBy,
    DateTime? editedAt,
    String? editNote,
  }) {
    return AttendanceModel(
      id: id,
      staffId: staffId,
      staffName: staffName,
      date: date,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      status: status ?? this.status,
      clockInLat: clockInLat ?? this.clockInLat,
      clockInLng: clockInLng ?? this.clockInLng,
      clockInAddress: clockInAddress ?? this.clockInAddress,
      clockInInside: clockInInside ?? this.clockInInside,
      clockOutLat: clockOutLat ?? this.clockOutLat,
      clockOutLng: clockOutLng ?? this.clockOutLng,
      clockOutAddress: clockOutAddress ?? this.clockOutAddress,
      clockOutInside: clockOutInside ?? this.clockOutInside,
      clockInSource: clockInSource ?? this.clockInSource,
      clockOutSource: clockOutSource ?? this.clockOutSource,
      editedBy: editedBy ?? this.editedBy,
      editedAt: editedAt ?? this.editedAt,
      editNote: editNote ?? this.editNote,
    );
  }
}
