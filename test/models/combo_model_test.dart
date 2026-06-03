import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/combo_model.dart';
import 'package:tulasihotels/models/product_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('ComboItem', () {
    test('toMap serialises all fields', () {
      final item = makeComboItem(isSwappable: true, swapOptions: ['p2', 'p3']);
      final map = item.toMap();
      expect(map['productId'], 'prod-1');
      expect(map['name'], 'Test Item');
      expect(map['quantity'], 1);
      expect(map['isSwappable'], true);
      expect(map['swapOptions'], ['p2', 'p3']);
    });

    test('toMap with null swapOptions', () {
      final map = makeComboItem().toMap();
      expect(map['swapOptions'], isNull);
    });

    test('fromMap deserialises correctly', () {
      final map = {
        'productId': 'p1',
        'name': 'Rice',
        'quantity': 2,
        'isSwappable': true,
        'swapOptions': ['p2'],
      };
      final item = ComboItem.fromMap(map);
      expect(item.productId, 'p1');
      expect(item.name, 'Rice');
      expect(item.quantity, 2);
      expect(item.isSwappable, true);
      expect(item.swapOptions, ['p2']);
    });

    test('fromMap handles missing fields', () {
      final item = ComboItem.fromMap({});
      expect(item.productId, '');
      expect(item.name, '');
      expect(item.quantity, 1);
      expect(item.isSwappable, false);
      expect(item.swapOptions, isNull);
    });
  });

  group('ComboModel', () {
    test('constructor defaults', () {
      final m = makeCombo();
      expect(m.isAvailable, true);
      expect(m.dietaryTag, DietaryTag.none);
      expect(m.items.length, 1);
    });

    test('copyWith updates name and price', () {
      final m = makeCombo();
      final updated = m.copyWith(name: 'New Combo', price: 300);
      expect(updated.name, 'New Combo');
      expect(updated.price, 300);
      expect(updated.id, m.id);
      expect(updated.createdAt, m.createdAt);
    });

    test('copyWith updates dietaryTag', () {
      final m = makeCombo();
      final updated = m.copyWith(dietaryTag: DietaryTag.veg);
      expect(updated.dietaryTag, DietaryTag.veg);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeCombo(description: 'Tasty', isAvailable: false);
      final updated = m.copyWith();
      expect(updated.description, 'Tasty');
      expect(updated.isAvailable, false);
    });

    group('Firestore round-trip', () {
      test('toFirestore serialises items and dietaryTag', () {
        final m = makeCombo(
          items: [
            makeComboItem(),
            makeComboItem(productId: 'p2', name: 'Dal'),
          ],
          dietaryTag: DietaryTag.veg,
        );
        final map = m.toFirestore();
        expect(map['name'], 'Test Combo');
        expect(map['dietaryTag'], 'veg');
        expect((map['items'] as List).length, 2);
        expect(map['createdAt'], isA<Timestamp>());
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeCombo(
          description: 'Full meal',
          items: [
            makeComboItem(productId: 'p1', name: 'Rice'),
            makeComboItem(
              productId: 'p2',
              name: 'Dal',
              isSwappable: true,
              swapOptions: ['p3'],
            ),
          ],
          dietaryTag: DietaryTag.veg,
        );
        await firestore
            .collection('combos')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore.collection('combos').doc(original.id).get();
        final restored = ComboModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.description, 'Full meal');
        expect(restored.price, original.price);
        expect(restored.items.length, 2);
        expect(restored.items[1].isSwappable, true);
        expect(restored.items[1].swapOptions, ['p3']);
        expect(restored.dietaryTag, DietaryTag.veg);
        expect(restored.isAvailable, true);
      });
    });
  });
}
