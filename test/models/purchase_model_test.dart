import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/purchase_model.dart';
import 'package:tulasihotels/models/bill_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('PurchaseItem', () {
    test('total calculates quantity * unitCost', () {
      final item = makePurchaseItem();
      expect(item.total, 500);
    });

    test('toMap serialises all fields', () {
      final item = makePurchaseItem(
        batchNumber: 'B001',
        expiryDate: DateTime(2025, 6),
      );
      final map = item.toMap();
      expect(map['ingredientId'], 'ing-1');
      expect(map['ingredientName'], 'Test Flour');
      expect(map['quantity'], 10.0);
      expect(map['unitCost'], 50.0);
      expect(map['batchNumber'], 'B001');
      expect(map['expiryDate'], isA<Timestamp>());
    });

    test('toMap with null optional fields', () {
      final map = makePurchaseItem().toMap();
      expect(map['batchNumber'], isNull);
      expect(map['expiryDate'], isNull);
    });

    test('fromMap deserialises correctly', () {
      final map = {
        'ingredientId': 'i1',
        'ingredientName': 'Sugar',
        'quantity': 20.0,
        'unitCost': 40.0,
        'batchNumber': 'B002',
      };
      final item = PurchaseItem.fromMap(map);
      expect(item.ingredientId, 'i1');
      expect(item.ingredientName, 'Sugar');
      expect(item.total, 800);
    });

    test('fromMap handles missing fields', () {
      final item = PurchaseItem.fromMap({});
      expect(item.ingredientId, '');
      expect(item.quantity, 0);
      expect(item.unitCost, 0);
    });
  });

  group('PurchaseModel', () {
    test('constructor defaults', () {
      final m = makePurchase();
      expect(m.paymentMethod, PaymentMethod.cash);
      expect(m.items.length, 1);
    });

    test('copyWith updates vendor and amount', () {
      final m = makePurchase();
      final updated = m.copyWith(vendorName: 'New Vendor', totalAmount: 8000);
      expect(updated.vendorName, 'New Vendor');
      expect(updated.totalAmount, 8000);
      expect(updated.id, m.id);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makePurchase(invoiceNumber: 'INV-001');
      final updated = m.copyWith();
      expect(updated.invoiceNumber, 'INV-001');
    });

    group('Firestore round-trip', () {
      test('toFirestore serialises items', () {
        final m = makePurchase(
          vendorId: 'v1',
          vendorName: 'Vendor A',
          invoiceNumber: 'INV-001',
          items: [
            makePurchaseItem(),
            makePurchaseItem(ingredientId: 'i2'),
          ],
        );
        final map = m.toFirestore();
        expect(map['vendorId'], 'v1');
        expect(map['invoiceNumber'], 'INV-001');
        expect(map['paymentMethod'], 'cash');
        expect((map['items'] as List).length, 2);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makePurchase(
          vendorId: 'v1',
          vendorName: 'Vendor A',
          totalAmount: 10000,
          paymentMethod: PaymentMethod.upi,
          invoiceNumber: 'INV-100',
          items: [
            makePurchaseItem(
              ingredientName: 'Rice',
              quantity: 50,
              unitCost: 60,
            ),
          ],
        );
        await firestore
            .collection('purchases')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('purchases')
            .doc(original.id)
            .get();
        final restored = PurchaseModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.vendorId, 'v1');
        expect(restored.vendorName, 'Vendor A');
        expect(restored.totalAmount, 10000);
        expect(restored.paymentMethod, PaymentMethod.upi);
        expect(restored.invoiceNumber, 'INV-100');
        expect(restored.items.first.ingredientName, 'Rice');
        expect(restored.items.first.total, 3000);
      });
    });
  });
}
