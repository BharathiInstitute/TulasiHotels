/// Shift scheduling service
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/models/shift_model.dart';

class ShiftService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  static CollectionReference<Map<String, dynamic>> get _shiftsRef =>
      _firestore.collection('$_basePath/shifts');

  /// Stream today's shifts
  static Stream<List<ShiftModel>> todayShiftsStream() {
    final today = DateTime.now();

    return _shiftsRef
        .where('date', isEqualTo: Timestamp.fromDate(DateTime(today.year, today.month, today.day)))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ShiftModel.fromFirestore(doc))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime)),
        );
  }

  /// Stream shifts for a specific staff member
  static Stream<List<ShiftModel>> staffShiftsStream(String staffId) {
    return _shiftsRef
        .where('staffId', isEqualTo: staffId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ShiftModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream shifts for a date range (weekly view)
  static Stream<List<ShiftModel>> weekShiftsStream(
      DateTime weekStart, DateTime weekEnd) {
    return _shiftsRef
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ShiftModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Create a shift
  static Future<void> createShift(ShiftModel shift) async {
    await _shiftsRef.doc(shift.id).set(shift.toFirestore());
  }

  /// Update a shift
  static Future<void> updateShift(ShiftModel shift) async {
    await _shiftsRef.doc(shift.id).update(shift.toFirestore());
  }

  /// Delete a shift
  static Future<void> deleteShift(String shiftId) async {
    await _shiftsRef.doc(shiftId).delete();
  }

  /// Bulk create shifts (for weekly scheduling)
  static Future<void> createBulkShifts(List<ShiftModel> shifts) async {
    final batch = _firestore.batch();
    for (final shift in shifts) {
      batch.set(_shiftsRef.doc(shift.id), shift.toFirestore());
    }
    await batch.commit();
  }

  /// Request a shift swap with another staff member
  static Future<void> requestSwap(
      String shiftId, String swapWithStaffId) async {
    await _shiftsRef.doc(shiftId).update({
      'isSwapRequested': true,
      'swapWithStaffId': swapWithStaffId,
    });
  }

  /// Approve a shift swap — swap the staffId/staffName between the two shifts
  static Future<void> approveSwap(String shiftId) async {
    final doc = await _shiftsRef.doc(shiftId).get();
    if (!doc.exists) return;
    final shift = ShiftModel.fromFirestore(doc);
    if (shift.swapWithStaffId == null) return;

    // Find the other staff's shift on the same date
    final otherShifts = await _shiftsRef
        .where('staffId', isEqualTo: shift.swapWithStaffId)
        .where('date', isEqualTo: Timestamp.fromDate(
            DateTime(shift.date.year, shift.date.month, shift.date.day)))
        .get();

    if (otherShifts.docs.isEmpty) return;

    final otherDoc = otherShifts.docs.first;
    final otherShift = ShiftModel.fromFirestore(otherDoc);

    final batch = _firestore.batch();
    batch.update(_shiftsRef.doc(shiftId), {
      'staffId': otherShift.staffId,
      'staffName': otherShift.staffName,
      'isSwapRequested': false,
      'swapWithStaffId': null,
    });
    batch.update(_shiftsRef.doc(otherDoc.id), {
      'staffId': shift.staffId,
      'staffName': shift.staffName,
    });
    await batch.commit();
  }
}
