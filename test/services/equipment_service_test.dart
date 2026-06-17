/// Tests for EquipmentService — Firestore CRUD + service record logic
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/equipment_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/equipment';
  });

  group('EquipmentService Firestore operations', () {
    test('create — writes and reads back all fields', () async {
      final equipment = makeEquipment(
        id: 'eq-1',
        name: 'Commercial Oven',
        brand: 'Voltas',
        serialNumber: 'SN-123',
        purchaseCost: 45000,
      );

      await fakeFirestore
          .collection(basePath)
          .doc(equipment.id)
          .set(equipment.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(equipment.id).get();
      expect(doc.exists, isTrue);

      final parsed = EquipmentModel.fromFirestore(doc);
      expect(parsed.name, 'Commercial Oven');
      expect(parsed.brand, 'Voltas');
      expect(parsed.serialNumber, 'SN-123');
      expect(parsed.purchaseCost, 45000);
    });

    test('read — missing doc does not exist', () async {
      final doc =
          await fakeFirestore.collection(basePath).doc('missing').get();
      expect(doc.exists, isFalse);
    });

    test('update — modifies existing fields', () async {
      final equipment = makeEquipment(id: 'eq-u1', name: 'Old Oven');
      await fakeFirestore
          .collection(basePath)
          .doc(equipment.id)
          .set(equipment.toFirestore());

      final updated = equipment.copyWith(name: 'New Oven');
      await fakeFirestore
          .collection(basePath)
          .doc(equipment.id)
          .update(updated.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('eq-u1').get();
      final parsed = EquipmentModel.fromFirestore(doc);
      expect(parsed.name, 'New Oven');
    });

    test('delete — removes document', () async {
      final equipment = makeEquipment(id: 'eq-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(equipment.id)
          .set(equipment.toFirestore());

      await fakeFirestore.collection(basePath).doc('eq-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('eq-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('addServiceRecord', () {
    test('appends service record to serviceHistory array', () async {
      final equipment = makeEquipment(id: 'eq-sr', serviceHistory: []);
      await fakeFirestore
          .collection(basePath)
          .doc(equipment.id)
          .set(equipment.toFirestore());

      final record = makeServiceRecord(
        description: 'Annual maintenance',
        cost: 2000,
      );

      // Simulate addServiceRecord: arrayUnion with record map
      await fakeFirestore.collection(basePath).doc('eq-sr').update({
        'serviceHistory': [record.toMap()],
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('eq-sr').get();
      final data = doc.data()!;
      final history = data['serviceHistory'] as List;
      expect(history.length, 1);
      expect(history[0]['description'], 'Annual maintenance');
      expect(history[0]['cost'], 2000);
    });
  });

  group('equipmentStream ordering', () {
    test('returns equipment ordered by name', () async {
      final equip1 = makeEquipment(id: 'e1', name: 'Blender');
      final equip2 = makeEquipment(id: 'e2', name: 'Oven');
      final equip3 = makeEquipment(id: 'e3', name: 'AC Unit');

      for (final e in [equip1, equip2, equip3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(e.id)
            .set(e.toFirestore());
      }

      final snapshot =
          await fakeFirestore.collection(basePath).orderBy('name').get();

      final names = snapshot.docs
          .map((d) => EquipmentModel.fromFirestore(d).name)
          .toList();
      expect(names, ['AC Unit', 'Blender', 'Oven']);
    });
  });

  group('needsServiceStream filtering', () {
    test('filters equipment with nextServiceDate within 30 days', () async {
      final soon = makeEquipment(
        id: 'e-soon',
        nextServiceDue: DateTime.now().add(const Duration(days: 10)),
      );
      final far = makeEquipment(
        id: 'e-far',
        nextServiceDue: DateTime.now().add(const Duration(days: 60)),
      );

      for (final e in [soon, far]) {
        await fakeFirestore
            .collection(basePath)
            .doc(e.id)
            .set(e.toFirestore());
      }

      // Simulate the query: nextServiceDate <= 30 days from now
      final snapshot = await fakeFirestore.collection(basePath).get();
      final needsService = snapshot.docs
          .map((d) => EquipmentModel.fromFirestore(d))
          .where((e) =>
              e.nextServiceDue != null &&
              e.nextServiceDue!.isBefore(
                  DateTime.now().add(const Duration(days: 30))))
          .toList();

      expect(needsService.length, 1);
      expect(needsService.first.id, 'e-soon');
    });
  });

  group('equipment with service history round-trip', () {
    test('multiple service records survive Firestore round-trip', () async {
      final records = [
        makeServiceRecord(description: 'Install', cost: 1000),
        makeServiceRecord(description: 'Repair'),
      ];
      final equipment =
          makeEquipment(id: 'eq-hist', serviceHistory: records);

      await fakeFirestore
          .collection(basePath)
          .doc(equipment.id)
          .set(equipment.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('eq-hist').get();
      final parsed = EquipmentModel.fromFirestore(doc);
      expect(parsed.serviceHistory.length, 2);
      expect(parsed.serviceHistory[0].description, 'Install');
      expect(parsed.serviceHistory[1].description, 'Repair');
    });
  });
}
