/// Super Admin providers for state management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/super_admin/models/admin_user_model.dart';
import 'package:tulasihotels/features/super_admin/services/admin_firestore_service.dart';

/// Hardcoded super admin email fallback (used when Firestore is unavailable)
const List<String> superAdminEmails = [
  'kehsaram001@gmail.com',
  'admin@tulasihotels.com',
  'bharathiinstitute1@gmail.com',
  'bharahiinstitute1@gmail.com',
  'shivamsingh8556@gmail.com',
  'admin@lite.app',
  'kehsihba@gmail.com',
];

/// Admin emails from Firestore (live list).
/// Watches authNotifierProvider so it re-evaluates after sign-in/sign-out.
/// Before sign-in the read would fail (not authenticated), so we return
/// just the primary owner until the user is logged in.
final adminEmailsProvider = FutureProvider<List<String>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (!authState.isLoggedIn) {
    return [AdminFirestoreService.primaryOwnerEmail];
  }
  return AdminFirestoreService.getAdminEmails();
});

/// Check if current user is a super admin.
/// Fast path: hardcoded list (no Firestore needed).
/// Slow path: Firestore list for dynamically-added admins.
final isSuperAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);

  // Use UserModel email first, fall back to Firebase Auth email
  // (handles case where _loadUserProfile failed but firebaseUser is set)
  final email = authState.user?.email ?? authState.firebaseUser?.email;

  if (email == null) return false;

  final normalizedEmail = email.toLowerCase().trim();

  // Fast path: hardcoded list — always works, no Firestore needed
  if (superAdminEmails.contains(normalizedEmail)) return true;

  // Slow path: check Firestore for dynamically-added admins
  final firestoreEmails = ref.watch(adminEmailsProvider);
  return firestoreEmails.whenOrNull(
        data: (emails) =>
            emails.map((e) => e.toLowerCase().trim()).contains(normalizedEmail),
      ) ??
      false;
});

/// Check if current user is the primary owner (kehsaram001@gmail.com)
final isPrimaryOwnerProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final email = authState.user?.email ?? authState.firebaseUser?.email;
  if (email == null) return false;
  return email.toLowerCase().trim() == AdminFirestoreService.primaryOwnerEmail;
});

/// Seed gate — all admin providers depend on this.
/// Only runs for super admins to avoid permission-denied for regular users.
final _adminSeedProvider = FutureProvider<void>((ref) async {
  final isSuperAdmin = ref.watch(isSuperAdminProvider);
  if (!isSuperAdmin) return;
  await AdminFirestoreService.ensureAdminSeeded();
});

/// Dashboard statistics provider
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  await ref.watch(_adminSeedProvider.future);
  return AdminFirestoreService.getAdminStats();
});

/// All users provider with pagination
final allUsersProvider =
    FutureProvider.family<List<AdminUser>, UsersQueryParams>((
      ref,
      params,
    ) async {
      await ref.watch(_adminSeedProvider.future);
      return AdminFirestoreService.getAllUsers(
        limit: params.limit,
        searchQuery: params.searchQuery,
        planFilter: params.planFilter,
      );
    });

/// Simple all users provider (for initial load)
final usersListProvider = FutureProvider<List<AdminUser>>((ref) async {
  await ref.watch(_adminSeedProvider.future);
  return AdminFirestoreService.getAllUsers();
});

/// Recent users for dashboard
final recentUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  await ref.watch(_adminSeedProvider.future);
  return AdminFirestoreService.getRecentUsers();
});

/// Single user detail provider
final userDetailProvider = FutureProvider.family<AdminUser?, String>((
  ref,
  userId,
) async {
  return AdminFirestoreService.getUser(userId);
});

/// Expiring subscriptions provider
final expiringSubscriptionsProvider = FutureProvider<List<AdminUser>>((
  ref,
) async {
  return AdminFirestoreService.getExpiringSubscriptions();
});

/// Query parameters for users list
class UsersQueryParams {
  final int limit;
  final String? searchQuery;
  final SubscriptionPlan? planFilter;

  const UsersQueryParams({this.limit = 100, this.searchQuery, this.planFilter});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsersQueryParams &&
        other.limit == limit &&
        other.searchQuery == searchQuery &&
        other.planFilter == planFilter;
  }

  @override
  int get hashCode => Object.hash(limit, searchQuery, planFilter);
}

/// Search query state
final usersSearchQueryProvider = StateProvider<String>((ref) => '');

/// Plan filter state
final usersPlanFilterProvider = StateProvider<SubscriptionPlan?>((ref) => null);

/// Filtered users provider (combines search and filter)
final filteredUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  final searchQuery = ref.watch(usersSearchQueryProvider);
  final planFilter = ref.watch(usersPlanFilterProvider);

  return AdminFirestoreService.getAllUsers(
    searchQuery: searchQuery.isEmpty ? null : searchQuery,
    planFilter: planFilter,
  );
});

/// Platform distribution stats provider
final platformStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return AdminFirestoreService.getPlatformStats();
});

/// Feature usage stats provider
final featureUsageProvider = FutureProvider<Map<String, double>>((ref) async {
  return AdminFirestoreService.getFeatureUsageStats();
});

/// NPS survey results provider
final npsResultsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return AdminFirestoreService.getNpsResults();
});
