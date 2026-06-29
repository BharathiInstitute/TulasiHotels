/// Staff management providers
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/services/offline_storage_service.dart';
import 'package:tulasihotels/features/staff/services/staff_service.dart';
import 'package:tulasihotels/models/staff_model.dart';

/// Real-time stream of all staff
final staffStreamProvider = StreamProvider.autoDispose<List<StaffModel>>((ref) {
  return StaffService.staffStream();
});

/// Real-time stream of active staff only
final activeStaffStreamProvider = StreamProvider.autoDispose<List<StaffModel>>((
  ref,
) {
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

/// Currently logged-in staff member (via PIN).
/// Session is persisted in SharedPreferences so it survives web page refreshes.
const String _staffSessionKey = 'logged_in_staff_session';

class LoggedInStaffNotifier extends StateNotifier<StaffModel?> {
  /// Initial state is restored synchronously from SharedPreferences.
  /// Since OfflineStorageService is initialized before any providers are
  /// created (see main.dart), prefs is available on first access.
  LoggedInStaffNotifier() : super(_tryRestoreFromPrefs());

  static StaffModel? _tryRestoreFromPrefs() {
    try {
      final json = OfflineStorageService.prefs?.getString(_staffSessionKey);
      if (json == null || json.isEmpty) return null;
      final data = jsonDecode(json) as Map<String, dynamic>;
      final staff = StaffModel.fromJson(data);
      if (!staff.isActive) {
        OfflineStorageService.prefs?.remove(_staffSessionKey);
        return null;
      }
      debugPrint(
        '👤 Staff session restored: ${staff.name} (${staff.role.displayName})',
      );
      return staff;
    } catch (e) {
      debugPrint('Staff session restore error: $e');
      return null;
    }
  }

  /// Log in a staff member and persist their session.
  void login(StaffModel staff) {
    try {
      OfflineStorageService.prefs?.setString(
        _staffSessionKey,
        jsonEncode(staff.toJson()),
      );
    } catch (e) {
      debugPrint('Staff session save error: $e');
    }
    state = staff;
  }

  /// Log out the current staff member and clear their persisted session.
  void logout() {
    OfflineStorageService.prefs?.remove(_staffSessionKey);
    state = null;
  }
}

final loggedInStaffProvider =
    StateNotifierProvider<LoggedInStaffNotifier, StaffModel?>(
      (ref) => LoggedInStaffNotifier(),
    );
