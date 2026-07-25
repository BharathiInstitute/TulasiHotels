library;

import 'package:tulasihotels/features/admin/models/store_role.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

/// Central policy catalog for role templates and preferred landing routes.
///
/// Keep business policy here so [PermissionCenter] can remain focused on
/// evaluation and messaging.
class PermissionPolicy {
  PermissionPolicy._();

  static Map<String, List<String>> staffRoleDefaults(StaffRole role) {
    final template = switch (role) {
      StaffRole.manager => {
        for (final s in PermissionConfig.allScreens) s.route: s.supportedActionKeys,
      },
      StaffRole.cashier => {
        AppRoutes.billing: _allActions,
        AppRoutes.khata: _allActions,
        AppRoutes.bills: [
          PermissionAction.view.key,
          PermissionAction.create.key,
        ],
        AppRoutes.tables: [PermissionAction.view.key],
        AppRoutes.myAttendance: [PermissionAction.view.key],
      },
      StaffRole.waiter => {
        AppRoutes.tables: [
          PermissionAction.view.key,
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
        AppRoutes.myAttendance: [PermissionAction.view.key],
        AppRoutes.wastage: [
          PermissionAction.view.key,
          PermissionAction.create.key,
        ],
      },
    };

    return PermissionConfig.normalizePermissions(template);
  }

  static Map<String, List<String>> memberRoleDefaults(StoreRole role) {
    final viewOnly = [PermissionAction.view.key];
    final template = switch (role) {
      StoreRole.owner => {
        for (final s in PermissionConfig.allScreens) s.route: s.supportedActionKeys,
      },
      StoreRole.manager => {
        for (final s in PermissionConfig.allScreens) s.route: s.supportedActionKeys,
      },
      StoreRole.cashier => {
        AppRoutes.billing: _allActions,
        AppRoutes.khata: _allActions,
        AppRoutes.bills: [
          PermissionAction.view.key,
          PermissionAction.create.key,
        ],
        AppRoutes.tables: viewOnly,
        AppRoutes.myAttendance: viewOnly,
      },
      StoreRole.accountant => {
        AppRoutes.billing: viewOnly,
        AppRoutes.khata: _allActions,
        AppRoutes.bills: _allActions,
        AppRoutes.dashboard: viewOnly,
        AppRoutes.advancedReports: viewOnly,
        AppRoutes.myAttendance: viewOnly,
      },
      StoreRole.staff => {
        AppRoutes.tables: viewOnly,
        AppRoutes.kitchen: viewOnly,
        AppRoutes.myAttendance: viewOnly,
      },
      StoreRole.custom => <String, List<String>>{},
    };

    return PermissionConfig.normalizePermissions(template);
  }

  static String preferredHomeForStaff(StaffRole role) {
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

  static String preferredHomeForMember(StoreRole role) {
    switch (role) {
      case StoreRole.owner:
      case StoreRole.manager:
      case StoreRole.cashier:
      case StoreRole.custom:
        return AppRoutes.billing;
      case StoreRole.accountant:
        return AppRoutes.dashboard;
      case StoreRole.staff:
        return AppRoutes.orders;
    }
  }

  static List<String> get _allActions =>
      PermissionAction.values.map((a) => a.key).toList();
}