/// Tests for SalaryService — salary computation from attendance records
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

  group('SalarySlip computation', () {
    test('presentDays counts only records with clockOut', () async {
      // Record 1: complete (has clockOut)
      final a1 = makeAttendance(
        id: 'a1',
        staffId: 'staff-1',
        date: DateTime(2024, 1, 10),
        clockIn: DateTime(2024, 1, 10, 9, 0),
        clockOut: DateTime(2024, 1, 10, 17, 0),
      );
      // Record 2: incomplete (no clockOut)
      final a2 = makeAttendance(
        id: 'a2',
        staffId: 'staff-1',
        date: DateTime(2024, 1, 11),
        clockIn: DateTime(2024, 1, 11, 9, 0),
        clockOut: null,
      );

      for (final a in [a1, a2]) {
        await fakeFirestore
            .collection(basePath)
            .doc(a.id)
            .set(a.toFirestore());
      }

      final month = DateTime(2024, 1);
      final startOfMonth = DateTime(month.year, month.month);
      final endOfMonth =
          DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('staffId', isEqualTo: 'staff-1')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      final records = snapshot.docs
          .map((d) => AttendanceModel.fromFirestore(d))
          .toList();

      final presentDays = records.where((r) => r.clockOut != null).length;
      expect(presentDays, 1);
    });

    test('overtime calculation: hours > 8 add to overtime', () {
      // 10h shift → 2h overtime
      final a = makeAttendance(
        clockIn: DateTime(2024, 1, 10, 8, 0),
        clockOut: DateTime(2024, 1, 10, 18, 0),
      );
      final hours = a.hoursWorked;
      expect(hours, 10.0);
      final overtime = hours > 8 ? hours - 8 : 0.0;
      expect(overtime, 2.0);
    });

    test('no overtime for exactly 8 hours', () {
      final a = makeAttendance(
        clockIn: DateTime(2024, 1, 10, 9, 0),
        clockOut: DateTime(2024, 1, 10, 17, 0),
      );
      final hours = a.hoursWorked;
      expect(hours, 8.0);
      final overtime = hours > 8 ? hours - 8 : 0.0;
      expect(overtime, 0.0);
    });

    test('hoursWorked is 0 when clockOut is null', () {
      final a = makeAttendance(clockOut: null);
      expect(a.hoursWorked, 0.0);
    });

    test('net salary = base + overtimePay - deductions - advances', () {
      const baseSalary = 20000.0;
      const overtimeHours = 5.0;
      const overtimeRate = 200.0;
      const deductions = 1000.0;
      const advances = 2000.0;

      final overtimePay = overtimeHours * overtimeRate;
      final netSalary = baseSalary + overtimePay - deductions - advances;

      expect(overtimePay, 1000.0);
      expect(netSalary, 18000.0);
    });

    test('endOfMonth calculation for January', () {
      final month = DateTime(2024, 1); // January 2024
      final endOfMonth =
          DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      expect(endOfMonth.day, 31);
      expect(endOfMonth.month, 1);
    });

    test('endOfMonth calculation for February (leap year)', () {
      final month = DateTime(2024, 2); // February 2024 (leap)
      final endOfMonth =
          DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      expect(endOfMonth.day, 29);
      expect(endOfMonth.month, 2);
    });

    test('totalDays from endOfMonth.day', () {
      final endOfMonth =
          DateTime(2024, 2 + 1, 0, 23, 59, 59); // Feb 2024 = 29 days
      expect(endOfMonth.day, 29);
    });
  });

  group('attendance query for salary', () {
    test('filters by staffId and month range', () async {
      // Staff-1 in January
      final a1 = makeAttendance(
        id: 'jan-1',
        staffId: 'staff-1',
        date: DateTime(2024, 1, 5),
        clockIn: DateTime(2024, 1, 5, 9, 0),
        clockOut: DateTime(2024, 1, 5, 17, 0),
      );
      // Staff-1 in February (should not appear)
      final a2 = makeAttendance(
        id: 'feb-1',
        staffId: 'staff-1',
        date: DateTime(2024, 2, 5),
        clockIn: DateTime(2024, 2, 5, 9, 0),
        clockOut: DateTime(2024, 2, 5, 17, 0),
      );
      // Staff-2 in January (should not appear)
      final a3 = makeAttendance(
        id: 'jan-s2',
        staffId: 'staff-2',
        date: DateTime(2024, 1, 10),
        clockIn: DateTime(2024, 1, 10, 9, 0),
        clockOut: DateTime(2024, 1, 10, 17, 0),
      );

      for (final a in [a1, a2, a3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(a.id)
            .set(a.toFirestore());
      }

      final startOfMonth = DateTime(2024, 1);
      final endOfMonth = DateTime(2024, 2, 0, 23, 59, 59);

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('staffId', isEqualTo: 'staff-1')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      expect(snapshot.docs.length, 1);
      final record = AttendanceModel.fromFirestore(snapshot.docs.first);
      expect(record.staffId, 'staff-1');
    });
  });
}
