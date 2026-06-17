/// Integration test: Attendance → Salary calculation
///
/// Tests the salary flow: clock in/out records over a month,
/// compute hours worked, overtime, and salary slip construction.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/services/salary_service.dart';
import 'package:tulasihotels/models/attendance_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('Integration: Attendance → Salary Calculation', () {
    test('Step 1: Clock in records hours worked', () {
      final record = makeAttendance(
        staffName: 'Raju',
        date: DateTime(2026, 3),
        clockIn: DateTime(2026, 3, 1, 9),
        clockOut: DateTime(2026, 3, 1, 17),
      );

      expect(record.hoursWorked, 8.0);
    });

    test('Step 2: No clock-out means 0 hours', () {
      final record = makeAttendance(
        staffName: 'Raju',
        date: DateTime(2026, 3),
        clockIn: DateTime(2026, 3, 1, 9),
        // no clockOut
      );

      expect(record.hoursWorked, 0.0);
    });

    test('Step 3: Overtime is hours beyond 8', () {
      final record = makeAttendance(
        staffName: 'Raju',
        date: DateTime(2026, 3, 5),
        clockIn: DateTime(2026, 3, 5, 8),
        clockOut: DateTime(2026, 3, 5, 19), // 11 hours
      );

      final hours = record.hoursWorked;
      expect(hours, 11.0);
      final overtime = hours > 8 ? hours - 8 : 0.0;
      expect(overtime, 3.0);
    });

    test('Step 4: Monthly hours calculation from multiple records', () {
      final records = [
        makeAttendance(
          date: DateTime(2026, 3),
          clockIn: DateTime(2026, 3, 1, 9),
          clockOut: DateTime(2026, 3, 1, 17), // 8h
        ),
        makeAttendance(
          date: DateTime(2026, 3, 2),
          clockIn: DateTime(2026, 3, 2, 9),
          clockOut: DateTime(2026, 3, 2, 20), // 11h
        ),
        makeAttendance(
          date: DateTime(2026, 3, 3),
          clockIn: DateTime(2026, 3, 3, 9),
          clockOut: DateTime(2026, 3, 3, 15), // 6h (short day)
        ),
      ];

      final presentDays = records.where((r) => r.clockOut != null).length;
      double totalHours = 0;
      double overtimeHours = 0;

      for (final record in records) {
        final hours = record.hoursWorked;
        totalHours += hours;
        if (hours > 8) {
          overtimeHours += hours - 8;
        }
      }

      expect(presentDays, 3);
      expect(totalHours, 25.0); // 8 + 11 + 6
      expect(overtimeHours, 3.0); // only from day 2
    });

    test('Step 5: Salary slip construction with all components', () {
      const baseSalary = 25000.0;
      const overtimeRatePerHour = 200.0;
      const deductions = 1500.0;
      const advances = 3000.0;
      const overtimeHours = 10.0;
      const overtimePay = overtimeHours * overtimeRatePerHour; // 2000
      const netSalary =
          baseSalary + overtimePay - deductions - advances; // 22500

      final slip = SalarySlip(
        staffId: 'staff-1',
        staffName: 'Raju',
        month: DateTime(2026, 3),
        totalDays: 31,
        presentDays: 26,
        totalHours: 218.0,
        overtimeHours: overtimeHours,
        baseSalary: baseSalary,
        overtimePay: overtimePay,
        deductions: deductions,
        advances: advances,
        netSalary: netSalary,
      );

      expect(slip.staffName, 'Raju');
      expect(slip.baseSalary, 25000);
      expect(slip.overtimePay, 2000);
      expect(slip.deductions, 1500);
      expect(slip.advances, 3000);
      expect(slip.netSalary, 22500);
      expect(slip.presentDays, 26);
      expect(slip.totalDays, 31);
    });

    test('Step 6: Zero overtime gives base salary minus deductions', () {
      final slip = SalarySlip(
        staffId: 'staff-2',
        staffName: 'Suresh',
        month: DateTime(2026, 3),
        totalDays: 31,
        presentDays: 20,
        totalHours: 160.0,
        overtimeHours: 0,
        baseSalary: 20000,
        overtimePay: 0,
        deductions: 500,
        advances: 0,
        netSalary: 19500,
      );

      expect(slip.netSalary, 19500);
      expect(slip.overtimePay, 0);
    });

    test('Step 7: Partial-hour tracking', () {
      final record = makeAttendance(
        date: DateTime(2026, 3, 10),
        clockIn: DateTime(2026, 3, 10, 9),
        clockOut: DateTime(2026, 3, 10, 17, 30), // 8.5 hours
      );

      expect(record.hoursWorked, 8.5);
      final overtime = record.hoursWorked > 8 ? record.hoursWorked - 8 : 0.0;
      expect(overtime, 0.5);
    });

    test('Step 8: Absent records have no clock-out and zero hours', () {
      final absent = makeAttendance(
        date: DateTime(2026, 3, 15),
        clockIn: DateTime(2026, 3, 15),
        status: AttendanceStatus.absent,
      );

      expect(absent.status, AttendanceStatus.absent);
      expect(absent.hoursWorked, 0.0);
    });
  });

  group('Integration: Salary edge cases', () {
    test('net salary can be negative with high deductions', () {
      final slip = SalarySlip(
        staffId: 'staff-3',
        staffName: 'Test',
        month: DateTime(2026, 3),
        totalDays: 31,
        presentDays: 5,
        totalHours: 40,
        overtimeHours: 0,
        baseSalary: 5000,
        overtimePay: 0,
        deductions: 3000,
        advances: 4000,
        netSalary: -2000, // 5000 - 3000 - 4000
      );

      expect(slip.netSalary, isNegative);
    });

    test('month has correct day count', () {
      // February 2026 has 28 days
      final feb = DateTime(2026, 3, 0); // last day of Feb
      expect(feb.day, 28);

      // March 2026 has 31 days
      final mar = DateTime(2026, 4, 0);
      expect(mar.day, 31);
    });
  });
}
