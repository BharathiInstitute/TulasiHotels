/// Store-level roles for multi-user access
library;

import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/router/app_router.dart';

/// Roles that a store member (Firebase Auth user) can hold
enum StoreRole {
  owner('Owner', 'Full access — cannot be removed'),
  manager('Manager', 'All features except user management'),
  accountant('Accountant', 'Finance, reports, and billing access'),
  cashier('Cashier', 'POS, billing, and order access'),
  staff('Staff', 'View-only on assigned modules'),
  custom('Custom', 'Manually assigned permissions');

  final String displayName;
  final String description;

  const StoreRole(this.displayName, this.description);

  static StoreRole fromString(String value) {
    return StoreRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StoreRole.staff,
    );
  }

  /// Default permission template for this role
  Map<String, List<String>> get defaultPermissions {
    final allActions =
        PermissionAction.values.map((a) => a.key).toList();
    final viewOnly = [PermissionAction.view.key];

    switch (this) {
      case StoreRole.owner:
        return {
          for (final s in PermissionConfig.allScreens) s.route: allActions,
        };

      case StoreRole.manager:
        // Everything except user management routes
        return {
          for (final s in PermissionConfig.allScreens) s.route: allActions,
        };

      case StoreRole.cashier:
        return {
          AppRoutes.billing: allActions,
          AppRoutes.khata: allActions,
          AppRoutes.bills: [
            PermissionAction.view.key,
            PermissionAction.create.key,
          ],
          AppRoutes.orders: [
            PermissionAction.view.key,
            PermissionAction.create.key,
            PermissionAction.update.key,
          ],
          AppRoutes.tables: viewOnly,
          AppRoutes.cashRegister: allActions,
          AppRoutes.attendance: viewOnly,
          AppRoutes.myAttendance: viewOnly,
        };

      case StoreRole.accountant:
        return {
          AppRoutes.billing: viewOnly,
          AppRoutes.khata: allActions,
          AppRoutes.bills: allActions,
          AppRoutes.dashboard: viewOnly,
          AppRoutes.cashRegister: allActions,
          AppRoutes.advancedReports: viewOnly,
          AppRoutes.gstExport: allActions,
          AppRoutes.salary: allActions,
          AppRoutes.myAttendance: viewOnly,
        };

      case StoreRole.staff:
        return {
          AppRoutes.tables: viewOnly,
          AppRoutes.orders: viewOnly,
          AppRoutes.kitchen: viewOnly,
          AppRoutes.myAttendance: viewOnly,
        };

      case StoreRole.custom:
        // Empty — must be manually configured
        return {};
    }
  }
}
