/// Shift scheduling model for staff management
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/staff_model.dart';

/// Shift type categories
enum ShiftType {
  morning('Morning', '🌅'),
  afternoon('Afternoon', '☀️'),
  evening('Evening', '🌆'),
  night('Night', '🌙'),
  custom('Custom', '⚙️');

  final String displayName;
  final String emoji;

  const ShiftType(this.displayName, this.emoji);

  static ShiftType fromString(String value) {
    return ShiftType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ShiftType.custom,
    );
  }
}

class ShiftModel {
  final String id;
  final String staffId;
  final String staffName;
  final StaffRole role;
  final ShiftType shiftType;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final bool isSwapRequested;
  final String? swapWithStaffId;
  final DateTime createdAt;

  const ShiftModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.role,
    this.shiftType = ShiftType.custom,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.isSwapRequested = false,
    this.swapWithStaffId,
    required this.createdAt,
  });

  /// Duration of this shift
  Duration get duration => endTime.difference(startTime);

  factory ShiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShiftModel(
      id: doc.id,
      staffId: (data['staffId'] as String?) ?? '',
      staffName: (data['staffName'] as String?) ?? '',
      role: StaffRole.fromString((data['role'] as String?) ?? 'waiter'),
      shiftType: ShiftType.fromString(
        (data['shiftType'] as String?) ?? 'custom',
      ),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] as String?,
      isSwapRequested: (data['isSwapRequested'] as bool?) ?? false,
      swapWithStaffId: data['swapWithStaffId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'staffId': staffId,
      'staffName': staffName,
      'role': role.name,
      'shiftType': shiftType.name,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'notes': notes,
      'isSwapRequested': isSwapRequested,
      'swapWithStaffId': swapWithStaffId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ShiftModel copyWith({
    String? staffId,
    String? staffName,
    StaffRole? role,
    ShiftType? shiftType,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    bool? isSwapRequested,
    String? swapWithStaffId,
  }) {
    return ShiftModel(
      id: id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      role: role ?? this.role,
      shiftType: shiftType ?? this.shiftType,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      isSwapRequested: isSwapRequested ?? this.isSwapRequested,
      swapWithStaffId: swapWithStaffId ?? this.swapWithStaffId,
      createdAt: createdAt,
    );
  }
}
