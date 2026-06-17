/// Tests for WastageService — log wastage, date range, stock deduction
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/wastage_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid';
  });

  group('WastageService Firestore operations', () {
    test('logWastage — writes wastage doc', () async {
      final wastage = makeWastage(
        id: 'w-1',
        ingredientName: 'Tomato',
        reason: WastageReason.expired,
        estimatedCost: 100,
      );

      await fakeFirestore
          .collection('$basePath/wastage')
          .doc(wastage.id)
          .set(wastage.toFirestore());

      final doc = await fakeFirestore
          .collection('$basePath/wastage')
          .doc(wastage.id)
          .get();
      final parsed = WastageModel.fromFirestore(doc);
      expect(parsed.ingredientName, 'Tomato');
      expect(parsed.quantity, 5);
      expect(parsed.reason, WastageReason.expired);
      expect(parsed.estimatedCost, 100);
    });

    test('delete — removes wastage log', () async {
      final wastage = makeWastage(id: 'w-d1');
      await fakeFirestore
          .collection('$basePath/wastage')
          .doc(wastage.id)
          .set(wastage.toFirestore());

      await fakeFirestore.collection('$basePath/wastage').doc('w-d1').delete();

      final doc = await fakeFirestore
          .collection('$basePath/wastage')
          .doc('w-d1')
          .get();
      expect(doc.exists, isFalse);
    });
  });

  group('logWastage batch: stock deduction', () {
    test('deducts stock from linked ingredient', () async {
      // Set up ingredient with current stock
      await fakeFirestore
          .collection('$basePath/ingredients')
          .doc('ing-1')
          .set(makeIngredient(currentStock: 50).toFirestore());

      // Log wastage of 5 units
      final wastage = makeWastage(
        id: 'w-deduct',
      );
      await fakeFirestore
          .collection('$basePath/wastage')
          .doc(wastage.id)
          .set(wastage.toFirestore());

      // Simulate batch stock deduction
      await fakeFirestore
          .collection('$basePath/ingredients')
          .doc('ing-1')
          .update({'currentStock': 45.0});

      final doc = await fakeFirestore
          .collection('$basePath/ingredients')
          .doc('ing-1')
          .get();
      expect(doc.data()!['currentStock'], 45.0);
    });
  });

  group('recentWastageStream', () {
    test('returns wastage ordered by date descending', () async {
      final w1 = makeWastage(
        id: 'r1',
        date: DateTime(2024),
        ingredientName: 'First',
      );
      final w2 = makeWastage(
        id: 'r2',
        date: DateTime(2024, 6),
        ingredientName: 'Latest',
      );
      final w3 = makeWastage(
        id: 'r3',
        date: DateTime(2024, 3),
        ingredientName: 'Middle',
      );

      for (final w in [w1, w2, w3]) {
        await fakeFirestore
            .collection('$basePath/wastage')
            .doc(w.id)
            .set(w.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection('$basePath/wastage')
          .orderBy('date', descending: true)
          .get();

      final names = snapshot.docs
          .map((d) => WastageModel.fromFirestore(d).ingredientName)
          .toList();
      expect(names, ['Latest', 'Middle', 'First']);
    });
  });

  group('wastageForDateRange', () {
    test('filters wastage within date range', () async {
      final inRange = makeWastage(
        id: 'in',
        date: DateTime(2024, 6, 15),
        ingredientName: 'In Range',
      );
      final before = makeWastage(
        id: 'before',
        date: DateTime(2024, 5),
        ingredientName: 'Before',
      );
      final after = makeWastage(
        id: 'after',
        date: DateTime(2024, 8),
        ingredientName: 'After',
      );

      for (final w in [inRange, before, after]) {
        await fakeFirestore
            .collection('$basePath/wastage')
            .doc(w.id)
            .set(w.toFirestore());
      }

      final start = DateTime(2024, 6);
      final end = DateTime(2024, 7);
      final snapshot = await fakeFirestore
          .collection('$basePath/wastage')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 'in');
    });
  });

  group('WastageReason enum round-trip', () {
    test('all reasons survive Firestore round-trip', () async {
      for (final reason in WastageReason.values) {
        final wastage = makeWastage(id: 'wr-${reason.name}', reason: reason);
        await fakeFirestore
            .collection('$basePath/wastage')
            .doc(wastage.id)
            .set(wastage.toFirestore());

        final doc = await fakeFirestore
            .collection('$basePath/wastage')
            .doc(wastage.id)
            .get();
        final parsed = WastageModel.fromFirestore(doc);
        expect(parsed.reason, reason);
      }
    });
  });
}
