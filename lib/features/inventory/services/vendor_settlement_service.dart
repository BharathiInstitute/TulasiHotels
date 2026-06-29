/// Vendor payment settlement service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/purchase_model.dart';

class VendorSettlementService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  /// Record a purchase from a vendor (increases balance â€” you owe them more)
  static Future<void> recordPurchase({
    required String vendorId,
    required double amount,
    String? note,
  }) async {
    final batch = _firestore.batch();

    // Add settlement record
    final ref = _firestore.collection('$_basePath/vendorSettlements').doc();
    batch.set(ref, {
      'vendorId': vendorId,
      'type': 'purchase',
      'amount': amount,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update vendor balance (positive = you owe them)
    final vendorRef = _firestore.doc('$_basePath/vendors/$vendorId');
    batch.update(vendorRef, {'balance': FieldValue.increment(amount)});

    await batch.commit();
  }

  /// Record a payment to a vendor (decreases balance â€” you paid them)
  static Future<void> recordPayment({
    required String vendorId,
    required double amount,
    String? note,
  }) async {
    final batch = _firestore.batch();

    // Add settlement record
    final ref = _firestore.collection('$_basePath/vendorSettlements').doc();
    batch.set(ref, {
      'vendorId': vendorId,
      'type': 'payment',
      'amount': amount,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update vendor balance
    final vendorRef = _firestore.doc('$_basePath/vendors/$vendorId');
    batch.update(vendorRef, {'balance': FieldValue.increment(-amount)});

    await batch.commit();
  }

  /// Stream full settlement history (purchases + payments) for a vendor
  static Stream<List<Map<String, dynamic>>> settlementHistoryStream(
      String vendorId) {
    return _firestore
        .collection('$_basePath/vendorSettlements')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'type': data['type'] as String? ?? 'payment',
                'amount': (data['amount'] as num?)?.toDouble() ?? 0,
                'note': data['note'] as String?,
                'createdAt':
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              };
            }).toList());
  }

  /// Stream the current balance for a vendor
  static Stream<double> vendorBalanceStream(String vendorId) {
    return _firestore
        .doc('$_basePath/vendors/$vendorId')
        .snapshots()
        .map((doc) => (doc.data()?['balance'] as num?)?.toDouble() ?? 0);
  }

  /// Get unpaid purchases for a vendor
  static Future<List<PurchaseModel>> unpaidPurchases(String vendorId) async {
    final snapshot = await _firestore
        .collection('$_basePath/purchases')
        .where('vendorId', isEqualTo: vendorId)
        .where('isPaid', isEqualTo: false)
        .orderBy('purchaseDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PurchaseModel.fromFirestore(doc))
        .toList();
  }

  /// Keep old method for backwards compatibility
  static Stream<List<Map<String, dynamic>>> paymentHistoryStream(
      String vendorId) => settlementHistoryStream(vendorId);
}
