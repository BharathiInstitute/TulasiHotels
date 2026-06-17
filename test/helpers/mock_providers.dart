/// Reusable Riverpod provider overrides for widget / integration tests.
///
/// Usage:
/// ```dart
/// await pumpApp(
///   tester,
///   MyWidget(),
///   overrides: [
///     ...loggedInOwnerOverrides(),
///     // add extra overrides here
///   ],
/// );
/// ```
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/services/connectivity_service.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/models/staff_model.dart';

// ── Staff helpers ────────────────────────────────────────────────────────────

/// Creates a [StaffModel] with the given [role]. Override individual fields as
/// needed.
StaffModel _makeStaff({
  required StaffRole role,
  String? id,
  String? name,
  String pin = '1234',
}) {
  return StaffModel(
    id: id ?? 'test-${role.name}',
    name: name ?? 'Test ${role.displayName}',
    role: role,
    pin: pin,
    createdAt: DateTime(2024),
  );
}

// ── Role-specific overrides ──────────────────────────────────────────────────

/// Provider overrides that simulate a logged-in **owner** (no staff login).
///
/// The owner is the Firebase-authenticated user, so `loggedInStaffProvider` is
/// `null` (staff PIN login is not used by the owner).
List<Override> loggedInOwnerOverrides() {
  return [
    isDemoModeProvider.overrideWithValue(false),
    isLoggedInProvider.overrideWithValue(true),
  ];
}

/// Provider overrides that simulate a logged-in **waiter**.
List<Override> loggedInWaiterOverrides({StaffModel? staff}) {
  final s = staff ?? _makeStaff(role: StaffRole.waiter);
  return [
    isDemoModeProvider.overrideWithValue(false),
    isLoggedInProvider.overrideWithValue(true),
    loggedInStaffProvider.overrideWith((ref) => s),
  ];
}

/// Provider overrides that simulate a logged-in **chef**.
List<Override> loggedInChefOverrides({StaffModel? staff}) {
  final s = staff ?? _makeStaff(role: StaffRole.chef);
  return [
    isDemoModeProvider.overrideWithValue(false),
    isLoggedInProvider.overrideWithValue(true),
    loggedInStaffProvider.overrideWith((ref) => s),
  ];
}

/// Provider overrides that simulate a logged-in **cashier**.
List<Override> loggedInCashierOverrides({StaffModel? staff}) {
  final s = staff ?? _makeStaff(role: StaffRole.cashier);
  return [
    isDemoModeProvider.overrideWithValue(false),
    isLoggedInProvider.overrideWithValue(true),
    loggedInStaffProvider.overrideWith((ref) => s),
  ];
}

/// Provider overrides that simulate a logged-in **manager**.
List<Override> loggedInManagerOverrides({StaffModel? staff}) {
  final s = staff ?? _makeStaff(role: StaffRole.manager);
  return [
    isDemoModeProvider.overrideWithValue(false),
    isLoggedInProvider.overrideWithValue(true),
    loggedInStaffProvider.overrideWith((ref) => s),
  ];
}

// ── Mode overrides ───────────────────────────────────────────────────────────

/// Provider overrides for **demo mode** (no real Firestore).
List<Override> demoModeOverrides() {
  return [
    isDemoModeProvider.overrideWithValue(true),
    isLoggedInProvider.overrideWithValue(true),
  ];
}

/// Provider overrides that simulate **offline mode**.
///
/// Sets the connectivity provider to emit [ConnectivityStatus.offline].
List<Override> offlineModeOverrides() {
  return [
    isDemoModeProvider.overrideWithValue(false),
    isLoggedInProvider.overrideWithValue(true),
    connectivityProvider.overrideWith(
      (ref) => Stream.value(ConnectivityStatus.offline),
    ),
    isOnlineProvider.overrideWith((ref) => false),
  ];
}
