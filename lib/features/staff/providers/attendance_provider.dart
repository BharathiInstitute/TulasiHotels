/// Attendance providers
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/services/attendance_service.dart';
import 'package:tulasihotels/models/attendance_model.dart';

/// Real-time stream of today's attendance
final todayAttendanceProvider =
    StreamProvider.autoDispose<List<AttendanceModel>>((ref) {
      return AttendanceService.todayAttendanceStream();
    });

/// Date range filter for attendance history
final attendanceDateRangeProvider = StateProvider<DateTimeRange?>(
  (ref) => null,
);

/// Staff filter for attendance history (null = all staff)
final attendanceStaffFilterProvider = StateProvider<String?>((ref) => null);

/// Staff detail panel: which staffId + staffName is being viewed
final staffDetailPanelProvider = StateProvider<({String id, String name})?>(
  (ref) => null,
);

/// Date range for the staff detail panel
final staffDetailDateRangeProvider = StateProvider<DateTimeRange?>(
  (ref) => null,
);

/// Attendance stream for a specific staff detail panel
final staffDetailAttendanceProvider =
    StreamProvider.autoDispose<List<AttendanceModel>>((ref) {
      final staffDetail = ref.watch(staffDetailPanelProvider);
      if (staffDetail == null) return const Stream.empty();
      final range = ref.watch(staffDetailDateRangeProvider);
      final now = DateTime.now();
      final from = range?.start ?? DateTime(now.year, now.month, now.day - 30);
      final to = range?.end ?? now;
      return AttendanceService.staffAttendanceStream(
        staffId: staffDetail.id,
        from: from,
        to: to,
      );
    });

/// Attendance stream for selected date range
final attendanceHistoryProvider =
    StreamProvider.autoDispose<List<AttendanceModel>>((ref) {
      final range = ref.watch(attendanceDateRangeProvider);
      if (range == null) {
        // Default: last 7 days
        final now = DateTime.now();
        return AttendanceService.attendanceStream(
          from: DateTime(now.year, now.month, now.day - 7),
          to: now,
        );
      }
      return AttendanceService.attendanceStream(
        from: range.start,
        to: range.end,
      );
    });

/// This week's attendance (Mon–today)
final thisWeekAttendanceProvider =
    StreamProvider.autoDispose<List<AttendanceModel>>((ref) {
      final now = DateTime.now();
      final weekday = now.weekday; // Mon=1
      final monday = DateTime(now.year, now.month, now.day - (weekday - 1));
      return AttendanceService.attendanceStream(from: monday, to: now);
    });

/// Last week's attendance (Mon–Sun of previous week)
final lastWeekAttendanceProvider =
    StreamProvider.autoDispose<List<AttendanceModel>>((ref) {
      final now = DateTime.now();
      final weekday = now.weekday;
      final thisMonday = DateTime(now.year, now.month, now.day - (weekday - 1));
      final lastMonday = thisMonday.subtract(const Duration(days: 7));
      final lastSunday = thisMonday.subtract(const Duration(days: 1));
      return AttendanceService.attendanceStream(
        from: lastMonday,
        to: DateTime(
          lastSunday.year,
          lastSunday.month,
          lastSunday.day,
          23,
          59,
          59,
        ),
      );
    });
