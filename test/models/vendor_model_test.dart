import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/vendor_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('VendorModel', () {
    test('constructor defaults', () {
      final m = makeVendor();
      expect(m.balance, 0);
      expect(m.supplyItems, isEmpty);
      expect(m.gstNumber, isNull);
    });

    test('copyWith updates name and balance', () {
      final m = makeVendor();
      final updated = m.copyWith(name: 'New Vendor', balance: 5000);
      expect(updated.name, 'New Vendor');
      expect(updated.balance, 5000);
      expect(updated.id, m.id);
    });

    test('copyWith updates supplyItems', () {
      final m = makeVendor();
      final updated = m.copyWith(supplyItems: ['Rice', 'Oil']);
      expect(updated.supplyItems, ['Rice', 'Oil']);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeVendor(
        phone: '9876543210',
        email: 'vendor@test.com',
        gstNumber: 'GST123',
      );
      final updated = m.copyWith();
      expect(updated.phone, '9876543210');
      expect(updated.email, 'vendor@test.com');
      expect(updated.gstNumber, 'GST123');
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeVendor(
          phone: '9876543210',
          email: 'v@test.com',
          address: '123 Main St',
          gstNumber: 'GST999',
          balance: 10000,
          supplyItems: ['Rice', 'Oil', 'Spices'],
        );
        final map = m.toFirestore();
        expect(map['name'], 'Test Vendor');
        expect(map['phone'], '9876543210');
        expect(map['email'], 'v@test.com');
        expect(map['gstNumber'], 'GST999');
        expect(map['balance'], 10000);
        expect(map['supplyItems'], ['Rice', 'Oil', 'Spices']);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeVendor(
          name: 'Fresh Farms',
          phone: '8888888888',
          address: '456 Market Rd',
          gstNumber: 'GST456',
          balance: 25000,
          supplyItems: ['Vegetables', 'Fruits'],
        );
        await firestore
            .collection('vendors')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('vendors')
            .doc(original.id)
            .get();
        final restored = VendorModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.name, 'Fresh Farms');
        expect(restored.phone, '8888888888');
        expect(restored.gstNumber, 'GST456');
        expect(restored.balance, 25000);
        expect(restored.supplyItems, ['Vegetables', 'Fruits']);
      });
    });
  });
}
