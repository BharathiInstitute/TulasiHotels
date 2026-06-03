import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/ingredient_model.dart';
import 'package:tulasihotels/models/wastage_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('WastageReason enum', () {
    test('fromString parses all values', () {
      for (final r in WastageReason.values) {
        expect(WastageReason.fromString(r.name), r);
      }
    });

    test('fromString defaults to other', () {
      expect(WastageReason.fromString('xyz'), WastageReason.other);
    });
  });

  group('WastageModel', () {
    test('constructor defaults', () {
      final m = makeWastage();
      expect(m.unit, IngredientUnit.kg);
      expect(m.reason, WastageReason.other);
      expect(m.estimatedCost, 250.0);
      expect(m.loggedBy, isNull);
    });

    test('copyWith updates reason and quantity', () {
      final m = makeWastage();
      final updated = m.copyWith(reason: WastageReason.expired, quantity: 10);
      expect(updated.reason, WastageReason.expired);
      expect(updated.quantity, 10);
      expect(updated.id, m.id);
    });

    test('copyWith updates unit', () {
      final m = makeWastage();
      final updated = m.copyWith(unit: IngredientUnit.liter);
      expect(updated.unit, IngredientUnit.liter);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeWastage(notes: 'Power outage', loggedBy: 'staff-1');
      final updated = m.copyWith();
      expect(updated.notes, 'Power outage');
      expect(updated.loggedBy, 'staff-1');
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeWastage(
          reason: WastageReason.spoiled,
          notes: 'Fridge malfunction',
          loggedBy: 'staff-1',
        );
        final map = m.toFirestore();
        expect(map['ingredientId'], 'ing-1');
        expect(map['ingredientName'], 'Test Flour');
        expect(map['quantity'], 5.0);
        expect(map['unit'], 'kg');
        expect(map['reason'], 'spoiled');
        expect(map['notes'], 'Fridge malfunction');
        expect(map['loggedBy'], 'staff-1');
        expect(map['estimatedCost'], 250.0);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeWastage(
          ingredientName: 'Milk',
          quantity: 20,
          unit: IngredientUnit.liter,
          reason: WastageReason.expired,
          notes: 'Past expiry',
          estimatedCost: 800,
          loggedBy: 'staff-2',
        );
        await firestore
            .collection('wastage')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('wastage')
            .doc(original.id)
            .get();
        final restored = WastageModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.ingredientName, 'Milk');
        expect(restored.quantity, 20);
        expect(restored.unit, IngredientUnit.liter);
        expect(restored.reason, WastageReason.expired);
        expect(restored.notes, 'Past expiry');
        expect(restored.estimatedCost, 800);
        expect(restored.loggedBy, 'staff-2');
      });
    });
  });
}
