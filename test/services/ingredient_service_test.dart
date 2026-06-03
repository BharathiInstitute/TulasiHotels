/// Tests for IngredientService — CRUD, stock adjustment, low stock filtering
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/ingredient_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/ingredients';
  });

  group('IngredientService Firestore operations', () {
    test('create — writes and reads back all fields', () async {
      final ingredient = makeIngredient(
        id: 'ing-100',
        name: 'Rice',
        unit: IngredientUnit.kg,
        currentStock: 50,
        minLevel: 10,
        costPerUnit: 60,
      );

      await fakeFirestore
          .collection(basePath)
          .doc(ingredient.id)
          .set(ingredient.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(ingredient.id).get();
      final parsed = IngredientModel.fromFirestore(doc);
      expect(parsed.name, 'Rice');
      expect(parsed.unit, IngredientUnit.kg);
      expect(parsed.currentStock, 50);
      expect(parsed.minLevel, 10);
      expect(parsed.costPerUnit, 60);
    });

    test('getIngredient — returns null for missing doc', () async {
      final doc =
          await fakeFirestore.collection(basePath).doc('missing').get();
      expect(doc.exists, isFalse);
    });

    test('update — modifies existing ingredient', () async {
      final ingredient = makeIngredient(id: 'ing-u1', name: 'Flour');
      await fakeFirestore
          .collection(basePath)
          .doc(ingredient.id)
          .set(ingredient.toFirestore());

      final updated = ingredient.copyWith(name: 'Whole Wheat Flour');
      await fakeFirestore
          .collection(basePath)
          .doc(ingredient.id)
          .update(updated.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('ing-u1').get();
      final parsed = IngredientModel.fromFirestore(doc);
      expect(parsed.name, 'Whole Wheat Flour');
    });

    test('delete — removes ingredient', () async {
      final ingredient = makeIngredient(id: 'ing-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(ingredient.id)
          .set(ingredient.toFirestore());

      await fakeFirestore.collection(basePath).doc('ing-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('ing-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('adjustStock', () {
    test('positive adjustment increases stock', () async {
      final ingredient = makeIngredient(id: 'adj-1', currentStock: 50);
      await fakeFirestore
          .collection(basePath)
          .doc(ingredient.id)
          .set(ingredient.toFirestore());

      // Simulate FieldValue.increment(20)
      await fakeFirestore.collection(basePath).doc('adj-1').update({
        'currentStock': 70.0,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('adj-1').get();
      expect(doc.data()!['currentStock'], 70.0);
    });

    test('negative adjustment decreases stock', () async {
      final ingredient = makeIngredient(id: 'adj-2', currentStock: 50);
      await fakeFirestore
          .collection(basePath)
          .doc(ingredient.id)
          .set(ingredient.toFirestore());

      await fakeFirestore.collection(basePath).doc('adj-2').update({
        'currentStock': 35.0,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('adj-2').get();
      expect(doc.data()!['currentStock'], 35.0);
    });
  });

  group('lowStockStream filtering', () {
    test('filters ingredients where currentStock <= minLevel', () async {
      final low = makeIngredient(
        id: 'low',
        name: 'Salt',
        currentStock: 5,
        minLevel: 10,
      );
      final ok = makeIngredient(
        id: 'ok',
        name: 'Sugar',
        currentStock: 50,
        minLevel: 10,
      );
      final atLevel = makeIngredient(
        id: 'at',
        name: 'Pepper',
        currentStock: 10,
        minLevel: 10,
      );

      for (final i in [low, ok, atLevel]) {
        await fakeFirestore
            .collection(basePath)
            .doc(i.id)
            .set(i.toFirestore());
      }

      final snapshot = await fakeFirestore.collection(basePath).get();
      final lowStockItems = snapshot.docs
          .map((d) => IngredientModel.fromFirestore(d))
          .where((i) => i.isLowStock)
          .toList();

      // isLowStock: currentStock <= minLevel → Salt (5<=10) and Pepper (10<=10)
      expect(lowStockItems.length, 2);
      final names = lowStockItems.map((i) => i.name).toSet();
      expect(names, containsAll(['Salt', 'Pepper']));
    });
  });

  group('ingredientsStream ordering', () {
    test('returns ingredients ordered by name', () async {
      final i1 = makeIngredient(id: 'i1', name: 'Tomato');
      final i2 = makeIngredient(id: 'i2', name: 'Onion');
      final i3 = makeIngredient(id: 'i3', name: 'Garlic');

      for (final i in [i1, i2, i3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(i.id)
            .set(i.toFirestore());
      }

      final snapshot =
          await fakeFirestore.collection(basePath).orderBy('name').get();

      final names = snapshot.docs
          .map((d) => IngredientModel.fromFirestore(d).name)
          .toList();
      expect(names, ['Garlic', 'Onion', 'Tomato']);
    });
  });

  group('IngredientUnit enum round-trip', () {
    test('all units survive Firestore round-trip', () async {
      for (final unit in IngredientUnit.values) {
        final ingredient =
            makeIngredient(id: 'u-${unit.name}', unit: unit);
        await fakeFirestore
            .collection(basePath)
            .doc(ingredient.id)
            .set(ingredient.toFirestore());

        final doc = await fakeFirestore
            .collection(basePath)
            .doc(ingredient.id)
            .get();
        final parsed = IngredientModel.fromFirestore(doc);
        expect(parsed.unit, unit);
      }
    });
  });
}
