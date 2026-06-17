import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/equipment_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('ServiceRecord', () {
    test('toMap serialises all fields', () {
      final r = makeServiceRecord(vendorName: 'ACME');
      final map = r.toMap();
      expect(map['description'], 'Routine service');
      expect(map['cost'], 500.0);
      expect(map['vendorName'], 'ACME');
      expect(map['date'], isA<Timestamp>());
    });

    test('fromMap deserialises correctly', () {
      final map = {
        'date': Timestamp.fromDate(DateTime(2024, 3)),
        'description': 'Oil change',
        'cost': 200.0,
        'vendorName': 'Vendor A',
      };
      final r = ServiceRecord.fromMap(map);
      expect(r.description, 'Oil change');
      expect(r.cost, 200.0);
      expect(r.vendorName, 'Vendor A');
    });

    test('fromMap handles missing fields', () {
      final r = ServiceRecord.fromMap({});
      expect(r.description, '');
      expect(r.cost, 0);
      expect(r.vendorName, isNull);
    });
  });

  group('EquipmentModel', () {
    test('constructor defaults', () {
      final m = makeEquipment();
      expect(m.serviceHistory, isEmpty);
      expect(m.brand, isNull);
    });

    test('isServiceOverdue true when past due', () {
      final m = makeEquipment(
        nextServiceDue: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(m.isServiceOverdue, isTrue);
    });

    test('isServiceOverdue false when future', () {
      final m = makeEquipment(
        nextServiceDue: DateTime.now().add(const Duration(days: 30)),
      );
      expect(m.isServiceOverdue, isFalse);
    });

    test('isServiceOverdue false when null', () {
      final m = makeEquipment();
      expect(m.isServiceOverdue, isFalse);
    });

    test('isUnderWarranty true when warranty active', () {
      final m = makeEquipment(
        warrantyUntil: DateTime.now().add(const Duration(days: 365)),
      );
      expect(m.isUnderWarranty, isTrue);
    });

    test('isUnderWarranty false when warranty expired', () {
      final m = makeEquipment(
        warrantyUntil: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(m.isUnderWarranty, isFalse);
    });

    test('isUnderWarranty false when null', () {
      final m = makeEquipment();
      expect(m.isUnderWarranty, isFalse);
    });

    group('Firestore round-trip', () {
      test('toFirestore serialises serviceHistory', () {
        final m = makeEquipment(
          brand: 'Bosch',
          serialNumber: 'SN-123',
          serviceHistory: [makeServiceRecord()],
        );
        final map = m.toFirestore();
        expect(map['name'], 'Test Oven');
        expect(map['brand'], 'Bosch');
        expect(map['serialNumber'], 'SN-123');
        expect((map['serviceHistory'] as List).length, 1);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeEquipment(
          brand: 'Bosch',
          purchaseCost: 50000,
          warrantyUntil: DateTime(2026),
          serviceHistory: [
            makeServiceRecord(description: 'Filter check', cost: 300),
          ],
          amcVendor: 'ServiceCo',
          amcPhone: '1234567890',
        );
        await firestore
            .collection('equipment')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('equipment')
            .doc(original.id)
            .get();
        final restored = EquipmentModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.name, 'Test Oven');
        expect(restored.brand, 'Bosch');
        expect(restored.purchaseCost, 50000);
        expect(restored.serviceHistory.length, 1);
        expect(restored.serviceHistory.first.description, 'Filter check');
        expect(restored.amcVendor, 'ServiceCo');
      });
    });
  });
}
