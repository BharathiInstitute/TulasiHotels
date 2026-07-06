/// Cash register / drawer management service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/cash_register_model.dart';

class CashRegisterService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _registersRef =>
      _firestore.collection('$_basePath/cashRegisters');

  /// Stream today's register session
  static Stream<CashRegisterModel?> todayRegisterStream() {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return _registersRef
        .where('date', isEqualTo: dateStr)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return CashRegisterModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Stream all register sessions (for history)
  static Stream<List<CashRegisterModel>> registerHistoryStream() {
    return _registersRef
        .orderBy('openedAt', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CashRegisterModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Open a new register session
  static Future<void> openRegister(CashRegisterModel register) async {
    await _registersRef.doc(register.id).set(register.toFirestore());
  }

  /// Close the register
  static Future<void> closeRegister(
    String registerId, {
    required double closingBalance,
    String? closedByName,
    String? notes,
  }) async {
    await _registersRef.doc(registerId).update({
      'closingBalance': closingBalance,
      'closedAt': FieldValue.serverTimestamp(),
      'closedByName': closedByName,
      'notes': ?notes,
    });
  }

  /// Add a cash movement (in/out) to the register
  static Future<void> addCashMovement(
      String registerId, CashMovement movement) async {
    await _registersRef.doc(registerId).update({
      'movements': FieldValue.arrayUnion([movement.toMap()]),
    });
  }

  /// Get register by ID
  static Future<CashRegisterModel?> getRegister(String registerId) async {
    final doc = await _registersRef.doc(registerId).get();
    if (!doc.exists) return null;
    return CashRegisterModel.fromFirestore(doc);
  }
}
