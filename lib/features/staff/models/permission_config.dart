/// Flexible per-user screen permission configuration
library;

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

const List<PermissionAction> _viewUpdateActions = [
  PermissionAction.view,
  PermissionAction.update,
];

const List<PermissionAction> _viewCreateActions = [
  PermissionAction.view,
  PermissionAction.create,
];

const List<PermissionAction> _viewCreateDeleteActions = [
  PermissionAction.view,
  PermissionAction.create,
  PermissionAction.delete,
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

  static const String coreCategory = 'Core';
  static const String ordersCategory = 'Orders & Kitchen';
  static const String financeCategory = 'Finance';
  static const String staffCategory = 'Staff';
  static const String inventoryCategory = 'Inventory';
  static const String hospitalityCategory = 'Hospitality';
  static const String reportsCategory = 'Reports';
  static const String complianceCategory = 'Compliance';

  static const List<String> categories = [
    coreCategory,
    ordersCategory,
    financeCategory,
    staffCategory,
    inventoryCategory,
    hospitalityCategory,
    reportsCategory,
    complianceCategory,
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
    ScreenDef(route: AppRoutes.combos, label: 'Combos', category: coreCategory),
    ScreenDef(
      route: AppRoutes.dailySpecials,
      label: 'Daily Specials',
      category: coreCategory,
    ),
    // Orders & Kitchen
    ScreenDef(
      route: AppRoutes.orders,
      label: 'Orders',
      category: ordersCategory,
    ),
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
    ScreenDef(
      route: AppRoutes.tableLayout,
      label: 'Table Layout',
      category: ordersCategory,
      supportedActions: _viewUpdateActions,
    ),
    // Finance
    ScreenDef(
      route: AppRoutes.khata,
      label: 'Khata Ledger',
      category: financeCategory,
    ),
    ScreenDef(
      route: AppRoutes.cashRegister,
      label: 'Cash Register',
      category: financeCategory,
    ),
    ScreenDef(
      route: AppRoutes.salary,
      label: 'Salary',
      category: financeCategory,
    ),
    // Staff
    ScreenDef(
      route: AppRoutes.staff,
      label: 'Staff Management',
      category: staffCategory,
    ),
    ScreenDef(
      route: AppRoutes.attendance,
      label: 'Attendance',
      category: staffCategory,
      supportedActions: _viewUpdateActions,
    ),
    ScreenDef(
      route: AppRoutes.myAttendance,
      label: 'My Attendance',
      category: staffCategory,
      supportedActions: _viewOnlyActions,
    ),
    ScreenDef(
      route: AppRoutes.shifts,
      label: 'Shifts',
      category: staffCategory,
    ),
    ScreenDef(route: AppRoutes.tasks, label: 'Tasks', category: staffCategory),
    ScreenDef(
      route: AppRoutes.messages,
      label: 'Messages',
      category: staffCategory,
      supportedActions: _viewCreateDeleteActions,
    ),
    // Inventory
    ScreenDef(
      route: AppRoutes.ingredients,
      label: 'Ingredients',
      category: inventoryCategory,
    ),
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
      route: AppRoutes.events,
      label: 'Events',
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
    ScreenDef(
      route: AppRoutes.gstExport,
      label: 'GST Export',
      category: reportsCategory,
      supportedActions: _viewOnlyActions,
    ),
    // Compliance
    ScreenDef(
      route: AppRoutes.equipment,
      label: 'Equipment',
      category: complianceCategory,
    ),
    ScreenDef(
      route: AppRoutes.licenses,
      label: 'Licenses',
      category: complianceCategory,
    ),
    ScreenDef(
      route: AppRoutes.complaints,
      label: 'Complaints',
      category: complianceCategory,
    ),
    // Management
    ScreenDef(
      route: AppRoutes.members,
      label: 'Members',
      category: staffCategory,
    ),
  ];

  /// Default permission templates per role (for quick setup)
  static Map<String, List<String>> defaultTemplate(StaffRole role) {
    final template = switch (role) {
      StaffRole.manager => {
        for (final s in allScreens) s.route: s.supportedActionKeys,
      },
      StaffRole.cashier => {
        AppRoutes.billing: _allActions,
        AppRoutes.khata: _allActions,
        AppRoutes.bills: [
          PermissionAction.view.key,
          PermissionAction.create.key,
        ],
        AppRoutes.tables: [PermissionAction.view.key],
        AppRoutes.orders: [
          PermissionAction.view.key,
          PermissionAction.create.key,
          PermissionAction.update.key,
        ],
        AppRoutes.myAttendance: [PermissionAction.view.key],
        AppRoutes.cashRegister: _allActions,
      },
      StaffRole.waiter => {
        AppRoutes.tables: [
          PermissionAction.view.key,
          PermissionAction.update.key,
        ],
        AppRoutes.orders: [
          PermissionAction.view.key,
          PermissionAction.create.key,
          PermissionAction.update.key,
        ],
        AppRoutes.kitchen: [PermissionAction.view.key],
        AppRoutes.myAttendance: [PermissionAction.view.key],
        AppRoutes.reservations: [PermissionAction.view.key],
        AppRoutes.feedback: [PermissionAction.view.key],
      },
      StaffRole.chef => {
        AppRoutes.kitchen: [
          PermissionAction.view.key,
          PermissionAction.update.key,
        ],
        AppRoutes.orders: [
          PermissionAction.view.key,
          PermissionAction.update.key,
        ],
        AppRoutes.myAttendance: [PermissionAction.view.key],
        AppRoutes.ingredients: [PermissionAction.view.key],
        AppRoutes.wastage: [
          PermissionAction.view.key,
          PermissionAction.create.key,
        ],
      },
    };

    return normalizePermissions(template);
  }

  static List<String> get _allActions =>
      PermissionAction.values.map((a) => a.key).toList();

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
    return {
      for (final entry in permissions.entries)
        entry.key: _normalizeActions(entry.key, entry.value),
    }..removeWhere((_, actions) => actions.isEmpty);
  }

  static List<String> _normalizeActions(String route, List<String> actions) {
    final screen = screenForRoute(route);
    if (screen == null) return List<String>.from(actions);

    final allowed = screen.supportedActionKeys.toSet();
    return [for (final action in actions) if (allowed.contains(action)) action];
  }

  /// Map of parent route → child routes that inherit permission
  /// e.g. /orders also covers /orders/:id, /orders/new, /orders/:id/bill
  static const Map<String, List<String>> _childRoutes = {
    AppRoutes.orders: [
      AppRoutes.orderDetail,
      AppRoutes.newOrder,
      AppRoutes.orderBilling,
      AppRoutes.splitBill,
    ],
    AppRoutes.products: [AppRoutes.productDetail],
    AppRoutes.khata: [AppRoutes.customerDetail],
    AppRoutes.advancedReports: [
      AppRoutes.menuPerformance,
      AppRoutes.weeklyReport,
      AppRoutes.pnlReport,
      AppRoutes.peakHours,
      AppRoutes.itemSales,
      AppRoutes.comparative,
      AppRoutes.feedbackReport,
    ],
    AppRoutes.feedback: [AppRoutes.feedbackDashboard],
  };

  /// Resolve a route to its parent permission route
  static String resolvePermissionRoute(String route) {
    for (final entry in _childRoutes.entries) {
      if (entry.value.contains(route)) return entry.key;
    }
    return route;
  }
}
