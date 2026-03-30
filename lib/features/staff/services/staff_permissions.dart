/// Per-user flexible screen permissions for staff members
library;

import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

/// Reads per-user permissions from StaffModel.permissions.
/// Falls back to role-based defaults when permissions are not set.
/// Owner (logged-in Firebase user with no staff) has full access.
class StaffPermissions {
  StaffPermissions._();

  /// Get the effective permission map for a staff member.
  /// Uses custom permissions if set, otherwise falls back to role template.
  static Map<String, List<String>> _effectivePermissions(StaffModel staff) {
    return staff.permissions ?? PermissionConfig.defaultTemplate(staff.role);
  }

  /// Check if a staff member can access a specific route (has 'view' permission)
  static bool canAccess(StaffModel staff, String route) {
    final perms = _effectivePermissions(staff);
    // Resolve child routes to their parent (e.g. /orders/:id → /orders)
    final resolved = PermissionConfig.resolvePermissionRoute(route);
    final actions = perms[resolved];
    if (actions == null) return false;
    return actions.contains(PermissionAction.view.key);
  }

  /// Check if a staff member has a specific CRUD action on a route
  static bool hasAction(StaffModel staff, String route, PermissionAction action) {
    final perms = _effectivePermissions(staff);
    final resolved = PermissionConfig.resolvePermissionRoute(route);
    final actions = perms[resolved];
    if (actions == null) return false;
    return actions.contains(action.key);
  }

  /// Get all permitted routes for a staff member (routes with 'view')
  static Set<String> permittedRoutes(StaffModel staff) {
    final perms = _effectivePermissions(staff);
    return perms.entries
        .where((e) => e.value.contains(PermissionAction.view.key))
        .map((e) => e.key)
        .toSet();
  }

  /// Get the default/home route for a staff member after login
  static String homeRoute(StaffModel staff) {
    final permitted = permittedRoutes(staff);
    // Try role-specific preferred home first
    final preferred = _preferredHome(staff.role);
    if (permitted.contains(preferred)) return preferred;
    // Fallback to first permitted route
    if (permitted.isNotEmpty) return permitted.first;
    return AppRoutes.attendance; // absolute fallback
  }

  static String _preferredHome(StaffRole role) {
    switch (role) {
      case StaffRole.manager:
      case StaffRole.cashier:
        return AppRoutes.billing;
      case StaffRole.waiter:
        return AppRoutes.tables;
      case StaffRole.chef:
        return AppRoutes.kitchen;
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

  /// Get visible navigation indices for a staff member (null = owner, show all)
  static List<int> visibleNavIndices(StaffModel? staff) {
    if (staff == null) {
      // Owner — all items visible
      return _navRoutes.map((n) => n.index).toSet().toList()..sort();
    }
    final permitted = permittedRoutes(staff);
    return _navRoutes
        .where((n) => permitted.contains(n.route))
        .map((n) => n.index)
        .toSet()
        .toList()
      ..sort();
  }

  /// Check if a sidebar section route is visible for a staff member
  static bool canViewRoute(StaffModel? staff, String route) {
    if (staff == null) return true; // Owner sees all
    return canAccess(staff, route);
  }
}

class _NavRoute {
  final String route;
  final int index;
  const _NavRoute({required this.route, required this.index});
}
