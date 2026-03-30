/// Attendance service — Firestore CRUD for staff attendance tracking
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/models/attendance_model.dart';

class AttendanceService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  static CollectionReference<Map<String, dynamic>> get _attendanceRef =>
      _firestore.collection('$_basePath/attendance');

  /// Stream today's attendance records (real-time)
  static Stream<List<AttendanceModel>> todayAttendanceStream() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _attendanceRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList()
            ..sort((a, b) => b.clockIn.compareTo(a.clockIn)),
        );
  }

  /// Stream attendance for a specific date range
  static Stream<List<AttendanceModel>> attendanceStream({
    required DateTime from,
    required DateTime to,
  }) {
    return _attendanceRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream attendance for a specific staff member within a date range
  static Stream<List<AttendanceModel>> staffAttendanceStream({
    required String staffId,
    required DateTime from,
    required DateTime to,
  }) {
    return _attendanceRef
        .where('staffId', isEqualTo: staffId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Clock in a staff member
  static Future<AttendanceModel> clockIn({
    required String staffId,
    required String staffName,
  }) async {
    final now = DateTime.now();
    final id = generateSafeId('att');
    final attendance = AttendanceModel(
      id: id,
      staffId: staffId,
      staffName: staffName,
      date: DateTime(now.year, now.month, now.day),
      clockIn: now,
    );

    await _attendanceRef.doc(id).set(attendance.toFirestore());
    debugPrint('Clock in: $staffName at $now');
    return attendance;
  }

  /// Clock out a staff member
  ///
  /// If [recordId] is provided, updates that record directly (preferred).
  /// Otherwise falls back to querying for the open record.
  static Future<void> clockOut(String staffId, {String? recordId}) async {
    if (recordId != null) {
      await _attendanceRef.doc(recordId).update({
        'clockOut': Timestamp.fromDate(DateTime.now()),
        'status': AttendanceStatus.clockedOut.name,
      });
      debugPrint('Clock out: $staffId (direct)');
      return;
    }

    // Fallback: query for today's open record
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot = await _attendanceRef
        .where('staffId', isEqualTo: staffId)
        .where('status', isEqualTo: AttendanceStatus.clockedIn.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final docId = snapshot.docs.first.id;
    await _attendanceRef.doc(docId).update({
      'clockOut': Timestamp.fromDate(DateTime.now()),
      'status': AttendanceStatus.clockedOut.name,
    });
    debugPrint('Clock out: $staffId');
  }

  /// Check if a staff member is currently clocked in today
  static Future<bool> isClockedIn(String staffId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot = await _attendanceRef
        .where('staffId', isEqualTo: staffId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('status', isEqualTo: AttendanceStatus.clockedIn.name)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ── Owner manual corrections ──────────────────────────────────

  /// Add a manual attendance record (owner use)
  static Future<void> addManualRecord({
    required String staffId,
    required String staffName,
    required DateTime date,
    required DateTime clockIn,
    required DateTime clockOut,
  }) async {
    final id = generateSafeId('att');
    final attendance = AttendanceModel(
      id: id,
      staffId: staffId,
      staffName: staffName,
      date: DateTime(date.year, date.month, date.day),
      clockIn: clockIn,
      clockOut: clockOut,
      status: AttendanceStatus.clockedOut,
    );
    await _attendanceRef.doc(id).set(attendance.toFirestore());
    debugPrint('Manual record added for $staffName on $date');
  }

  /// Update an existing attendance record (owner correction)
  static Future<void> updateRecord(
    String recordId, {
    DateTime? clockIn,
    DateTime? clockOut,
    AttendanceStatus? status,
  }) async {
    final updates = <String, dynamic>{};
    if (clockIn != null) updates['clockIn'] = Timestamp.fromDate(clockIn);
    if (clockOut != null) updates['clockOut'] = Timestamp.fromDate(clockOut);
    if (status != null) updates['status'] = status.name;
    if (updates.isEmpty) return;
    await _attendanceRef.doc(recordId).update(updates);
    debugPrint('Record $recordId updated');
  }

  /// Delete an attendance record (owner correction)
  static Future<void> deleteRecord(String recordId) async {
    await _attendanceRef.doc(recordId).delete();
    debugPrint('Record $recordId deleted');
  }
}
