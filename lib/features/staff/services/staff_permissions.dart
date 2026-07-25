/// Per-user flexible screen permissions for staff members
library;

import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/staff_model.dart';

/// Reads per-user permissions from StaffModel.permissions.
/// Falls back to a minimal baseline when permissions are not set.
/// Owner (logged-in Firebase user with no staff) has full access.
@Deprecated('Use PermissionCenter APIs directly')
class StaffPermissions {
  StaffPermissions._();

  @Deprecated('Use PermissionCenter.canView(...)')
  /// Check if a staff member can access a specific route (has 'view' permission)
  static bool canAccess(StaffModel staff, String route) {
    return PermissionCenter.canView(
      route: route,
      isOwner: false,
      staff: staff,
    );
  }

  @Deprecated('Use PermissionCenter.hasAction(...)')
  /// Check if a staff member has a specific CRUD action on a route
  static bool hasAction(StaffModel staff, String route, PermissionAction action) {
    return PermissionCenter.hasAction(
      route: route,
      action: action,
      isOwner: false,
      staff: staff,
    );
  }

  @Deprecated('Use PermissionCenter.canView(...) in consumers')
  /// Get all permitted routes for a staff member (routes with 'view')
  static Set<String> permittedRoutes(StaffModel staff) {
    return {
      for (final s in PermissionConfig.allScreens)
        if (PermissionCenter.canView(route: s.route, isOwner: false, staff: staff))
          s.route,
    };
  }

  @Deprecated('Use PermissionCenter.homeRoute(...)')
  /// Get the default/home route for a staff member after login
  static String homeRoute(StaffModel staff) {
    return PermissionCenter.homeRoute(
      isOwner: false,
      staff: staff,
    );
  }

  @Deprecated('Use PermissionCenter.visibleNavIndices(...)')
  /// Get visible navigation indices for a staff member (null = owner, show all)
  static List<int> visibleNavIndices(StaffModel? staff) {
    return PermissionCenter.visibleNavIndices(
      isOwner: staff == null,
      staff: staff,
    );
  }

  @Deprecated('Use PermissionCenter.canSeeNavRoute(...)')
  /// Check if a sidebar section route is visible for a staff member
  static bool canViewRoute(StaffModel? staff, String route) {
    return PermissionCenter.canSeeNavRoute(
      route: route,
      isOwner: staff == null,
      staff: staff,
    );
  }
}
