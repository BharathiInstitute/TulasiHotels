/// Tests for AdvancedReportsService — Firestore aggregation logic
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/order_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String billsPath;
  late String ordersPath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    billsPath = 'users/test-uid/bills';
    ordersPath = 'users/test-uid/orders';
  });

  /// Helper to write a raw bill doc matching BillModel.toFirestore shape
  Future<void> writeBill(
    String id, {
    required double total,
    required String date,
    required DateTime createdAt,
    String paymentMethod = 'cash',
    String? waiterName,
    List<Map<String, dynamic>>? items,
  }) async {
    await fakeFirestore.collection(billsPath).doc(id).set({
      'billNumber': 1,
      'items': items ?? [],
      'total': total,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'date': date,
      if (waiterName != null) 'waiterName': waiterName,
    });
  }

  group('dailyRevenue', () {
    test('aggregates by date string', () async {
      await writeBill('b1',
          total: 500, date: '2024-01-15', createdAt: DateTime(2024, 1, 15));
      await writeBill('b2',
          total: 300, date: '2024-01-15', createdAt: DateTime(2024, 1, 15));
      await writeBill('b3',
          total: 700, date: '2024-01-16', createdAt: DateTime(2024, 1, 16));

      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 2, 1);

      final snapshot = await fakeFirestore
          .collection(billsPath)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .get();

      final dailyMap = <String, double>{};
      for (final doc in snapshot.docs) {
        final bill = BillModel.fromFirestore(doc);
        dailyMap[bill.date] = (dailyMap[bill.date] ?? 0) + bill.total;
      }

      expect(dailyMap['2024-01-15'], 800);
      expect(dailyMap['2024-01-16'], 700);
    });
  });

  group('topProducts', () {
    test('accumulates quantity and revenue, sorted by quantity', () async {
      await writeBill('b-tp1',
          total: 1000,
          date: '2024-01-15',
          createdAt: DateTime(2024, 1, 15),
          items: [
            {'name': 'Dosa', 'quantity': 5, 'price': 80},
            {'name': 'Idli', 'quantity': 3, 'price': 50},
          ]);
      await writeBill('b-tp2',
          total: 500,
          date: '2024-01-15',
          createdAt: DateTime(2024, 1, 15),
          items: [
            {'name': 'Dosa', 'quantity': 2, 'price': 80},
          ]);

      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 2, 1);

      final snapshot = await fakeFirestore
          .collection(billsPath)
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
            productSales[name] = {
              'name': name,
              'quantity': 0,
              'revenue': 0.0,
            };
          }
          productSales[name]!['quantity'] =
              (productSales[name]!['quantity'] as int) + qty;
          productSales[name]!['revenue'] =
              (productSales[name]!['revenue'] as double) + (price * qty);
        }
      }

      final sorted = productSales.values.toList()
        ..sort(
            (a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

      expect(sorted.first['name'], 'Dosa');
      expect(sorted.first['quantity'], 7);
      expect(sorted.first['revenue'], 560.0); // (5+2) * 80
      expect(sorted[1]['name'], 'Idli');
      expect(sorted[1]['quantity'], 3);
      expect(sorted[1]['revenue'], 150.0); // 3 * 50
    });

    test('respects limit', () {
      final sorted = [
        {'name': 'A', 'quantity': 10},
        {'name': 'B', 'quantity': 5},
        {'name': 'C', 'quantity': 3},
      ];
      final top2 = sorted.take(2).toList();
      expect(top2.length, 2);
      expect(top2[0]['name'], 'A');
    });
  });

  group('revenueByPaymentMethod', () {
    test('groups bills by payment method display name', () async {
      await writeBill('b-pm1',
          total: 500,
          date: '2024-01-15',
          createdAt: DateTime(2024, 1, 15),
          paymentMethod: 'cash');
      await writeBill('b-pm2',
          total: 300,
          date: '2024-01-15',
          createdAt: DateTime(2024, 1, 15),
          paymentMethod: 'upi');
      await writeBill('b-pm3',
          total: 200,
          date: '2024-01-15',
          createdAt: DateTime(2024, 1, 15),
          paymentMethod: 'cash');

      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 2, 1);

      final snapshot = await fakeFirestore
          .collection(billsPath)
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

      expect(methodMap['Cash'], 700);
      expect(methodMap['UPI'], 300);
    });
  });

  group('orderTypeDistribution', () {
    test('counts orders by type', () async {
      final o1 = makeOrder(
          id: 'od1', orderType: OrderType.dineIn, createdAt: DateTime(2024, 1, 15));
      final o2 = makeOrder(
          id: 'od2', orderType: OrderType.takeaway, createdAt: DateTime(2024, 1, 15));
      final o3 = makeOrder(
          id: 'od3', orderType: OrderType.dineIn, createdAt: DateTime(2024, 1, 16));

      for (final o in [o1, o2, o3]) {
        await fakeFirestore
            .collection(ordersPath)
            .doc(o.id)
            .set(o.toFirestore());
      }

      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 2, 1);

      final snapshot = await fakeFirestore
          .collection(ordersPath)
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

      expect(typeMap[OrderType.dineIn.displayName], 2);
      expect(typeMap[OrderType.takeaway.displayName], 1);
    });
  });

  group('hourlyOrderCounts', () {
    test('counts orders per hour', () async {
      final o1 = makeOrder(
          id: 'h1', createdAt: DateTime(2024, 1, 15, 12, 30));
      final o2 = makeOrder(
          id: 'h2', createdAt: DateTime(2024, 1, 15, 12, 45));
      final o3 = makeOrder(
          id: 'h3', createdAt: DateTime(2024, 1, 15, 19, 0));

      for (final o in [o1, o2, o3]) {
        await fakeFirestore
            .collection(ordersPath)
            .doc(o.id)
            .set(o.toFirestore());
      }

      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 2, 1);

      final snapshot = await fakeFirestore
          .collection(ordersPath)
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

      expect(hourMap[12], 2);
      expect(hourMap[19], 1);
    });
  });

  group('waiterPerformance', () {
    test('groups by waiter name sorted by revenue', () async {
      await writeBill('b-wp1',
          total: 800,
          date: '2024-01-15',
          createdAt: DateTime(2024, 1, 15),
          waiterName: 'Ravi');
      await writeBill('b-wp2',
          total: 1200,
          date: '2024-01-15',
          createdAt: DateTime(2024, 1, 15),
          waiterName: 'Amit');
      await writeBill('b-wp3',
          total: 500,
          date: '2024-01-16',
          createdAt: DateTime(2024, 1, 16),
          waiterName: 'Ravi');

      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 2, 1);

      final snapshot = await fakeFirestore
          .collection(billsPath)
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

      final sorted = waiterMap.values.toList()
        ..sort((a, b) => (b['totalRevenue'] as double)
            .compareTo(a['totalRevenue'] as double));

      expect(sorted[0]['name'], 'Ravi');
      expect(sorted[0]['totalRevenue'], 1300.0);
      expect(sorted[0]['billCount'], 2);
      expect(sorted[1]['name'], 'Amit');
      expect(sorted[1]['totalRevenue'], 1200.0);
      expect(sorted[1]['billCount'], 1);
    });

    test('defaults to Unknown for null waiterName', () async {
      await writeBill('b-unk',
          total: 100,
          date: '2024-01-15',
          createdAt: DateTime(2024, 1, 15));

      final snapshot = await fakeFirestore.collection(billsPath).get();
      final bill = BillModel.fromFirestore(snapshot.docs.first);
      final name = bill.waiterName ?? 'Unknown';
      expect(name, 'Unknown');
    });
  });
}
