library;

import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/router/app_router.dart';

/// Canonical panel metadata used by permission evaluation.
class PermissionPanelDef {
  final String route;
  final String label;
  final List<String> collections;

  const PermissionPanelDef({
    required this.route,
    required this.label,
    required this.collections,
  });
}

/// Central panel catalog and route-to-panel aliases.
///
/// Notes:
/// - `route` is the panel permission anchor key.
/// - `collections` document which data groups belong to that panel.
/// - Route aliases map nested/non-nav routes to a panel anchor.
class PermissionPanels {
  PermissionPanels._();

  static const List<PermissionPanelDef> all = [
    PermissionPanelDef(
      route: AppRoutes.billing,
      label: 'Billing Panel',
      collections: ['bills', 'bill_items', 'payments', 'split_bills'],
    ),
    PermissionPanelDef(
      route: AppRoutes.khata,
      label: 'Khata Panel',
      collections: ['customers', 'khata_ledger', 'customer_balances'],
    ),
    PermissionPanelDef(
      route: AppRoutes.products,
      label: 'Products Panel',
      collections: ['products', 'menu_items', 'combos', 'daily_specials'],
    ),
    PermissionPanelDef(
      route: AppRoutes.dashboard,
      label: 'Dashboard Panel',
      collections: [
        'dashboard_metrics',
        'sales_summary',
        'bills',
        'expenses',
        'product_stock',
      ],
    ),
    PermissionPanelDef(
      route: AppRoutes.bills,
      label: 'Bills Panel',
      collections: ['bills', 'bill_items'],
    ),
    PermissionPanelDef(
      route: AppRoutes.tables,
      label: 'Tables Panel',
      collections: ['tables', 'table_layout'],
    ),
    PermissionPanelDef(
      route: AppRoutes.kitchen,
      label: 'Kitchen Panel',
      collections: ['kitchen_queue', 'kds_status'],
    ),
    PermissionPanelDef(
      route: AppRoutes.staff,
      label: 'Staff Panel',
      collections: ['staff', 'roles', 'attendance_records'],
    ),
    PermissionPanelDef(
      route: AppRoutes.myAttendance,
      label: 'My Attendance Panel',
      collections: ['attendance_records'],
    ),
    PermissionPanelDef(
      route: AppRoutes.vendors,
      label: 'Vendors Panel',
      collections: ['vendors', 'purchase_orders'],
    ),
    PermissionPanelDef(
      route: AppRoutes.wastage,
      label: 'Wastage Panel',
      collections: ['wastage_entries'],
    ),
    PermissionPanelDef(
      route: AppRoutes.reservations,
      label: 'Reservations Panel',
      collections: ['reservations', 'tables'],
    ),
    PermissionPanelDef(
      route: AppRoutes.coupons,
      label: 'Coupons Panel',
      collections: ['coupons', 'coupon_usage'],
    ),
    PermissionPanelDef(
      route: AppRoutes.feedback,
      label: 'Feedback Panel',
      collections: ['feedback', 'feedback_analytics'],
    ),
    PermissionPanelDef(
      route: AppRoutes.advancedReports,
      label: 'Reports Panel',
      collections: ['reports', 'analytics_exports'],
    ),
    PermissionPanelDef(
      route: AppRoutes.events,
      label: 'Events Panel',
      collections: ['events', 'compliance_logs'],
    ),
    PermissionPanelDef(
      route: AppRoutes.subscription,
      label: 'Subscription Panel',
      collections: ['subscription', 'plan_limits'],
    ),
    PermissionPanelDef(
      route: AppRoutes.settingsHardware,
      label: 'Hardware Panel',
      collections: [
        'printer_settings',
        'hardware_devices',
        'bluetooth_printers',
        'serial_printers',
      ],
    ),
  ];

  static const Map<String, String> _routeToPanel = {
    // Nested billing flows
    AppRoutes.orderBilling: AppRoutes.billing,
    AppRoutes.splitBill: AppRoutes.billing,

    // Nested orders flows now belong to Tables
    AppRoutes.orders: AppRoutes.tables,
    AppRoutes.orderDetail: AppRoutes.tables,
    AppRoutes.newOrder: AppRoutes.tables,
    AppRoutes.customerOrderStatus: AppRoutes.tables,

    // Nested products flows
    AppRoutes.productDetail: AppRoutes.products,
    AppRoutes.combos: AppRoutes.products,
    AppRoutes.dailySpecials: AppRoutes.products,
    AppRoutes.ingredients: AppRoutes.products,

    // Nested khata flow
    AppRoutes.customerDetail: AppRoutes.khata,

    // Nested tables flow
    AppRoutes.tableLayout: AppRoutes.tables,

    // Report routes
    AppRoutes.menuPerformance: AppRoutes.advancedReports,
    AppRoutes.weeklyReport: AppRoutes.advancedReports,
    AppRoutes.pnlReport: AppRoutes.advancedReports,
    AppRoutes.peakHours: AppRoutes.advancedReports,
    AppRoutes.itemSales: AppRoutes.advancedReports,
    AppRoutes.comparative: AppRoutes.advancedReports,
    AppRoutes.feedbackReport: AppRoutes.advancedReports,
    AppRoutes.gstExport: AppRoutes.advancedReports,

    // Feedback analytics
    AppRoutes.feedbackDashboard: AppRoutes.feedback,

    // Compliance-adjacent tools under events panel for now
    AppRoutes.licenses: AppRoutes.events,
    AppRoutes.equipment: AppRoutes.events,
    AppRoutes.complaints: AppRoutes.events,
  };

  static String resolvePanelRoute(String route) {
    if (route == AppRoutes.subscription || route.startsWith('${AppRoutes.subscription}/')) {
      return AppRoutes.subscription;
    }
    if (route == '/settings/subscription') {
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
    return _routeToPanel[route] ??
        _routeToPanel[PermissionConfig.resolvePermissionRoute(route)] ??
        PermissionConfig.resolvePermissionRoute(route);
  }

  static PermissionPanelDef? panelForRoute(String route) {
    final panelRoute = resolvePanelRoute(route);
    for (final panel in all) {
      if (panel.route == panelRoute) return panel;
    }
    return null;
  }

  static String panelLabelForRoute(String route) {
    return panelForRoute(route)?.label ?? route;
  }

  static String panelCategoryForRoute(String route) {
    final panelRoute = resolvePanelRoute(route);
    return PermissionConfig.screenForRoute(panelRoute)?.category ?? 'Other';
  }

  /// Migrates mixed route-based permissions to panel-route keys.
  ///
  /// Rules:
  /// - Child/alias routes are collapsed to their panel anchor route.
  /// - Duplicate actions are merged and de-duplicated per panel route.
  /// - Actions are normalized against the panel route's supported actions.
  static Map<String, List<String>> normalizeToPanelPermissions(
    Map<String, List<String>> permissions,
  ) {
    final merged = <String, Set<String>>{};

    for (final entry in permissions.entries) {
      final route = resolvePanelRoute(
        PermissionConfig.resolvePermissionRoute(entry.key),
      );
      final actions = merged.putIfAbsent(route, () => <String>{});
      actions.addAll(entry.value);
    }

    final normalized = <String, List<String>>{
      for (final entry in merged.entries) entry.key: entry.value.toList(),
    };

    return PermissionConfig.normalizePermissions(normalized);
  }
}
