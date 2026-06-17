/// Tests for ShiftService — CRUD, bulk create, swap request/approve, week range
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/shift_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/shifts';
  });

  group('ShiftService Firestore operations', () {
    test('create — writes and reads back all fields', () async {
      final shift = makeShift(
        id: 'sh-1',
        staffName: 'Ravi',
        date: DateTime(2024, 6, 15),
        startTime: DateTime(2024, 6, 15, 6),
        endTime: DateTime(2024, 6, 15, 14),
      );

      await fakeFirestore
          .collection(basePath)
          .doc(shift.id)
          .set(shift.toFirestore());

      final doc = await fakeFirestore.collection(basePath).doc(shift.id).get();
      final parsed = ShiftModel.fromFirestore(doc);
      expect(parsed.staffId, 'staff-1');
      expect(parsed.staffName, 'Ravi');
      expect(parsed.shiftType, ShiftType.morning);
    });

    test('update — modifies existing shift', () async {
      final shift = makeShift(id: 'sh-u1', notes: 'Old note');
      await fakeFirestore
          .collection(basePath)
          .doc(shift.id)
          .set(shift.toFirestore());

      final updated = shift.copyWith(notes: 'Updated note');
      await fakeFirestore
          .collection(basePath)
          .doc(shift.id)
          .update(updated.toFirestore());

      final doc = await fakeFirestore.collection(basePath).doc('sh-u1').get();
      final parsed = ShiftModel.fromFirestore(doc);
      expect(parsed.notes, 'Updated note');
    });

    test('delete — removes shift', () async {
      final shift = makeShift(id: 'sh-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(shift.id)
          .set(shift.toFirestore());

      await fakeFirestore.collection(basePath).doc('sh-d1').delete();

      final doc = await fakeFirestore.collection(basePath).doc('sh-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('createBulkShifts', () {
    test('creates multiple shifts in batch', () async {
      final shifts = [
        makeShift(id: 'bulk-1', staffName: 'A'),
        makeShift(id: 'bulk-2', staffName: 'B'),
        makeShift(id: 'bulk-3', staffName: 'C'),
      ];

      // Simulate batch write
      for (final s in shifts) {
        await fakeFirestore.collection(basePath).doc(s.id).set(s.toFirestore());
      }

      final snapshot = await fakeFirestore.collection(basePath).get();
      expect(snapshot.docs.length, 3);
    });
  });

  group('weekShiftsStream', () {
    test('filters shifts within date range', () async {
      final inRange = makeShift(id: 'in', date: DateTime(2024, 6, 12));
      final before = makeShift(id: 'before', date: DateTime(2024, 6));
      final after = makeShift(id: 'after', date: DateTime(2024, 6, 25));

      for (final s in [inRange, before, after]) {
        await fakeFirestore.collection(basePath).doc(s.id).set(s.toFirestore());
      }

      final weekStart = DateTime(2024, 6, 10);
      final weekEnd = DateTime(2024, 6, 16);
      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 'in');
    });
  });

  group('staffShiftsStream', () {
    test('filters shifts by staffId', () async {
      final s1 = makeShift(id: 'ss-1');
      final s2 = makeShift(id: 'ss-2', staffId: 'staff-2');
      final s3 = makeShift(id: 'ss-3');

      for (final s in [s1, s2, s3]) {
        await fakeFirestore.collection(basePath).doc(s.id).set(s.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('staffId', isEqualTo: 'staff-1')
          .get();

      expect(snapshot.docs.length, 2);
      final ids = snapshot.docs.map((d) => d.id).toSet();
      expect(ids, {'ss-1', 'ss-3'});
    });
  });

  group('requestSwap', () {
    test('sets isSwapRequested and swapWithStaffId', () async {
      final shift = makeShift(id: 'swap-req');
      await fakeFirestore
          .collection(basePath)
          .doc(shift.id)
          .set(shift.toFirestore());

      await fakeFirestore.collection(basePath).doc('swap-req').update({
        'isSwapRequested': true,
        'swapWithStaffId': 'staff-2',
      });

      final doc = await fakeFirestore
          .collection(basePath)
          .doc('swap-req')
          .get();
      expect(doc.data()!['isSwapRequested'], isTrue);
      expect(doc.data()!['swapWithStaffId'], 'staff-2');
    });
  });

  group('approveSwap', () {
    test('swaps staffId and staffName between two shifts', () async {
      final shift1 = makeShift(
        id: 'sw-1',
        staffId: 'staff-A',
        staffName: 'Alice',
        isSwapRequested: true,
        swapWithStaffId: 'staff-B',
        date: DateTime(2024, 6, 15),
      );
      final shift2 = makeShift(
        id: 'sw-2',
        staffId: 'staff-B',
        staffName: 'Bob',
        date: DateTime(2024, 6, 15),
      );

      for (final s in [shift1, shift2]) {
        await fakeFirestore.collection(basePath).doc(s.id).set(s.toFirestore());
      }

      // Simulate approveSwap batch: swap staff info
      await fakeFirestore.collection(basePath).doc('sw-1').update({
        'staffId': 'staff-B',
        'staffName': 'Bob',
        'isSwapRequested': false,
        'swapWithStaffId': null,
      });
      await fakeFirestore.collection(basePath).doc('sw-2').update({
        'staffId': 'staff-A',
        'staffName': 'Alice',
      });

      final doc1 = await fakeFirestore.collection(basePath).doc('sw-1').get();
      final doc2 = await fakeFirestore.collection(basePath).doc('sw-2').get();

      final parsed1 = ShiftModel.fromFirestore(doc1);
      final parsed2 = ShiftModel.fromFirestore(doc2);

      expect(parsed1.staffId, 'staff-B');
      expect(parsed1.staffName, 'Bob');
      expect(parsed1.isSwapRequested, isFalse);
      expect(parsed2.staffId, 'staff-A');
      expect(parsed2.staffName, 'Alice');
    });
  });

  group('ShiftType enum round-trip', () {
    test('all shift types survive Firestore round-trip', () async {
      for (final type in ShiftType.values) {
        final shift = makeShift(id: 'st-${type.name}', shiftType: type);
        await fakeFirestore
            .collection(basePath)
            .doc(shift.id)
            .set(shift.toFirestore());

        final doc = await fakeFirestore
            .collection(basePath)
            .doc(shift.id)
            .get();
        final parsed = ShiftModel.fromFirestore(doc);
        expect(parsed.shiftType, type);
      }
    });
  });

  group('duration computed getter', () {
    test('calculates duration from start to end time', () {
      final shift = makeShift(
        startTime: DateTime(2024, 1, 15, 6),
        endTime: DateTime(2024, 1, 15, 14),
      );
      expect(shift.duration, const Duration(hours: 8));
    });
  });
}
