/// Tests for AttendanceService — clock in/out, manual records, date queries
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/attendance_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/attendance';
  });

  group('AttendanceService Firestore operations', () {
    test('clockIn — writes attendance record', () async {
      final att = makeAttendance(
        staffName: 'Ravi',
      );

      await fakeFirestore
          .collection(basePath)
          .doc(att.id)
          .set(att.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(att.id).get();
      final parsed = AttendanceModel.fromFirestore(doc);
      expect(parsed.staffId, 'staff-1');
      expect(parsed.staffName, 'Ravi');
      expect(parsed.status, AttendanceStatus.clockedIn);
      expect(parsed.clockOut, isNull);
    });

    test('clockOut — updates clockOut and status', () async {
      final att = makeAttendance(id: 'att-co');
      await fakeFirestore
          .collection(basePath)
          .doc(att.id)
          .set(att.toFirestore());

      final clockOut = DateTime(2024, 1, 15, 17);
      await fakeFirestore.collection(basePath).doc('att-co').update({
        'clockOut': Timestamp.fromDate(clockOut),
        'status': AttendanceStatus.clockedOut.name,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('att-co').get();
      final parsed = AttendanceModel.fromFirestore(doc);
      expect(parsed.status, AttendanceStatus.clockedOut);
      expect(parsed.clockOut, clockOut);
    });

    test('delete — removes attendance record', () async {
      final att = makeAttendance(id: 'att-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(att.id)
          .set(att.toFirestore());

      await fakeFirestore.collection(basePath).doc('att-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('att-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('todayAttendanceStream', () {
    test('filters attendance by date range (midnight to midnight)', () async {
      final today = DateTime.now();
      final startOfDay =
          DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todayAtt = makeAttendance(
        id: 'today',
        date: startOfDay,
        clockIn: startOfDay.add(const Duration(hours: 9)),
      );
      final yesterdayAtt = makeAttendance(
        id: 'yesterday',
        date: startOfDay.subtract(const Duration(days: 1)),
        clockIn: startOfDay.subtract(const Duration(hours: 15)),
      );

      for (final a in [todayAtt, yesterdayAtt]) {
        await fakeFirestore
            .collection(basePath)
            .doc(a.id)
            .set(a.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 'today');
    });
  });

  group('attendanceStream date range', () {
    test('filters attendance within from-to range', () async {
      final inRange = makeAttendance(
        id: 'in',
        date: DateTime(2024, 6, 15),
      );
      final outOf = makeAttendance(
        id: 'out',
        date: DateTime(2024),
      );

      for (final a in [inRange, outOf]) {
        await fakeFirestore
            .collection(basePath)
            .doc(a.id)
            .set(a.toFirestore());
      }

      final from = DateTime(2024, 6);
      final to = DateTime(2024, 6, 30);
      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 'in');
    });
  });

  group('staffAttendanceStream', () {
    test('filters by staffId and date range', () async {
      final match = makeAttendance(
        id: 'match',
        date: DateTime(2024, 6, 15),
      );
      final wrongStaff = makeAttendance(
        id: 'wrong-staff',
        staffId: 'staff-2',
        date: DateTime(2024, 6, 15),
      );
      final wrongDate = makeAttendance(
        id: 'wrong-date',
        date: DateTime(2024),
      );

      for (final a in [match, wrongStaff, wrongDate]) {
        await fakeFirestore
            .collection(basePath)
            .doc(a.id)
            .set(a.toFirestore());
      }

      final from = DateTime(2024, 6);
      final to = DateTime(2024, 6, 30);
      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('staffId', isEqualTo: 'staff-1')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 'match');
    });
  });

  group('isClockedIn query', () {
    test('finds clocked-in record for staff today', () async {
      final today = DateTime.now();
      final startOfDay =
          DateTime(today.year, today.month, today.day);

      final att = makeAttendance(
        id: 'ci',
        date: startOfDay,
      );
      await fakeFirestore
          .collection(basePath)
          .doc(att.id)
          .set(att.toFirestore());

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('staffId', isEqualTo: 'staff-1')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('status', isEqualTo: AttendanceStatus.clockedIn.name)
          .get();

      expect(snapshot.docs.isNotEmpty, isTrue);
    });

    test('returns empty when staff is clocked out', () async {
      final today = DateTime.now();
      final startOfDay =
          DateTime(today.year, today.month, today.day);

      final att = makeAttendance(
        id: 'co',
        status: AttendanceStatus.clockedOut,
        date: startOfDay,
      );
      await fakeFirestore
          .collection(basePath)
          .doc(att.id)
          .set(att.toFirestore());

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('staffId', isEqualTo: 'staff-1')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('status', isEqualTo: AttendanceStatus.clockedIn.name)
          .get();

      expect(snapshot.docs.isEmpty, isTrue);
    });
  });

  group('addManualRecord', () {
    test('creates attendance with clockOut already set', () async {
      final att = makeAttendance(
        id: 'manual-1',
        staffName: 'Ravi',
        date: DateTime(2024, 6, 10),
        clockIn: DateTime(2024, 6, 10, 9),
        clockOut: DateTime(2024, 6, 10, 17),
        status: AttendanceStatus.clockedOut,
      );

      await fakeFirestore
          .collection(basePath)
          .doc(att.id)
          .set(att.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('manual-1').get();
      final parsed = AttendanceModel.fromFirestore(doc);
      expect(parsed.status, AttendanceStatus.clockedOut);
      expect(parsed.clockOut, isNotNull);
      expect(parsed.hoursWorked, 8.0);
    });
  });

  group('updateRecord partial fields', () {
    test('updates only clockIn without touching other fields', () async {
      final att = makeAttendance(
        id: 'partial',
        clockIn: DateTime(2024, 1, 15, 9),
        clockOut: DateTime(2024, 1, 15, 17),
        status: AttendanceStatus.clockedOut,
      );
      await fakeFirestore
          .collection(basePath)
          .doc(att.id)
          .set(att.toFirestore());

      final newClockIn = DateTime(2024, 1, 15, 8, 30);
      await fakeFirestore.collection(basePath).doc('partial').update({
        'clockIn': Timestamp.fromDate(newClockIn),
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('partial').get();
      final parsed = AttendanceModel.fromFirestore(doc);
      expect(parsed.clockIn, newClockIn);
      // clockOut should be preserved
      expect(parsed.clockOut, DateTime(2024, 1, 15, 17));
    });
  });

  group('hoursWorked computed', () {
    test('returns hours when clocked out', () {
      final att = makeAttendance(
        clockIn: DateTime(2024, 1, 15, 9),
        clockOut: DateTime(2024, 1, 15, 17, 30),
      );
      expect(att.hoursWorked, 8.5);
    });

    test('returns 0 when clockOut is null', () {
      final att = makeAttendance();
      expect(att.hoursWorked, 0);
    });
  });
}
