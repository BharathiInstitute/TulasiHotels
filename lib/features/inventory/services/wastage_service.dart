/// Wastage logging service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/features/permissions/services/module_mutation_guard.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/wastage_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class WastageService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _wastageRef =>
      _firestore.collection('$_basePath/wastage');

  /// Stream recent wastage logs
  static Stream<List<WastageModel>> recentWastageStream() {
    return _wastageRef
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WastageModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream wastage for a date range
  static Stream<List<WastageModel>> wastageForDateRange(
      DateTime start, DateTime end) {
    return _wastageRef
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WastageModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Log a wastage entry and deduct from ingredient stock
  static Future<void> logWastage(WastageModel wastage) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.wastage,
      PermissionAction.create,
    );
    final batch = _firestore.batch();

    batch.set(_wastageRef.doc(wastage.id), wastage.toFirestore());

    // Deduct from ingredient stock if linked
    if (wastage.ingredientId.isNotEmpty) {
      final ingredientRef = _firestore
          .collection('$_basePath/ingredients')
          .doc(wastage.ingredientId);
      batch.update(ingredientRef, {
        'currentStock': FieldValue.increment(-wastage.quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Reverse a wastage log and restore linked ingredient stock atomically.
  static Future<void> reverseWastage(
    String wastageId, {
    String? reason,
  }) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.wastage,
      PermissionAction.update,
    );

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('User is not signed in');

    await _firestore.runTransaction((transaction) async {
      final wastageRef = _wastageRef.doc(wastageId);
      final wastageSnapshot = await transaction.get(wastageRef);
      if (!wastageSnapshot.exists) throw StateError('Wastage record not found');

      final wastage = WastageModel.fromFirestore(wastageSnapshot);
      if (wastage.status == WastageStatus.reversed) {
        throw StateError('Wastage record is already reversed');
      }

      if (wastage.ingredientId.isNotEmpty) {
        final ingredientRef = _firestore
            .collection('$_basePath/ingredients')
            .doc(wastage.ingredientId);
        transaction.update(ingredientRef, {
          'currentStock': FieldValue.increment(wastage.quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(wastageRef, {
        'status': WastageStatus.reversed.name,
        'reversedAt': FieldValue.serverTimestamp(),
        'reversedBy': uid,
        'reversalReason': reason?.trim().isEmpty == true ? null : reason?.trim(),
      });
    });
  }
}
