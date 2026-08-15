/// Flexible per-user screen permission configuration
library;

import 'package:tulasihotels/features/permissions/permission_policy.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

/// CRUD actions that can be granted per screen
enum PermissionAction {
  view('view', 'View'),
  create('create', 'Create'),
  update('update', 'Update'),
  delete('delete', 'Delete');

  final String key;
  final String label;
  const PermissionAction(this.key, this.label);
}

const List<PermissionAction> _fullCrudActions = [
  PermissionAction.view,
  PermissionAction.create,
  PermissionAction.update,
  PermissionAction.delete,
];

const List<PermissionAction> _viewOnlyActions = [PermissionAction.view];

const List<PermissionAction> _viewCreateActions = [
  PermissionAction.view,
  PermissionAction.create,
];

const List<PermissionAction> _viewUpdateActions = [
  PermissionAction.view,
  PermissionAction.update,
];

/// A screen that can be permission-controlled
class ScreenDef {
  final String route;
  final String label;
  final String category;
  final List<PermissionAction> supportedActions;

  const ScreenDef({
    required this.route,
    required this.label,
    required this.category,
    this.supportedActions = _fullCrudActions,
  });

  List<String> get supportedActionKeys =>
      supportedActions.map((action) => action.key).toList();
}

/// All permissionable screens grouped by category
class PermissionConfig {
  PermissionConfig._();

  /// Minimal baseline for non-owner users before admin grants module access.
  /// Keeps self-attendance reachable without granting any business module.
  static Map<String, List<String>> minimalAssignedPermissions() =>
      normalizePermissions({
        AppRoutes.myAttendance: [PermissionAction.view.key],
      });

  static const String coreCategory = 'Core';
  static const String ordersCategory = 'Orders & Kitchen';
  static const String financeCategory = 'Finance';
  static const String staffCategory = 'Staff';
  static const String inventoryCategory = 'Inventory';
  static const String hospitalityCategory = 'Hospitality';
  static const String reportsCategory = 'Reports';
  static const String complianceCategory = 'Compliance';
  static const String settingsCategory = 'Settings';

  static const List<String> categories = [
    coreCategory,
    ordersCategory,
    financeCategory,
    staffCategory,
    inventoryCategory,
    hospitalityCategory,
    reportsCategory,
    complianceCategory,
    settingsCategory,
  ];

  static const List<ScreenDef> allScreens = [
    // Core
    ScreenDef(
      route: AppRoutes.billing,
      label: 'Billing / Walk-in',
      category: coreCategory,
    ),
    ScreenDef(
      route: AppRoutes.products,
      label: 'Products / Menu',
      category: coreCategory,
    ),
    ScreenDef(
      route: AppRoutes.dashboard,
      label: 'Dashboard',
      category: coreCategory,
      supportedActions: _viewOnlyActions,
    ),
    ScreenDef(
      route: AppRoutes.bills,
      label: 'Bills',
      category: coreCategory,
      supportedActions: _viewOnlyActions,
    ),
    // Orders & Kitchen
    ScreenDef(
      route: AppRoutes.kitchen,
      label: 'Kitchen Display',
      category: ordersCategory,
      supportedActions: _viewUpdateActions,
    ),
    ScreenDef(
      route: AppRoutes.tables,
      label: 'Tables',
      category: ordersCategory,
    ),
    // Finance
    ScreenDef(
      route: AppRoutes.khata,
      label: 'Khata Ledger',
      category: financeCategory,
    ),
    // Staff
    ScreenDef(
      route: AppRoutes.staff,
      label: 'Staff Management',
      category: staffCategory,
    ),
    ScreenDef(
      route: AppRoutes.myAttendance,
      label: 'My Attendance',
      category: staffCategory,
      // Only self clock-in/out (create) + viewing own history are enforced.
      supportedActions: _viewCreateActions,
    ),
    // Inventory
    ScreenDef(
      route: AppRoutes.vendors,
      label: 'Vendors',
      category: inventoryCategory,
    ),
    ScreenDef(
      route: AppRoutes.wastage,
      label: 'Wastage',
      category: inventoryCategory,
      supportedActions: _viewCreateActions,
    ),
    // Hospitality
    ScreenDef(
      route: AppRoutes.reservations,
      label: 'Reservations',
      category: hospitalityCategory,
    ),
    ScreenDef(
      route: AppRoutes.coupons,
      label: 'Coupons',
      category: hospitalityCategory,
    ),
    ScreenDef(
      route: AppRoutes.feedback,
      label: 'Feedback',
      category: hospitalityCategory,
      supportedActions: _viewOnlyActions,
    ),
    // Reports
    ScreenDef(
      route: AppRoutes.advancedReports,
      label: 'Advanced Reports',
      category: reportsCategory,
      supportedActions: _viewOnlyActions,
    ),
    // Compliance
    ScreenDef(
      route: AppRoutes.events,
      label: 'Events',
      category: complianceCategory,
    ),
    // Settings
    ScreenDef(
      route: AppRoutes.settings,
      label: 'Settings',
      category: settingsCategory,
      supportedActions: _viewOnlyActions,
    ),
    ScreenDef(
      route: AppRoutes.subscription,
      label: 'Subscription',
      category: settingsCategory,
      supportedActions: _viewOnlyActions,
    ),
    // Settings: Hardware is the only settings panel configurable for staff.
    ScreenDef(
      route: AppRoutes.settingsHardware,
      label: 'Hardware',
      category: settingsCategory,
      supportedActions: _viewUpdateActions,
    ),
  ];

  /// Default permission templates per role (for quick setup)
  static Map<String, List<String>> defaultTemplate(StaffRole role) {
    return PermissionPolicy.staffRoleDefaults(role);
  }

  /// Get screens for a category
  static List<ScreenDef> screensForCategory(String category) {
    return allScreens.where((s) => s.category == category).toList();
  }

  static ScreenDef? screenForRoute(String route) {
    for (final screen in allScreens) {
      if (screen.route == route) return screen;
    }
    return null;
  }

  static List<PermissionAction> supportedActionsForRoute(String route) {
    return screenForRoute(route)?.supportedActions ?? _fullCrudActions;
  }

  static Map<String, List<String>> normalizePermissions(
    Map<String, List<String>> permissions,
  ) {
    final merged = <String, Set<String>>{};

    for (final entry in permissions.entries) {
      final route = resolvePermissionRoute(entry.key);
      final actions = merged.putIfAbsent(route, () => <String>{});
      actions.addAll(entry.value);
    }

    final normalized = <String, List<String>>{
      for (final entry in merged.entries)
        entry.key: _normalizeActions(entry.key, entry.value.toList()),
    };

    normalized
      ..removeWhere((_, actions) => actions.isEmpty)
      ..remove(AppRoutes.gstExport);

    return normalized;
  }

  static List<String> _normalizeActions(String route, List<String> actions) {
    final screen = screenForRoute(route);
    if (screen == null) {
      final deduped = <String>[];
      for (final action in actions) {
        if (!deduped.contains(action)) deduped.add(action);
      }
      return deduped;
    }

    final allowed = screen.supportedActionKeys.toSet();
    final filtered = [for (final action in actions) if (allowed.contains(action)) action];

    final hasMutation = filtered.contains(PermissionAction.create.key) ||
        filtered.contains(PermissionAction.update.key) ||
        filtered.contains(PermissionAction.delete.key);

    if (hasMutation &&
        !filtered.contains(PermissionAction.view.key) &&
        allowed.contains(PermissionAction.view.key)) {
      filtered.add(PermissionAction.view.key);
    }

    final normalized = <String>[];
    for (final key in screen.supportedActionKeys) {
      if (filtered.contains(key) && !normalized.contains(key)) {
        normalized.add(key);
      }
    }

    return normalized;
  }

  /// Map of parent route → child routes that inherit permission
  /// e.g. /orders also covers /orders/:id, /orders/new, /orders/:id/bill
  static const Map<String, List<String>> _childRoutes = {
    AppRoutes.billing: [AppRoutes.orderBilling, AppRoutes.splitBill],
    AppRoutes.products: [
      AppRoutes.productDetail,
      AppRoutes.combos,
      AppRoutes.dailySpecials,
      AppRoutes.ingredients,
    ],
    AppRoutes.khata: [AppRoutes.customerDetail],
    AppRoutes.staff: [
      AppRoutes.shifts,
      AppRoutes.cashRegister,
      AppRoutes.salary,
      AppRoutes.staffAttendanceDetail,
      AppRoutes.staffPayrollDetail,
    ],
    AppRoutes.tables: [
      AppRoutes.orders,
      AppRoutes.orderDetail,
      AppRoutes.newOrder,
      AppRoutes.customerOrderStatus,
      AppRoutes.tableLayout,
    ],
    AppRoutes.advancedReports: [
      AppRoutes.menuPerformance,
      AppRoutes.weeklyReport,
      AppRoutes.pnlReport,
      AppRoutes.peakHours,
      AppRoutes.itemSales,
      AppRoutes.comparative,
      AppRoutes.feedbackReport,
      AppRoutes.gstExport,
    ],
    AppRoutes.feedback: [AppRoutes.feedbackDashboard],
  };

  /// Resolve a route to its parent permission route
  static String resolvePermissionRoute(String route) {
    if (route == AppRoutes.subscription ||
        route.startsWith('${AppRoutes.subscription}/') ||
        route == '/settings/subscription') {
      return AppRoutes.subscription;
    }

    if (route == AppRoutes.settingsHardware) {
      return AppRoutes.settingsHardware;
    }

    if (route == AppRoutes.settings ||
        route == AppRoutes.settingsGeneral ||
        route == AppRoutes.settingsAccount ||
        route == AppRoutes.settingsBilling ||
        route == AppRoutes.attendanceSettings ||
        route == AppRoutes.themeSettings) {
      return AppRoutes.settings;
    }

    if (route.startsWith('/settings/')) {
      final tab = route.substring('/settings/'.length);
      if (tab == 'hardware') return AppRoutes.settingsHardware;
      if (tab == 'subscription') return AppRoutes.subscription;
      return AppRoutes.settings;
    }

    if (route == AppRoutes.orders || route.startsWith('${AppRoutes.orders}/')) {
      return AppRoutes.tables;
    }

    for (final entry in _childRoutes.entries) {
      if (entry.value.contains(route)) return entry.key;
    }
    return route;
  }
}
