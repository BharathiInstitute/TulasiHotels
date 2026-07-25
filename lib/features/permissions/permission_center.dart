library;

import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/permissions/permission_panel.dart';
import 'package:tulasihotels/features/permissions/permission_policy.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

/// Global permission state for a specific route.
class RoutePermissionState {
  final bool isResolved;
  final bool canView;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;

  const RoutePermissionState({
    required this.isResolved,
    required this.canView,
    required this.canCreate,
    required this.canUpdate,
    required this.canDelete,
  });

  const RoutePermissionState.fullAccess()
    : isResolved = true,
      canView = true,
      canCreate = true,
      canUpdate = true,
      canDelete = true;

  const RoutePermissionState.none({this.isResolved = true})
    : canView = false,
      canCreate = false,
      canUpdate = false,
      canDelete = false;
}

/// Single global center for permission evaluation and messages.
///
/// Public contract (frozen):
/// - [resolveRouteState]: resolve view and CRUD flags for route-aware UI.
/// - [canView]: quick route visibility check for router/shell.
/// - [hasAction]: quick mutation action check for services/UI guards.
/// - [homeRoute]: best landing route for the current identity context.
/// - [visibleNavIndices] and [canSeeNavRoute]: shell navigation visibility.
/// - [deniedViewMessage] and [deniedActionMessage]: uniform denial copy.
///
/// Usage example:
/// final state = PermissionCenter.resolveRouteState(
///   route: AppRoutes.products,
///   contextResolved: true,
///   isOwner: false,
///   staff: staff,
/// );
/// if (!state.canView) {
///   final message = PermissionCenter.deniedViewMessage(AppRoutes.products);
/// }
class PermissionCenter {
  PermissionCenter._();

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

  static RoutePermissionState resolveRouteState({
    required String route,
    required bool contextResolved,
    required bool isOwner,
    StaffModel? staff,
    StoreMember? member,
  }) {
    if (!contextResolved) {
      return const RoutePermissionState.none(isResolved: false);
    }

    if (staff != null) {
      return RoutePermissionState(
        isResolved: true,
        canView: canView(route: route, isOwner: false, staff: staff),
        canCreate: hasAction(
          route: route,
          action: PermissionAction.create,
          isOwner: false,
          staff: staff,
        ),
        canUpdate: hasAction(
          route: route,
          action: PermissionAction.update,
          isOwner: false,
          staff: staff,
        ),
        canDelete: hasAction(
          route: route,
          action: PermissionAction.delete,
          isOwner: false,
          staff: staff,
        ),
      );
    }

    if (isOwner) {
      return const RoutePermissionState.fullAccess();
    }

    if (member == null) {
      return const RoutePermissionState.none();
    }

    return RoutePermissionState(
      isResolved: true,
      canView: canView(route: route, isOwner: false, member: member),
      canCreate: hasAction(
        route: route,
        action: PermissionAction.create,
        isOwner: false,
        member: member,
      ),
      canUpdate: hasAction(
        route: route,
        action: PermissionAction.update,
        isOwner: false,
        member: member,
      ),
      canDelete: hasAction(
        route: route,
        action: PermissionAction.delete,
        isOwner: false,
        member: member,
      ),
    );
  }

  static bool canView({
    required String route,
    required bool isOwner,
    StaffModel? staff,
    StoreMember? member,
  }) {
    if (_isAlwaysViewableUtilityRoute(route)) {
      return true;
    }
    if (staff != null) {
      final actions = _staffActionsForRoute(staff, route);
      return actions.contains(PermissionAction.view.key);
    }
    if (isOwner) return true;
    if (member == null) return false;
    final actions = _memberActionsForRoute(member, route);
    return actions.contains(PermissionAction.view.key);
  }

  static bool hasAction({
    required String route,
    required PermissionAction action,
    required bool isOwner,
    StaffModel? staff,
    StoreMember? member,
  }) {
    if (staff != null) {
      final actions = _staffActionsForRoute(staff, route);
      return actions.contains(action.key);
    }
    if (isOwner) return true;
    if (member == null) return false;
    final actions = _memberActionsForRoute(member, route);
    return actions.contains(action.key);
  }

  static String homeRoute({
    required bool isOwner,
    StaffModel? staff,
    StoreMember? member,
  }) {
    if (staff != null) {
      final preferred = PermissionPolicy.preferredHomeForStaff(staff.role);
      if (canView(route: preferred, isOwner: false, staff: staff)) {
        return preferred;
      }
      return _firstAccessibleNavRoute(isOwner: false, staff: staff) ??
          AppRoutes.attendance;
    }
    if (isOwner) return AppRoutes.billing;
    if (member != null) {
      final preferred = PermissionPolicy.preferredHomeForMember(member.role);
      if (canView(route: preferred, isOwner: false, member: member)) {
        return preferred;
      }
      return _firstAccessibleNavRoute(isOwner: false, member: member) ??
          AppRoutes.billing;
    }
    return AppRoutes.billing;
  }

  static List<int> visibleNavIndices({
    required bool isOwner,
    StaffModel? staff,
    StoreMember? member,
  }) {
    if (isOwner) {
      return _navRoutes.map((n) => n.index).toSet().toList()..sort();
    }

    return _navRoutes
        .where(
          (n) => canView(
            route: n.route,
            isOwner: isOwner,
            staff: staff,
            member: member,
          ),
        )
        .map((n) => n.index)
        .toSet()
        .toList()
      ..sort();
  }

  static bool canSeeNavRoute({
    required String route,
    required bool isOwner,
    StaffModel? staff,
    StoreMember? member,
  }) {
    return canView(
      route: route,
      isOwner: isOwner,
      staff: staff,
      member: member,
    );
  }

  static String deniedViewMessage(String route) {
    final label = _panelOrScreenLabelFor(route);
    return 'You do not have permission to view $label.';
  }

  static String deniedActionMessage(String route, PermissionAction action) {
    final label = _panelOrScreenLabelFor(route);
    return 'You do not have permission to ${action.label.toLowerCase()} $label.';
  }

  static String _panelOrScreenLabelFor(String route) {
    final panel = PermissionPanels.panelForRoute(route);
    if (panel != null) return panel.label;

    final resolved = PermissionPanels.resolvePanelRoute(
      PermissionConfig.resolvePermissionRoute(route),
    );
    final screen = PermissionConfig.screenForRoute(resolved);
    return screen?.label ?? route;
  }

  static List<String> _staffActionsForRoute(StaffModel staff, String route) {
    final permissions = PermissionConfig.normalizePermissions(
      staff.permissions ?? PermissionConfig.minimalAssignedPermissions(),
    );
    final permissionRoute = PermissionConfig.resolvePermissionRoute(route);
    final resolved = PermissionPanels.resolvePanelRoute(permissionRoute);
    final direct = permissions[resolved] ?? const <String>[];
    if (direct.isNotEmpty) return direct;

    // Backward compatibility: historically many roles granted table actions but
    // not explicit /orders permissions. Allow table-linked order flows to work
    // by deriving order actions from the table action set.
    if (permissionRoute == AppRoutes.orders) {
      final tableActions = permissions[AppRoutes.tables] ?? const <String>[];
      final bridged = _deriveOrderActionsFromTableActions(tableActions);
      if (bridged.isNotEmpty) return bridged;
    }

    // Backward compatibility: read legacy route-keyed entries if present.
    final legacyResolved = PermissionConfig.resolvePermissionRoute(route);
    return permissions[legacyResolved] ?? const <String>[];
  }

  static List<String> _memberActionsForRoute(StoreMember member, String route) {
    final permissions = member.effectivePermissions;
    final permissionRoute = PermissionConfig.resolvePermissionRoute(route);
    final resolved = PermissionPanels.resolvePanelRoute(permissionRoute);
    final direct = permissions[resolved] ?? const <String>[];
    if (direct.isNotEmpty) return direct;

    // Backward compatibility bridge for older/custom member configs where
    // table actions exist without explicit /orders entries.
    if (permissionRoute == AppRoutes.orders) {
      final tableActions = permissions[AppRoutes.tables] ?? const <String>[];
      final bridged = _deriveOrderActionsFromTableActions(tableActions);
      if (bridged.isNotEmpty) return bridged;
    }

    // Backward compatibility: read legacy route-keyed entries if present.
    final legacyResolved = PermissionConfig.resolvePermissionRoute(route);
    return permissions[legacyResolved] ?? const <String>[];
  }

  static List<String> _deriveOrderActionsFromTableActions(
    List<String> tableActions,
  ) {
    if (tableActions.isEmpty) return const <String>[];

    final bridged = <String>{};
    if (tableActions.contains(PermissionAction.view.key)) {
      bridged.add(PermissionAction.view.key);
    }

    // Table update capability implies handling table-linked order lifecycle
    // (start/edit/serve), so bridge create+update for orders.
    if (tableActions.contains(PermissionAction.update.key)) {
      bridged
        ..add(PermissionAction.create.key)
        ..add(PermissionAction.update.key);
    }

    if (tableActions.contains(PermissionAction.delete.key)) {
      bridged.add(PermissionAction.delete.key);
    }

    return bridged.toList();
  }

  static String? _firstAccessibleNavRoute({
    required bool isOwner,
    StaffModel? staff,
    StoreMember? member,
  }) {
    for (final nav in _navRoutes) {
      if (canView(
        route: nav.route,
        isOwner: isOwner,
        staff: staff,
        member: member,
      )) {
        return nav.route;
      }
    }
    return null;
  }

  static bool _isAlwaysViewableUtilityRoute(String route) {
    return route == AppRoutes.notifications ||
        route == AppRoutes.support ||
        route == AppRoutes.supportChat ||
        route.startsWith('/support/');
  }
}

class _NavRoute {
  final String route;
  final int index;
  const _NavRoute({required this.route, required this.index});
}
