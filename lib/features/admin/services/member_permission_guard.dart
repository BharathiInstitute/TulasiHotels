/// Unified permission guard for store members (Firebase Auth users with roles).
/// Works alongside StaffPermissions (PIN-based staff login).
///
/// Priority:
/// 1. If a PIN-staff is logged in → StaffPermissions applies (existing behavior)
/// 2. If current user has a StoreMember doc → member permissions apply
/// 3. If no member doc exists → owner has full access (backward compatibility)
library;

import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/models/store_role.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/router/app_router.dart';

class MemberPermissionGuard {
  MemberPermissionGuard._();

  /// Check if a member can access a route (has 'view' permission).
  /// Returns true for owner or if no member doc (backward compat).
  static bool canAccess(StoreMember? member, String route) {
    if (member == null) return true; // No member doc → owner, full access
    if (member.isOwner) return true;

    final perms = member.effectivePermissions;
    final resolved = PermissionConfig.resolvePermissionRoute(route);
    final actions = perms[resolved];
    if (actions == null) return false;
    return actions.contains(PermissionAction.view.key);
  }

  /// Check if a member has a specific CRUD action on a route
  static bool hasAction(
    StoreMember? member,
    String route,
    PermissionAction action,
  ) {
    if (member == null) return true;
    if (member.isOwner) return true;

    final perms = member.effectivePermissions;
    final resolved = PermissionConfig.resolvePermissionRoute(route);
    final actions = perms[resolved];
    if (actions == null) return false;
    return actions.contains(action.key);
  }

  /// Get all routes the member can view
  static Set<String> permittedRoutes(StoreMember? member) {
    if (member == null || member.isOwner) {
      // Full access
      return PermissionConfig.allScreens.map((s) => s.route).toSet();
    }
    final perms = member.effectivePermissions;
    return perms.entries
        .where((e) => e.value.contains(PermissionAction.view.key))
        .map((e) => e.key)
        .toSet();
  }

  /// Get the best home route for the member
  static String homeRoute(StoreMember? member) {
    if (member == null || member.isOwner) return AppRoutes.billing;

    final permitted = permittedRoutes(member);
    final preferred = _preferredHome(member.role);
    if (permitted.contains(preferred)) return preferred;
    if (permitted.isNotEmpty) return permitted.first;
    return AppRoutes.billing;
  }

  static String _preferredHome(StoreRole role) {
    switch (role) {
      case StoreRole.owner:
      case StoreRole.manager:
        return AppRoutes.billing;
      case StoreRole.accountant:
        return AppRoutes.dashboard;
      case StoreRole.cashier:
        return AppRoutes.billing;
      case StoreRole.staff:
        return AppRoutes.orders;
      case StoreRole.custom:
        return AppRoutes.billing;
    }
  }

  /// Navigation items with their route and index mapping
  static const List<_NavRoute> _navRoutes = [
    _NavRoute(route: AppRoutes.billing, index: 0),
    _NavRoute(route: AppRoutes.khata, index: 1),
    _NavRoute(route: AppRoutes.products, index: 2),
    _NavRoute(route: AppRoutes.dashboard, index: 3),
    _NavRoute(route: AppRoutes.bills, index: 4),
    _NavRoute(route: AppRoutes.tables, index: 5),
    _NavRoute(route: AppRoutes.orders, index: 6),
    _NavRoute(route: AppRoutes.kitchen, index: 7),
    _NavRoute(route: AppRoutes.staff, index: 8),
    _NavRoute(route: AppRoutes.attendance, index: 9),
    _NavRoute(route: AppRoutes.myAttendance, index: 9),
  ];

  /// Get visible sidebar indices for a member
  static List<int> visibleNavIndices(StoreMember? member) {
    if (member == null || member.isOwner) {
      return _navRoutes.map((n) => n.index).toSet().toList()..sort();
    }
    final permitted = permittedRoutes(member);
    return _navRoutes
        .where((n) => permitted.contains(n.route))
        .map((n) => n.index)
        .toSet()
        .toList()
      ..sort();
  }

  /// Check if a sidebar section route is visible for a member
  static bool canViewRoute(StoreMember? member, String route) {
    if (member == null || member.isOwner) return true;
    return canAccess(member, route);
  }
}

class _NavRoute {
  final String route;
  final int index;
  const _NavRoute({required this.route, required this.index});
}
