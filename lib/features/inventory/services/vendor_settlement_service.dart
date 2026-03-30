/// Vendor payment settlement service
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/models/purchase_model.dart';

class VendorSettlementService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  /// Record a payment to a vendor (reduces their balance)
  static Future<void> recordPayment({
    required String vendorId,
    required double amount,
    String? note,
  }) async {
    final batch = _firestore.batch();

    // Add payment record
    final paymentRef = _firestore
        .collection('$_basePath/vendorPayments')
        .doc();
    batch.set(paymentRef, {
      'vendorId': vendorId,
      'amount': amount,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update vendor balance
    final vendorRef = _firestore.doc('$_basePath/vendors/$vendorId');
    batch.update(vendorRef, {
      'balance': FieldValue.increment(-amount),
    });

    await batch.commit();
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

  /// Get payment history for a vendor
  static Stream<List<Map<String, dynamic>>> paymentHistoryStream(
      String vendorId) {
    return _firestore
        .collection('$_basePath/vendorPayments')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'amount': (data['amount'] as num?)?.toDouble() ?? 0,
                'note': data['note'] as String?,
                'createdAt':
                    (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              };
            }).toList());
  }
}
