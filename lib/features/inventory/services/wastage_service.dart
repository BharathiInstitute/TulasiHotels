/// Wastage logging service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/wastage_model.dart';

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

  /// Delete a wastage log
  static Future<void> deleteWastage(String wastageId) async {
    await _wastageRef.doc(wastageId).delete();
  }
}
