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
    final allActions = PermissionAction.values.map((a) => a.key).toList();
    final viewOnly = [PermissionAction.view.key];

    final Map<String, List<String>> template;

    switch (this) {
      case StoreRole.owner:
        template = {
          for (final s in PermissionConfig.allScreens)
            s.route: s.supportedActionKeys,
        };
        break;
      case StoreRole.manager:
        template = {
          for (final s in PermissionConfig.allScreens)
            s.route: s.supportedActionKeys,
        };
        break;
      case StoreRole.cashier:
        template = {
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
        break;
      case StoreRole.accountant:
        template = {
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
        break;
      case StoreRole.staff:
        template = {
          AppRoutes.tables: viewOnly,
          AppRoutes.orders: viewOnly,
          AppRoutes.kitchen: viewOnly,
          AppRoutes.myAttendance: viewOnly,
        };
        break;
      case StoreRole.custom:
        template = {};
        break;
    }

    return PermissionConfig.normalizePermissions(template);
  }
}
