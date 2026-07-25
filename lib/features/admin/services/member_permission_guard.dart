/// Unified permission guard for store members (Firebase Auth users with roles).
/// Works alongside StaffPermissions (PIN-based staff login).
///
/// Priority:
/// 1. If a PIN-staff is logged in → StaffPermissions applies (existing behavior)
/// 2. If current user has a StoreMember doc → member permissions apply
/// 3. If no member doc exists → owner has full access (backward compatibility)
library;

import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';

@Deprecated('Use PermissionCenter APIs directly')
class MemberPermissionGuard {
  MemberPermissionGuard._();

  @Deprecated('Use PermissionCenter.canView(...)')
  /// Check if a member can access a route (has 'view' permission).
  /// Returns true for owner or if no member doc (backward compat).
  static bool canAccess(StoreMember? member, String route) {
    return PermissionCenter.canView(
      route: route,
      isOwner: member == null || member.isOwner,
      member: member,
    );
  }

  @Deprecated('Use PermissionCenter.hasAction(...)')
  /// Check if a member has a specific CRUD action on a route
  static bool hasAction(
    StoreMember? member,
    String route,
    PermissionAction action,
  ) {
    return PermissionCenter.hasAction(
      route: route,
      action: action,
      isOwner: member == null || member.isOwner,
      member: member,
    );
  }

  @Deprecated('Use PermissionCenter.canView(...) in consumers')
  /// Get all routes the member can view
  static Set<String> permittedRoutes(StoreMember? member) {
    final isOwner = member == null || member.isOwner;
    return {
      for (final s in PermissionConfig.allScreens)
        if (PermissionCenter.canView(
          route: s.route,
          isOwner: isOwner,
          member: member,
        ))
          s.route,
    };
  }

  @Deprecated('Use PermissionCenter.homeRoute(...)')
  /// Get the best home route for the member
  static String homeRoute(StoreMember? member) {
    return PermissionCenter.homeRoute(
      isOwner: member == null || member.isOwner,
      member: member,
    );
  }

  @Deprecated('Use PermissionCenter.visibleNavIndices(...)')
  /// Get visible sidebar indices for a member
  static List<int> visibleNavIndices(StoreMember? member) {
    return PermissionCenter.visibleNavIndices(
      isOwner: member == null || member.isOwner,
      member: member,
    );
  }

  @Deprecated('Use PermissionCenter.canSeeNavRoute(...)')
  /// Check if a sidebar section route is visible for a member
  static bool canViewRoute(StoreMember? member, String route) {
    return PermissionCenter.canSeeNavRoute(
      route: route,
      isOwner: member == null || member.isOwner,
      member: member,
    );
  }
}
