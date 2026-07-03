/// Staff management service â€” Firestore CRUD for staff members
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/subscription/services/plan_enforcement_service.dart';
import 'package:tulasihotels/models/staff_model.dart';

class StaffService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _staffRef =>
      _firestore.collection('$_basePath/staff');

  /// Stream all staff (real-time)
  static Stream<List<StaffModel>> staffStream() {
    return _staffRef
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream only active staff
  static Stream<List<StaffModel>> activeStaffStream() {
    return _staffRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => StaffModel.fromFirestore(doc)).toList()
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
    // Check staff limit before creating
    final check = await PlanEnforcementService.checkLimit(LimitType.staff);
    if (!check.allowed) {
      throw Exception(check.message);
    }

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
    _incrementStaffCount(1);
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
    _incrementStaffCount(-1);
  }

  /// Increment (or decrement) the user-level `limits.staffCount` counter.
  /// No Cloud Function exists for staff, so this is handled client-side.
  static void _incrementStaffCount(int delta) {
    // Write to the SAME document the subscription panel reads from
    final storeId =
        ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;
    if (storeId == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(storeId)
        .update({'limits.staffCount': FieldValue.increment(delta)})
        .ignore();
  }

  /// Toggle staff active/inactive status
  static Future<void> toggleStaffActive(String staffId, bool isActive) async {
    await _staffRef.doc(staffId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Verify staff PIN â€” returns the matching staff member or null
  static Future<StaffModel?> verifyPin(String pin) async {
    final snapshot = await _staffRef
        .where('pin', isEqualTo: pin)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return StaffModel.fromFirestore(snapshot.docs.first);
  }

  /// Verify staff email + PIN â€” returns the matching staff or null
  static Future<StaffModel?> verifyEmailAndPin(String email, String pin) async {
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
