import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/event_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('EventMenuItem', () {
    test('toMap serialises all fields', () {
      final item = makeEventMenuItem(quantity: 5);
      final map = item.toMap();
      expect(map['productId'], 'prod-1');
      expect(map['name'], 'Test Dish');
      expect(map['quantity'], 5);
    });

    test('fromMap deserialises correctly', () {
      final map = {'productId': 'p1', 'name': 'Biryani', 'quantity': 10};
      final item = EventMenuItem.fromMap(map);
      expect(item.productId, 'p1');
      expect(item.name, 'Biryani');
      expect(item.quantity, 10);
    });

    test('fromMap handles missing fields', () {
      final item = EventMenuItem.fromMap({});
      expect(item.productId, '');
      expect(item.name, '');
      expect(item.quantity, 1);
    });
  });

  group('EventModel', () {
    test('constructor defaults', () {
      final m = makeEvent();
      expect(m.guestCount, 50);
      expect(m.menu.length, 1);
    });

    test('balanceDue calculates correctly', () {
      final m = makeEvent();
      expect(m.balanceDue, 20000);
    });

    test('balanceDue is zero when fully paid', () {
      final m = makeEvent(advancePaid: 25000);
      expect(m.balanceDue, 0);
    });

    test('isUpcoming true for future event', () {
      final m = makeEvent(
        eventDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(m.isUpcoming, isTrue);
    });

    test('isUpcoming false for past event', () {
      final m = makeEvent(eventDate: DateTime(2020));
      expect(m.isUpcoming, isFalse);
    });

    group('Firestore round-trip', () {
      test('toFirestore serialises menu items', () {
        final m = makeEvent(
          menu: [
            makeEventMenuItem(),
            makeEventMenuItem(name: 'Dal', quantity: 3),
          ],
          specialInstructions: 'No onion',
        );
        final map = m.toFirestore();
        expect(map['eventName'], 'Test Event');
        expect((map['menu'] as List).length, 2);
        expect(map['specialInstructions'], 'No onion');
        expect(map['eventDate'], isA<Timestamp>());
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeEvent(
          clientName: 'Ravi',
          guestCount: 100,
          menu: [makeEventMenuItem(name: 'Biryani', quantity: 100)],
          perPlatePrice: 300,
          totalAmount: 30000,
          advancePaid: 10000,
          specialInstructions: 'Jain food table',
        );
        await firestore
            .collection('events')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore.collection('events').doc(original.id).get();
        final restored = EventModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.clientName, 'Ravi');
        expect(restored.guestCount, 100);
        expect(restored.menu.first.name, 'Biryani');
        expect(restored.totalAmount, 30000);
        expect(restored.advancePaid, 10000);
        expect(restored.balanceDue, 20000);
        expect(restored.specialInstructions, 'Jain food table');
      });
    });
  });
}
