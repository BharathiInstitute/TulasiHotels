/// Staff management service — Firestore CRUD for staff members
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/models/staff_model.dart';

class StaffService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  static CollectionReference<Map<String, dynamic>> get _staffRef =>
      _firestore.collection('$_basePath/staff');

  /// Stream all staff (real-time)
  static Stream<List<StaffModel>> staffStream() {
    return _staffRef.orderBy('name').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => StaffModel.fromFirestore(doc)).toList(),
    );
  }

  /// Stream only active staff
  static Stream<List<StaffModel>> activeStaffStream() {
    return _staffRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffModel.fromFirestore(doc))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  /// Get a single staff member by ID
  static Future<StaffModel?> getStaff(String staffId) async {
    final doc = await _staffRef.doc(staffId).get();
    if (!doc.exists) return null;
    return StaffModel.fromFirestore(doc);
  }

  /// Create a new staff member
  static Future<StaffModel> createStaff({
    required String name,
    String? email,
    String? phone,
    StaffRole role = StaffRole.waiter,
    required String pin,
  }) async {
    final id = generateSafeId('staff');
    final now = DateTime.now();
    final staff = StaffModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      pin: pin,
      createdAt: now,
    );

    await _staffRef.doc(id).set(staff.toFirestore());
    debugPrint('Created staff: ${staff.name} (${staff.role.displayName})');
    return staff;
  }

  /// Update an existing staff member
  static Future<void> updateStaff(StaffModel staff) async {
    await _staffRef.doc(staff.id).update({
      ...staff.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update only the permissions for a staff member
  static Future<void> updatePermissions(
    String staffId,
    Map<String, List<String>> permissions,
  ) async {
    await _staffRef.doc(staffId).update({
      'permissions': permissions,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a staff member
  static Future<void> deleteStaff(String staffId) async {
    await _staffRef.doc(staffId).delete();
  }

  /// Toggle staff active/inactive status
  static Future<void> toggleStaffActive(
    String staffId,
    bool isActive,
  ) async {
    await _staffRef.doc(staffId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Verify staff PIN — returns the matching staff member or null
  static Future<StaffModel?> verifyPin(String pin) async {
    final snapshot = await _staffRef
        .where('pin', isEqualTo: pin)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return StaffModel.fromFirestore(snapshot.docs.first);
  }

  /// Verify staff email + PIN — returns the matching staff or null
  static Future<StaffModel?> verifyEmailAndPin(
    String email,
    String pin,
  ) async {
    final snapshot = await _staffRef
        .where('email', isEqualTo: email)
        .where('pin', isEqualTo: pin)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return StaffModel.fromFirestore(snapshot.docs.first);
  }

  /// Check if a PIN is already in use (for validation when creating/editing)
  static Future<bool> isPinTaken(String pin, {String? excludeStaffId}) async {
    final snapshot = await _staffRef
        .where('pin', isEqualTo: pin)
        .limit(2)
        .get();
    for (final doc in snapshot.docs) {
      if (doc.id != excludeStaffId) return true;
    }
    return false;
  }
}
