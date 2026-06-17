/// Tests for ReservationService — lifecycle, availability, queries
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/reservation_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/reservations';
  });

  group('create and read back', () {
    test('writes and reads all fields', () async {
      final res = makeReservation(
        id: 'r-1',
        guestName: 'Amit Shah',
        phone: '9999999999',
        partySize: 6,
        tableId: 'table-5',
        dateTime: DateTime(2024, 12, 25, 19),
        specialRequests: 'Window seat',
      );

      await fakeFirestore
          .collection(basePath)
          .doc(res.id)
          .set(res.toFirestore());

      final doc = await fakeFirestore.collection(basePath).doc('r-1').get();
      final parsed = ReservationModel.fromFirestore(doc);
      expect(parsed.guestName, 'Amit Shah');
      expect(parsed.phone, '9999999999');
      expect(parsed.partySize, 6);
      expect(parsed.tableId, 'table-5');
      expect(parsed.specialRequests, 'Window seat');
      expect(parsed.status, ReservationStatus.pending);
    });
  });

  group('lifecycle transitions', () {
    test('pending → confirmed', () async {
      final res = makeReservation(id: 'r-lc');
      await fakeFirestore
          .collection(basePath)
          .doc(res.id)
          .set(res.toFirestore());

      await fakeFirestore.collection(basePath).doc('r-lc').update({
        'status': ReservationStatus.confirmed.name,
      });

      final doc = await fakeFirestore.collection(basePath).doc('r-lc').get();
      final parsed = ReservationModel.fromFirestore(doc);
      expect(parsed.status, ReservationStatus.confirmed);
    });

    test('confirmed → seated with table assignment', () async {
      final res = makeReservation(
        id: 'r-seat',
        status: ReservationStatus.confirmed,
      );
      await fakeFirestore
          .collection(basePath)
          .doc(res.id)
          .set(res.toFirestore());

      await fakeFirestore.collection(basePath).doc('r-seat').update({
        'status': ReservationStatus.seated.name,
        'tableId': 'table-3',
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('r-seat').get();
      final parsed = ReservationModel.fromFirestore(doc);
      expect(parsed.status, ReservationStatus.seated);
      expect(parsed.tableId, 'table-3');
    });

    test('cancel reservation', () async {
      final res = makeReservation(id: 'r-cancel');
      await fakeFirestore
          .collection(basePath)
          .doc(res.id)
          .set(res.toFirestore());

      await fakeFirestore.collection(basePath).doc('r-cancel').update({
        'status': ReservationStatus.cancelled.name,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('r-cancel').get();
      final parsed = ReservationModel.fromFirestore(doc);
      expect(parsed.status, ReservationStatus.cancelled);
    });

    test('mark no-show', () async {
      final res = makeReservation(id: 'r-noshow');
      await fakeFirestore
          .collection(basePath)
          .doc(res.id)
          .set(res.toFirestore());

      await fakeFirestore.collection(basePath).doc('r-noshow').update({
        'status': ReservationStatus.noShow.name,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('r-noshow').get();
      final parsed = ReservationModel.fromFirestore(doc);
      expect(parsed.status, ReservationStatus.noShow);
    });
  });

  group('isTableAvailable', () {
    test('returns empty when no conflicting reservations', () async {
      final dateTime = DateTime(2024, 12, 25, 19);
      final start = dateTime.subtract(const Duration(minutes: 90));
      final end = dateTime.add(const Duration(minutes: 90));

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('tableId', isEqualTo: 'table-1')
          .where('status', whereIn: ['pending', 'confirmed'])
          .where('dateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      expect(snapshot.docs.isEmpty, isTrue);
    });

    test('finds conflict within 90-min window', () async {
      final res = makeReservation(
        id: 'r-conflict',
        tableId: 'table-1',
        dateTime: DateTime(2024, 12, 25, 19, 30),
        status: ReservationStatus.confirmed,
      );
      await fakeFirestore
          .collection(basePath)
          .doc(res.id)
          .set(res.toFirestore());

      final checkTime = DateTime(2024, 12, 25, 19);
      final start = checkTime.subtract(const Duration(minutes: 90));
      final end = checkTime.add(const Duration(minutes: 90));

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('tableId', isEqualTo: 'table-1')
          .where('status', whereIn: ['pending', 'confirmed'])
          .where('dateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      expect(snapshot.docs.isNotEmpty, isTrue);
    });

    test('cancelled reservation does not block table', () async {
      final res = makeReservation(
        id: 'r-cancelled',
        tableId: 'table-2',
        dateTime: DateTime(2024, 12, 25, 19),
        status: ReservationStatus.cancelled,
      );
      await fakeFirestore
          .collection(basePath)
          .doc(res.id)
          .set(res.toFirestore());

      final checkTime = DateTime(2024, 12, 25, 19);
      final start = checkTime.subtract(const Duration(minutes: 90));
      final end = checkTime.add(const Duration(minutes: 90));

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('tableId', isEqualTo: 'table-2')
          .where('status', whereIn: ['pending', 'confirmed'])
          .where('dateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      expect(snapshot.docs.isEmpty, isTrue);
    });
  });

  group('delete', () {
    test('removes reservation', () async {
      final res = makeReservation(id: 'r-del');
      await fakeFirestore
          .collection(basePath)
          .doc(res.id)
          .set(res.toFirestore());

      await fakeFirestore.collection(basePath).doc('r-del').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('r-del').get();
      expect(doc.exists, isFalse);
    });
  });

  group('ReservationStatus round-trip', () {
    test('all statuses survive Firestore', () async {
      for (final status in ReservationStatus.values) {
        final res = makeReservation(
          id: 'rs-${status.name}',
          status: status,
        );
        await fakeFirestore
            .collection(basePath)
            .doc(res.id)
            .set(res.toFirestore());

        final doc =
            await fakeFirestore.collection(basePath).doc(res.id).get();
        final parsed = ReservationModel.fromFirestore(doc);
        expect(parsed.status, status);
      }
    });
  });

  group('ordering by dateTime', () {
    test('reservations sort chronologically', () async {
      final r1 = makeReservation(
        id: 'r-late',
        dateTime: DateTime(2024, 12, 25, 21),
      );
      final r2 = makeReservation(
        id: 'r-early',
        dateTime: DateTime(2024, 12, 25, 18),
      );
      final r3 = makeReservation(
        id: 'r-mid',
        dateTime: DateTime(2024, 12, 25, 19, 30),
      );

      for (final r in [r1, r2, r3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(r.id)
            .set(r.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .orderBy('dateTime')
          .get();

      final ids =
          snapshot.docs.map((d) => d.id).toList();
      expect(ids, ['r-early', 'r-mid', 'r-late']);
    });
  });
}
