/// Shift scheduling providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/services/shift_service.dart';
import 'package:tulasihotels/models/shift_model.dart';

/// Stream today's shifts
final todayShiftsProvider = StreamProvider.autoDispose<List<ShiftModel>>((ref) {
  return ShiftService.todayShiftsStream();
});

/// Stream shifts for a specific staff member
final staffShiftsProvider =
    StreamProvider.autoDispose.family<List<ShiftModel>, String>((ref, staffId) {
  return ShiftService.staffShiftsStream(staffId);
});

/// Week filter for shift calendar
final shiftWeekStartProvider =
    StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return now.subtract(Duration(days: now.weekday - 1)); // Monday
});
