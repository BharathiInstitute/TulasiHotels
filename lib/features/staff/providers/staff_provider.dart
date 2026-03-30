/// Staff management providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/services/staff_service.dart';
import 'package:tulasihotels/models/staff_model.dart';

/// Real-time stream of all staff
final staffStreamProvider = StreamProvider.autoDispose<List<StaffModel>>((ref) {
  return StaffService.staffStream();
});

/// Real-time stream of active staff only
final activeStaffStreamProvider =
    StreamProvider.autoDispose<List<StaffModel>>((ref) {
  return StaffService.activeStaffStream();
});

/// Filter by role (null = all roles)
final staffRoleFilterProvider = StateProvider<StaffRole?>((ref) => null);

/// Search query for staff list
final staffSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered staff list by role and search
final filteredStaffProvider =
    Provider.autoDispose<AsyncValue<List<StaffModel>>>((ref) {
  final staffAsync = ref.watch(staffStreamProvider);
  final roleFilter = ref.watch(staffRoleFilterProvider);
  final searchQuery = ref.watch(staffSearchQueryProvider).toLowerCase();

  return staffAsync.whenData((staff) {
    var filtered = staff;

    if (roleFilter != null) {
      filtered = filtered.where((s) => s.role == roleFilter).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (s) =>
                s.name.toLowerCase().contains(searchQuery) ||
                (s.phone?.contains(searchQuery) ?? false),
          )
          .toList();
    }

    return filtered;
  });
});

/// Currently logged-in staff member (via PIN)
final loggedInStaffProvider = StateProvider<StaffModel?>((ref) => null);
