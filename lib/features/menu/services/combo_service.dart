/// Combo meal management service
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/models/combo_model.dart';

class ComboService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  static CollectionReference<Map<String, dynamic>> get _combosRef =>
      _firestore.collection('$_basePath/combos');

  /// Stream all combos
  static Stream<List<ComboModel>> combosStream() {
    return _combosRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ComboModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream only available combos
  static Stream<List<ComboModel>> availableCombosStream() {
    return _combosRef
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ComboModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get a single combo
  static Future<ComboModel?> getCombo(String comboId) async {
    final doc = await _combosRef.doc(comboId).get();
    if (!doc.exists) return null;
    return ComboModel.fromFirestore(doc);
  }

  /// Create a combo
  static Future<void> createCombo(ComboModel combo) async {
    await _combosRef.doc(combo.id).set(combo.toFirestore());
  }

  /// Update a combo
  static Future<void> updateCombo(ComboModel combo) async {
    await _combosRef.doc(combo.id).update(combo.toFirestore());
  }

  /// Delete a combo
  static Future<void> deleteCombo(String comboId) async {
    await _combosRef.doc(comboId).delete();
  }

  /// Toggle combo availability
  static Future<void> toggleAvailability(
      String comboId, bool isAvailable) async {
    await _combosRef.doc(comboId).update({'isAvailable': isAvailable});
  }
}
