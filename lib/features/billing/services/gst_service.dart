/// GST report and export service
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/models/bill_model.dart';

class GstService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  static CollectionReference<Map<String, dynamic>> get _billsRef =>
      _firestore.collection('$_basePath/bills');

  /// Get bills for a month (for GSTR-1 export)
  static Future<List<BillModel>> getMonthlyBills(int year, int month) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);

    final snapshot = await _billsRef
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt')
        .get();

    return snapshot.docs
        .map((doc) => BillModel.fromFirestore(doc))
        .toList();
  }

  /// Calculate GST summary for a period
  static Future<Map<String, double>> getGstSummary(
      DateTime start, DateTime end) async {
    final snapshot = await _billsRef
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    double totalCgst = 0, totalSgst = 0, totalTax = 0, totalTaxable = 0;
    for (final doc in snapshot.docs) {
      final bill = BillModel.fromFirestore(doc);
      totalCgst += bill.cgst;
      totalSgst += bill.sgst;
      totalTax += bill.totalTax;
      totalTaxable += bill.subtotal;
    }

    return {
      'totalCgst': totalCgst,
      'totalSgst': totalSgst,
      'totalTax': totalTax,
      'totalTaxable': totalTaxable,
      'totalRevenue': totalTaxable + totalTax,
    };
  }

  /// Generate GST breakdown by HSN code for a period
  static Future<Map<String, Map<String, double>>> getHsnBreakdown(
      DateTime start, DateTime end) async {
    final bills = await getMonthlyBills(start.year, start.month);
    final hsnMap = <String, Map<String, double>>{};

    for (final bill in bills) {
      if (bill.gstBreakdown == null) continue;
      for (final line in bill.gstBreakdown!) {
        final existing = hsnMap[line.hsnCode] ??
            {'taxableAmount': 0, 'cgst': 0, 'sgst': 0};
        existing['taxableAmount'] =
            (existing['taxableAmount'] ?? 0) + line.taxableAmount;
        existing['cgst'] = (existing['cgst'] ?? 0) + line.cgst;
        existing['sgst'] = (existing['sgst'] ?? 0) + line.sgst;
        hsnMap[line.hsnCode] = existing;
      }
    }

    return hsnMap;
  }

  /// Generate CSV data for GST export
  static String generateGstCsv(List<BillModel> bills) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Bill No,Date,Subtotal,CGST,SGST,Total Tax,Total,Payment Method');
    for (final bill in bills) {
      buffer.writeln(
          '${bill.billNumber},${bill.date},${bill.subtotal},${bill.cgst},${bill.sgst},${bill.totalTax},${bill.total},${bill.paymentMethod.displayName}');
    }
    return buffer.toString();
  }
}
