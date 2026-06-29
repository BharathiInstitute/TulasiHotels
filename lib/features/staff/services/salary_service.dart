/// Salary calculation service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/attendance_model.dart';

class SalarySlip {
  final String staffId;
  final String staffName;
  final DateTime month;
  final int totalDays;
  final int presentDays;
  final double totalHours;
  final double overtimeHours;
  final double baseSalary;
  final double overtimePay;
  final double deductions;
  final double advances;
  final double netSalary;

  const SalarySlip({
    required this.staffId,
    required this.staffName,
    required this.month,
    required this.totalDays,
    required this.presentDays,
    required this.totalHours,
    required this.overtimeHours,
    required this.baseSalary,
    required this.overtimePay,
    required this.deductions,
    required this.advances,
    required this.netSalary,
  });
}

class SalaryService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  /// Calculate salary for a staff member for a given month
  static Future<SalarySlip> calculateSalary({
    required String staffId,
    required String staffName,
    required DateTime month,
    required double baseSalary,
    double overtimeRatePerHour = 0,
    double deductions = 0,
    double advances = 0,
  }) async {
    final startOfMonth = DateTime(month.year, month.month);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final totalDays = endOfMonth.day;

    // Fetch attendance records for the month
    final snapshot = await _firestore
        .collection('$_basePath/attendance')
        .where('staffId', isEqualTo: staffId)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    final records =
        snapshot.docs.map((d) => AttendanceModel.fromFirestore(d)).toList();

    // Calculate days and hours
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

    final overtimePay = overtimeHours * overtimeRatePerHour;
    final netSalary = baseSalary + overtimePay - deductions - advances;

    return SalarySlip(
      staffId: staffId,
      staffName: staffName,
      month: startOfMonth,
      totalDays: totalDays,
      presentDays: presentDays,
      totalHours: totalHours,
      overtimeHours: overtimeHours,
      baseSalary: baseSalary,
      overtimePay: overtimePay,
      deductions: deductions,
      advances: advances,
      netSalary: netSalary,
    );
  }
}
