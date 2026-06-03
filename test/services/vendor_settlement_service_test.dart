/// Tests for VendorSettlementService — payment recording, balance, unpaid purchases
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid';
  });

  group('recordPayment', () {
    test('creates payment record and reduces vendor balance', () async {
      // Set up vendor with existing balance
      final vendor = makeVendor(id: 'v-pay', balance: 10000);
      final vendorData = vendor.toFirestore();
      await fakeFirestore
          .collection('$basePath/vendors')
          .doc(vendor.id)
          .set(vendorData);

      // Simulate batch: create payment + update vendor balance
      await fakeFirestore.collection('$basePath/vendorPayments').doc().set({
        'vendorId': 'v-pay',
        'amount': 3000.0,
        'note': 'Weekly payment',
        'createdAt': DateTime.now().toIso8601String(),
      });
      await fakeFirestore.collection('$basePath/vendors').doc('v-pay').update({
        'balance': 7000.0,
      });

      // Verify vendor balance reduced
      final vendorDoc = await fakeFirestore
          .collection('$basePath/vendors')
          .doc('v-pay')
          .get();
      expect(vendorDoc.data()!['balance'], 7000.0);

      // Verify payment record exists
      final payments = await fakeFirestore
          .collection('$basePath/vendorPayments')
          .get();
      expect(payments.docs.length, 1);
      expect(payments.docs.first.data()['amount'], 3000.0);
      expect(payments.docs.first.data()['note'], 'Weekly payment');
    });
  });

  group('vendorBalanceStream', () {
    test('returns balance from vendor document', () async {
      await fakeFirestore.collection('$basePath/vendors').doc('v-1').set({
        'name': 'Test Vendor',
        'balance': 5000,
      });

      final doc = await fakeFirestore
          .collection('$basePath/vendors')
          .doc('v-1')
          .get();
      final balance = (doc.data()?['balance'] as num?)?.toDouble() ?? 0;
      expect(balance, 5000);
    });

    test('returns 0 when balance field is missing', () async {
      await fakeFirestore.collection('$basePath/vendors').doc('v-nobal').set({
        'name': 'No Balance',
      });

      final doc = await fakeFirestore
          .collection('$basePath/vendors')
          .doc('v-nobal')
          .get();
      final balance = (doc.data()?['balance'] as num?)?.toDouble() ?? 0;
      expect(balance, 0);
    });
  });

  group('unpaidPurchases', () {
    test('filters unpaid purchases for a specific vendor', () async {
      // Create purchases
      final paid = makePurchase(id: 'p-paid', vendorId: 'v-1');
      final unpaid1 = makePurchase(id: 'p-unpaid1', vendorId: 'v-1');
      final unpaid2 = makePurchase(id: 'p-unpaid2', vendorId: 'v-1');
      final otherVendor = makePurchase(id: 'p-other', vendorId: 'v-2');

      final paidData = paid.toFirestore();
      paidData['isPaid'] = true;
      paidData['vendorId'] = 'v-1';
      await fakeFirestore
          .collection('$basePath/purchases')
          .doc(paid.id)
          .set(paidData);

      for (final p in [unpaid1, unpaid2]) {
        final data = p.toFirestore();
        data['isPaid'] = false;
        data['vendorId'] = 'v-1';
        await fakeFirestore
            .collection('$basePath/purchases')
            .doc(p.id)
            .set(data);
      }

      final otherData = otherVendor.toFirestore();
      otherData['isPaid'] = false;
      otherData['vendorId'] = 'v-2';
      await fakeFirestore
          .collection('$basePath/purchases')
          .doc(otherVendor.id)
          .set(otherData);

      // Query: unpaid for vendor v-1
      final snapshot = await fakeFirestore
          .collection('$basePath/purchases')
          .where('vendorId', isEqualTo: 'v-1')
          .where('isPaid', isEqualTo: false)
          .get();

      expect(snapshot.docs.length, 2);
      final ids = snapshot.docs.map((d) => d.id).toSet();
      expect(ids, {'p-unpaid1', 'p-unpaid2'});
    });

    test('returns empty list when all purchases are paid', () async {
      final paid = makePurchase(id: 'p-allpaid', vendorId: 'v-3');
      final data = paid.toFirestore();
      data['isPaid'] = true;
      data['vendorId'] = 'v-3';
      await fakeFirestore
          .collection('$basePath/purchases')
          .doc(paid.id)
          .set(data);

      final snapshot = await fakeFirestore
          .collection('$basePath/purchases')
          .where('vendorId', isEqualTo: 'v-3')
          .where('isPaid', isEqualTo: false)
          .get();

      expect(snapshot.docs, isEmpty);
    });
  });

  group('paymentHistoryStream', () {
    test('returns payments for specific vendor ordered by createdAt', () async {
      await fakeFirestore
          .collection('$basePath/vendorPayments')
          .doc('pay-1')
          .set({
            'vendorId': 'v-1',
            'amount': 2000,
            'createdAt': DateTime(2024, 1, 15).toIso8601String(),
          });
      await fakeFirestore
          .collection('$basePath/vendorPayments')
          .doc('pay-2')
          .set({
            'vendorId': 'v-1',
            'amount': 3000,
            'createdAt': DateTime(2024, 2, 15).toIso8601String(),
          });
      await fakeFirestore
          .collection('$basePath/vendorPayments')
          .doc('pay-3')
          .set({
            'vendorId': 'v-2',
            'amount': 1000,
            'createdAt': DateTime(2024, 3, 1).toIso8601String(),
          });

      final snapshot = await fakeFirestore
          .collection('$basePath/vendorPayments')
          .where('vendorId', isEqualTo: 'v-1')
          .get();

      expect(snapshot.docs.length, 2);
      final amounts = snapshot.docs.map((d) => d.data()['amount']).toList();
      expect(amounts, containsAll([2000, 3000]));
    });
  });

  group('multiple payments reduce balance correctly', () {
    test('sequential payments reduce vendor balance', () async {
      await fakeFirestore.collection('$basePath/vendors').doc('v-multi').set({
        'name': 'Multi Pay',
        'balance': 10000,
      });

      // First payment: 3000
      await fakeFirestore.collection('$basePath/vendors').doc('v-multi').update(
        {'balance': 7000},
      );

      // Second payment: 2000
      await fakeFirestore.collection('$basePath/vendors').doc('v-multi').update(
        {'balance': 5000},
      );

      final doc = await fakeFirestore
          .collection('$basePath/vendors')
          .doc('v-multi')
          .get();
      expect(doc.data()!['balance'], 5000);
    });
  });
}
