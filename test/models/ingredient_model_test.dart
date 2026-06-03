import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/ingredient_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('IngredientUnit enum', () {
    test('displayName and shortName', () {
      expect(IngredientUnit.kg.displayName, 'Kilogram');
      expect(IngredientUnit.kg.shortName, 'kg');
      expect(IngredientUnit.ml.displayName, isNotEmpty);
      expect(IngredientUnit.ml.shortName, 'ml');
      expect(IngredientUnit.pieces.displayName, 'Pieces');
    });

    test('fromString parses all values', () {
      for (final u in IngredientUnit.values) {
        expect(IngredientUnit.fromString(u.name), u);
      }
    });

    test('fromString defaults to kg for unknown', () {
      expect(IngredientUnit.fromString('xyz'), IngredientUnit.kg);
    });
  });

  group('IngredientModel', () {
    test('constructor defaults', () {
      final m = makeIngredient();
      expect(m.unit, IngredientUnit.kg);
      expect(m.currentStock, 100.0);
      expect(m.minLevel, 10.0);
    });

    test('isLowStock true when at minLevel', () {
      final m = makeIngredient(currentStock: 10, minLevel: 10);
      expect(m.isLowStock, isTrue);
    });

    test('isLowStock true when below minLevel', () {
      final m = makeIngredient(currentStock: 5, minLevel: 10);
      expect(m.isLowStock, isTrue);
    });

    test('isLowStock false when above minLevel', () {
      final m = makeIngredient(currentStock: 100, minLevel: 10);
      expect(m.isLowStock, isFalse);
    });

    test('isExpiringSoon true when expiry within days', () {
      final m = makeIngredient(
        expiryDate: DateTime.now().add(const Duration(days: 2)),
      );
      expect(m.isExpiringSoon(7), isTrue);
    });

    test('isExpiringSoon false when expiry far away', () {
      final m = makeIngredient(
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(m.isExpiringSoon(7), isFalse);
    });

    test('isExpiringSoon false when no expiryDate', () {
      final m = makeIngredient();
      expect(m.isExpiringSoon(7), isFalse);
    });

    test('copyWith sets updatedAt to now', () {
      final m = makeIngredient();
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final updated = m.copyWith(currentStock: 50);
      expect(updated.currentStock, 50);
      expect(updated.updatedAt, isNotNull);
      expect(updated.updatedAt!.isAfter(before), isTrue);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeIngredient(vendorName: 'Vendor A');
      final updated = m.copyWith();
      expect(updated.vendorName, 'Vendor A');
      expect(updated.name, m.name);
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeIngredient(
          vendorId: 'v1',
          vendorName: 'Vendor A',
          expiryDate: DateTime(2025, 6, 1),
          batchNumber: 'B001',
          maxLevel: 500,
        );
        final map = m.toFirestore();
        expect(map['name'], 'Test Flour');
        expect(map['unit'], 'kg');
        expect(map['currentStock'], 100.0);
        expect(map['vendorId'], 'v1');
        expect(map['batchNumber'], 'B001');
        expect(map['maxLevel'], 500.0);
        expect(map['expiryDate'], isA<Timestamp>());
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeIngredient(
          name: 'Sugar',
          unit: IngredientUnit.g,
          currentStock: 5000,
          minLevel: 500,
          costPerUnit: 40,
          vendorId: 'v1',
          vendorName: 'Sweet Vendor',
          expiryDate: DateTime(2025, 12, 1),
          batchNumber: 'B002',
        );
        await firestore
            .collection('ingredients')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('ingredients')
            .doc(original.id)
            .get();
        final restored = IngredientModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.name, 'Sugar');
        expect(restored.unit, IngredientUnit.g);
        expect(restored.currentStock, 5000);
        expect(restored.costPerUnit, 40);
        expect(restored.vendorName, 'Sweet Vendor');
        expect(restored.batchNumber, 'B002');
      });
    });
  });
}
