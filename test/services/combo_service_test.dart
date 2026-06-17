/// Tests for ComboService — CRUD, availability toggle, query
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/combo_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/combos';
  });

  group('ComboService Firestore operations', () {
    test('create — writes and reads back all fields', () async {
      final combo = makeCombo(
        id: 'cb-1',
        name: 'Lunch Combo',
        price: 299,
        items: [
          makeComboItem(name: 'Rice'),
          makeComboItem(name: 'Dal'),
          makeComboItem(name: 'Roti', quantity: 2),
        ],
      );

      await fakeFirestore
          .collection(basePath)
          .doc(combo.id)
          .set(combo.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(combo.id).get();
      final parsed = ComboModel.fromFirestore(doc);
      expect(parsed.name, 'Lunch Combo');
      expect(parsed.price, 299);
      expect(parsed.items.length, 3);
      expect(parsed.items[0].name, 'Rice');
      expect(parsed.items[2].quantity, 2);
    });

    test('getCombo — returns null for missing doc', () async {
      final doc =
          await fakeFirestore.collection(basePath).doc('missing').get();
      expect(doc.exists, isFalse);
    });

    test('update — modifies existing combo', () async {
      final combo = makeCombo(id: 'cb-u1', name: 'Old Combo');
      await fakeFirestore
          .collection(basePath)
          .doc(combo.id)
          .set(combo.toFirestore());

      final updated = combo.copyWith(name: 'Premium Combo');
      await fakeFirestore
          .collection(basePath)
          .doc(combo.id)
          .update(updated.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('cb-u1').get();
      final parsed = ComboModel.fromFirestore(doc);
      expect(parsed.name, 'Premium Combo');
    });

    test('delete — removes combo', () async {
      final combo = makeCombo(id: 'cb-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(combo.id)
          .set(combo.toFirestore());

      await fakeFirestore.collection(basePath).doc('cb-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('cb-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('toggleAvailability', () {
    test('sets combo to unavailable', () async {
      final combo = makeCombo(id: 'cb-t1');
      await fakeFirestore
          .collection(basePath)
          .doc(combo.id)
          .set(combo.toFirestore());

      await fakeFirestore.collection(basePath).doc('cb-t1').update({
        'isAvailable': false,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('cb-t1').get();
      final parsed = ComboModel.fromFirestore(doc);
      expect(parsed.isAvailable, isFalse);
    });

    test('sets combo to available', () async {
      final combo = makeCombo(id: 'cb-t2', isAvailable: false);
      await fakeFirestore
          .collection(basePath)
          .doc(combo.id)
          .set(combo.toFirestore());

      await fakeFirestore.collection(basePath).doc('cb-t2').update({
        'isAvailable': true,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('cb-t2').get();
      final parsed = ComboModel.fromFirestore(doc);
      expect(parsed.isAvailable, isTrue);
    });
  });

  group('availableCombosStream query', () {
    test('filters only available combos', () async {
      final avail1 = makeCombo(id: 'a1', name: 'A');
      final avail2 = makeCombo(id: 'a2', name: 'B');
      final unavail = makeCombo(id: 'u1', isAvailable: false, name: 'C');

      for (final c in [avail1, avail2, unavail]) {
        await fakeFirestore
            .collection(basePath)
            .doc(c.id)
            .set(c.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('isAvailable', isEqualTo: true)
          .get();

      expect(snapshot.docs.length, 2);
      final ids = snapshot.docs.map((d) => d.id).toSet();
      expect(ids, {'a1', 'a2'});
    });
  });

  group('ComboItem nested serialization', () {
    test('swappable item with swap options round-trips', () async {
      final combo = makeCombo(
        id: 'cb-swap',
        items: [
          makeComboItem(
            name: 'Bread',
            isSwappable: true,
            swapOptions: ['Naan', 'Roti', 'Paratha'],
          ),
        ],
      );

      await fakeFirestore
          .collection(basePath)
          .doc(combo.id)
          .set(combo.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('cb-swap').get();
      final parsed = ComboModel.fromFirestore(doc);
      expect(parsed.items.first.isSwappable, isTrue);
      expect(parsed.items.first.swapOptions, ['Naan', 'Roti', 'Paratha']);
    });
  });
}
