/// Advanced reports service — analytics, trends, and intelligence
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/order_model.dart';

class AdvancedReportsService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  /// Get daily revenue for a date range (for charting)
  static Future<Map<String, double>> dailyRevenue(
      DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('$_basePath/bills')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    final dailyMap = <String, double>{};
    for (final doc in snapshot.docs) {
      final bill = BillModel.fromFirestore(doc);
      dailyMap[bill.date] = (dailyMap[bill.date] ?? 0) + bill.total;
    }
    return dailyMap;
  }

  /// Get top-selling products for a period
  static Future<List<Map<String, dynamic>>> topProducts(
      DateTime start, DateTime end,
      {int limit = 10}) async {
    final snapshot = await _firestore
        .collection('$_basePath/bills')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    final productSales = <String, Map<String, dynamic>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final items = (data['items'] as List<dynamic>?) ?? [];
      for (final item in items) {
        final map = item as Map<String, dynamic>;
        final name = (map['name'] as String?) ?? '';
        final qty = (map['quantity'] as int?) ?? 1;
        final price = (map['price'] as num?)?.toDouble() ?? 0;

        if (productSales[name] == null) {
          productSales[name] = {'name': name, 'quantity': 0, 'revenue': 0.0};
        }
        productSales[name]!['quantity'] =
            (productSales[name]!['quantity'] as int) + qty;
        productSales[name]!['revenue'] =
            (productSales[name]!['revenue'] as double) + (price * qty);
      }
    }

    final sorted = productSales.values.toList()
      ..sort((a, b) =>
          (b['quantity'] as int).compareTo(a['quantity'] as int));
    return sorted.take(limit).toList();
  }

  /// Get revenue by payment method
  static Future<Map<String, double>> revenueByPaymentMethod(
      DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('$_basePath/bills')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    final methodMap = <String, double>{};
    for (final doc in snapshot.docs) {
      final bill = BillModel.fromFirestore(doc);
      final key = bill.paymentMethod.displayName;
      methodMap[key] = (methodMap[key] ?? 0) + bill.total;
    }
    return methodMap;
  }

  /// Get order type distribution
  static Future<Map<String, int>> orderTypeDistribution(
      DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('$_basePath/orders')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    final typeMap = <String, int>{};
    for (final doc in snapshot.docs) {
      final order = OrderModel.fromFirestore(doc);
      final key = order.orderType.displayName;
      typeMap[key] = (typeMap[key] ?? 0) + 1;
    }
    return typeMap;
  }

  /// Get hourly order counts (peak hour analysis)
  static Future<Map<int, int>> hourlyOrderCounts(
      DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('$_basePath/orders')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    final hourMap = <int, int>{};
    for (final doc in snapshot.docs) {
      final order = OrderModel.fromFirestore(doc);
      final hour = order.createdAt.hour;
      hourMap[hour] = (hourMap[hour] ?? 0) + 1;
    }
    return hourMap;
  }

  /// Get waiter performance statistics
  static Future<List<Map<String, dynamic>>> waiterPerformance(
      DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('$_basePath/bills')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    final waiterMap = <String, Map<String, dynamic>>{};
    for (final doc in snapshot.docs) {
      final bill = BillModel.fromFirestore(doc);
      final name = bill.waiterName ?? 'Unknown';
      if (waiterMap[name] == null) {
        waiterMap[name] = {
          'name': name,
          'billCount': 0,
          'totalRevenue': 0.0,
        };
      }
      waiterMap[name]!['billCount'] =
          (waiterMap[name]!['billCount'] as int) + 1;
      waiterMap[name]!['totalRevenue'] =
          (waiterMap[name]!['totalRevenue'] as double) + bill.total;
    }

    return waiterMap.values.toList()
      ..sort((a, b) => (b['totalRevenue'] as double)
          .compareTo(a['totalRevenue'] as double));
  }

  /// Get raw bills in a date range (for export)
  static Future<List<BillModel>> getBillsInRange(
      DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('$_basePath/bills')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => BillModel.fromFirestore(doc)).toList();
  }
}
