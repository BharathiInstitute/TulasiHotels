import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/reservation_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('ReservationStatus enum', () {
    test('displayName and emoji', () {
      expect(ReservationStatus.pending.displayName, 'Pending');
      expect(ReservationStatus.confirmed.displayName, 'Confirmed');
      expect(ReservationStatus.seated.displayName, 'Seated');
      expect(ReservationStatus.cancelled.displayName, 'Cancelled');
      expect(ReservationStatus.noShow.displayName, 'No Show');
    });

    test('fromString parses all values', () {
      for (final s in ReservationStatus.values) {
        expect(ReservationStatus.fromString(s.name), s);
      }
    });

    test('fromString defaults to pending', () {
      expect(ReservationStatus.fromString('xyz'), ReservationStatus.pending);
    });
  });

  group('ReservationModel', () {
    test('constructor defaults', () {
      final m = makeReservation();
      expect(m.status, ReservationStatus.pending);
      expect(m.durationMinutes, 90);
      expect(m.tableId, isNull);
    });

    test('copyWith updates status and tableId', () {
      final m = makeReservation();
      final updated = m.copyWith(
        status: ReservationStatus.confirmed,
        tableId: 'table-1',
      );
      expect(updated.status, ReservationStatus.confirmed);
      expect(updated.tableId, 'table-1');
      expect(updated.id, m.id);
      expect(updated.guestName, m.guestName);
    });

    test('copyWith sets updatedAt to now', () {
      final m = makeReservation();
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final updated = m.copyWith(partySize: 6);
      expect(updated.partySize, 6);
      expect(updated.updatedAt, isNotNull);
      expect(updated.updatedAt!.isAfter(before), isTrue);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeReservation(specialRequests: 'Window seat', partySize: 8);
      final updated = m.copyWith();
      expect(updated.specialRequests, 'Window seat');
      expect(updated.partySize, 8);
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeReservation(
          tableId: 't1',
          specialRequests: 'Anniversary',
          partySize: 6,
        );
        final map = m.toFirestore();
        expect(map['guestName'], 'Test Guest');
        expect(map['phone'], '9876543210');
        expect(map['partySize'], 6);
        expect(map['status'], 'pending');
        expect(map['durationMinutes'], 90);
        expect(map['specialRequests'], 'Anniversary');
        expect(map['tableId'], 't1');
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeReservation(
          guestName: 'Ravi Kumar',
          phone: '9999999999',
          tableId: 't1',
          status: ReservationStatus.confirmed,
          specialRequests: 'Birthday cake',
          durationMinutes: 120,
        );
        await firestore
            .collection('reservations')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('reservations')
            .doc(original.id)
            .get();
        final restored = ReservationModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.guestName, 'Ravi Kumar');
        expect(restored.phone, '9999999999');
        expect(restored.partySize, 4);
        expect(restored.status, ReservationStatus.confirmed);
        expect(restored.specialRequests, 'Birthday cake');
        expect(restored.durationMinutes, 120);
      });
    });
  });
}
