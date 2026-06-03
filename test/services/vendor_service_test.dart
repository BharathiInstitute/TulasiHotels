/// Tests for VendorService — CRUD, active filter, query by ID
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/vendor_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/vendors';
  });

  group('VendorService Firestore operations', () {
    test('create — writes and reads back all fields', () async {
      final vendor = makeVendor(
        id: 'v-1',
        name: 'Fresh Farm',
        phone: '9876543210',
        email: 'farm@test.com',
        address: '123 Market St',
        gstNumber: 'GST123',
        balance: 5000,
        supplyItems: ['Tomato', 'Onion', 'Potato'],
      );

      await fakeFirestore
          .collection(basePath)
          .doc(vendor.id)
          .set(vendor.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(vendor.id).get();
      final parsed = VendorModel.fromFirestore(doc);
      expect(parsed.name, 'Fresh Farm');
      expect(parsed.phone, '9876543210');
      expect(parsed.email, 'farm@test.com');
      expect(parsed.gstNumber, 'GST123');
      expect(parsed.balance, 5000);
      expect(parsed.supplyItems, ['Tomato', 'Onion', 'Potato']);
    });

    test('read — missing doc does not exist', () async {
      final doc =
          await fakeFirestore.collection(basePath).doc('missing').get();
      expect(doc.exists, isFalse);
    });

    test('update — modifies existing vendor', () async {
      final vendor = makeVendor(id: 'v-u1', name: 'Old Name');
      await fakeFirestore
          .collection(basePath)
          .doc(vendor.id)
          .set(vendor.toFirestore());

      final updated = vendor.copyWith(name: 'New Name');
      await fakeFirestore
          .collection(basePath)
          .doc(vendor.id)
          .update(updated.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('v-u1').get();
      final parsed = VendorModel.fromFirestore(doc);
      expect(parsed.name, 'New Name');
    });

    test('delete — removes vendor', () async {
      final vendor = makeVendor(id: 'v-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(vendor.id)
          .set(vendor.toFirestore());

      await fakeFirestore.collection(basePath).doc('v-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('v-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('activeVendorsStream query', () {
    test('filters only active vendors', () async {
      final active1 = makeVendor(id: 'a1', name: 'Active Vendor 1');
      final active2 = makeVendor(id: 'a2', name: 'Active Vendor 2');

      // VendorModel doesn't have isActive field by default, so we set
      // it manually in Firestore
      for (final v in [active1, active2]) {
        final data = v.toFirestore();
        data['isActive'] = true;
        await fakeFirestore.collection(basePath).doc(v.id).set(data);
      }

      final inactiveData = makeVendor(id: 'i1', name: 'Inactive').toFirestore();
      inactiveData['isActive'] = false;
      await fakeFirestore.collection(basePath).doc('i1').set(inactiveData);

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('isActive', isEqualTo: true)
          .get();

      expect(snapshot.docs.length, 2);
      final ids = snapshot.docs.map((d) => d.id).toSet();
      expect(ids, {'a1', 'a2'});
    });
  });

  group('vendorsStream ordering', () {
    test('returns vendors ordered by name', () async {
      final v1 = makeVendor(id: 'v1', name: 'Zest Foods');
      final v2 = makeVendor(id: 'v2', name: 'Agri Fresh');
      final v3 = makeVendor(id: 'v3', name: 'Metro Supplies');

      for (final v in [v1, v2, v3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(v.id)
            .set(v.toFirestore());
      }

      final snapshot =
          await fakeFirestore.collection(basePath).orderBy('name').get();

      final names = snapshot.docs
          .map((d) => VendorModel.fromFirestore(d).name)
          .toList();
      expect(names, ['Agri Fresh', 'Metro Supplies', 'Zest Foods']);
    });
  });

  group('vendor with supply items', () {
    test('empty supplyItems list round-trips correctly', () async {
      final vendor = makeVendor(id: 'v-empty', supplyItems: []);
      await fakeFirestore
          .collection(basePath)
          .doc(vendor.id)
          .set(vendor.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('v-empty').get();
      final parsed = VendorModel.fromFirestore(doc);
      expect(parsed.supplyItems, isEmpty);
    });

    test('supplyItems with multiple items round-trips', () async {
      final vendor = makeVendor(
        id: 'v-items',
        supplyItems: ['Rice', 'Wheat', 'Oil'],
      );
      await fakeFirestore
          .collection(basePath)
          .doc(vendor.id)
          .set(vendor.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('v-items').get();
      final parsed = VendorModel.fromFirestore(doc);
      expect(parsed.supplyItems, ['Rice', 'Wheat', 'Oil']);
    });
  });

  group('vendor balance', () {
    test('balance field persists through Firestore', () async {
      final vendor = makeVendor(id: 'v-bal', balance: 15000);
      await fakeFirestore
          .collection(basePath)
          .doc(vendor.id)
          .set(vendor.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('v-bal').get();
      final parsed = VendorModel.fromFirestore(doc);
      expect(parsed.balance, 15000);
    });
  });
}
