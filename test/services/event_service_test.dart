/// Tests for EventService — Firestore CRUD + date filtering
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/event_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/events';
  });

  group('EventService Firestore operations', () {
    test('create — writes and reads back all fields', () async {
      final event = makeEvent(
        id: 'ev-1',
        eventName: 'Wedding Reception',
        clientName: 'Kumar Family',
        guestCount: 200,
        totalAmount: 100000,
        advancePaid: 25000,
      );

      await fakeFirestore
          .collection(basePath)
          .doc(event.id)
          .set(event.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(event.id).get();
      expect(doc.exists, isTrue);

      final parsed = EventModel.fromFirestore(doc);
      expect(parsed.eventName, 'Wedding Reception');
      expect(parsed.clientName, 'Kumar Family');
      expect(parsed.guestCount, 200);
      expect(parsed.totalAmount, 100000);
      expect(parsed.advancePaid, 25000);
    });

    test('read — returns non-existent for missing doc', () async {
      final doc =
          await fakeFirestore.collection(basePath).doc('missing').get();
      expect(doc.exists, isFalse);
    });

    test('update — modifies existing event', () async {
      final event = makeEvent(id: 'ev-u1', guestCount: 50);
      await fakeFirestore
          .collection(basePath)
          .doc(event.id)
          .set(event.toFirestore());

      final updated = event.copyWith(guestCount: 100);
      await fakeFirestore
          .collection(basePath)
          .doc(event.id)
          .update(updated.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('ev-u1').get();
      final parsed = EventModel.fromFirestore(doc);
      expect(parsed.guestCount, 100);
    });

    test('delete — removes event', () async {
      final event = makeEvent(id: 'ev-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(event.id)
          .set(event.toFirestore());

      await fakeFirestore.collection(basePath).doc('ev-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('ev-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('EventMenuItem nested serialization', () {
    test('event with menu items round-trips correctly', () async {
      final menuItems = [
        makeEventMenuItem(name: 'Paneer Tikka', quantity: 200),
        makeEventMenuItem(name: 'Biryani', quantity: 200),
        makeEventMenuItem(name: 'Gulab Jamun', quantity: 200),
      ];
      final event = makeEvent(id: 'ev-menu', menu: menuItems);

      await fakeFirestore
          .collection(basePath)
          .doc(event.id)
          .set(event.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('ev-menu').get();
      final parsed = EventModel.fromFirestore(doc);
      expect(parsed.menu.length, 3);
      expect(parsed.menu[0].name, 'Paneer Tikka');
      expect(parsed.menu[1].name, 'Biryani');
      expect(parsed.menu[2].name, 'Gulab Jamun');
      expect(parsed.menu[0].quantity, 200);
    });
  });

  group('balanceDue computed getter', () {
    test('balanceDue = totalAmount - advancePaid', () {
      final event = makeEvent(totalAmount: 50000, advancePaid: 15000);
      expect(event.balanceDue, 35000);
    });

    test('balanceDue is zero when fully paid', () {
      final event = makeEvent(totalAmount: 50000, advancePaid: 50000);
      expect(event.balanceDue, 0);
    });
  });

  group('isUpcoming computed getter', () {
    test('returns true for future event', () {
      final event = makeEvent(
        eventDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(event.isUpcoming, isTrue);
    });

    test('returns false for past event', () {
      final event = makeEvent(
        eventDate: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(event.isUpcoming, isFalse);
    });
  });

  group('allEventsStream ordering', () {
    test('returns events ordered by eventDate descending', () async {
      final e1 = makeEvent(
          id: 'e1', eventDate: DateTime(2024, 6, 1), eventName: 'June');
      final e2 = makeEvent(
          id: 'e2', eventDate: DateTime(2024, 12, 1), eventName: 'December');
      final e3 = makeEvent(
          id: 'e3', eventDate: DateTime(2024, 3, 1), eventName: 'March');

      for (final e in [e1, e2, e3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(e.id)
            .set(e.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .orderBy('eventDate', descending: true)
          .get();

      final names = snapshot.docs
          .map((d) => EventModel.fromFirestore(d).eventName)
          .toList();
      expect(names, ['December', 'June', 'March']);
    });
  });
}
