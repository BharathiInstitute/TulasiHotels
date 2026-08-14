/// Integration-style role flow checks using PermissionCenter.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/features/staff/services/staff_permissions.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

import '../helpers/test_factories_extended.dart';

StaffModel _roleStaff(StaffRole role) {
  return makeStaff(
    role: role,
    permissions: PermissionConfig.defaultTemplate(role),
  );
}

void main() {
  group('Integration: Staff Role-Based Access', () {
    test('waiter can access role-template screens', () {
      final waiter = _roleStaff(StaffRole.waiter);

      expect(
        PermissionCenter.canView(
          route: AppRoutes.tables,
          isOwner: false,
          staff: waiter,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.kitchen,
          isOwner: false,
          staff: waiter,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.myAttendance,
          isOwner: false,
          staff: waiter,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.billing,
          isOwner: false,
          staff: waiter,
        ),
        isFalse,
      );
    });

    test('chef can access kitchen/wastage but not billing', () {
      final chef = _roleStaff(StaffRole.chef);

      expect(
        PermissionCenter.canView(
          route: AppRoutes.kitchen,
          isOwner: false,
          staff: chef,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.wastage,
          isOwner: false,
          staff: chef,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.billing,
          isOwner: false,
          staff: chef,
        ),
        isFalse,
      );
    });

    test('cashier can access billing and khata', () {
      final cashier = _roleStaff(StaffRole.cashier);

      expect(
        PermissionCenter.canView(
          route: AppRoutes.billing,
          isOwner: false,
          staff: cashier,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.khata,
          isOwner: false,
          staff: cashier,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.kitchen,
          isOwner: false,
          staff: cashier,
        ),
        isFalse,
      );
    });

    test('manager has business catalog access and CRUD on products', () {
      final manager = _roleStaff(StaffRole.manager);

      for (final screen in PermissionConfig.allScreens) {
        if (screen.route == AppRoutes.settings) continue;
        expect(
          PermissionCenter.canView(
            route: screen.route,
            isOwner: false,
            staff: manager,
          ),
          isTrue,
        );
      }
      expect(
        PermissionCenter.canView(
          route: AppRoutes.settings,
          isOwner: false,
          staff: manager,
        ),
        isFalse,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.settingsHardware,
          isOwner: false,
          staff: manager,
        ),
        isTrue,
      );

      expect(
        PermissionCenter.hasAction(
          route: AppRoutes.products,
          action: PermissionAction.create,
          isOwner: false,
          staff: manager,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.hasAction(
          route: AppRoutes.products,
          action: PermissionAction.delete,
          isOwner: false,
          staff: manager,
        ),
        isTrue,
      );
    });

    test('custom permissions override role defaults', () {
      final customWaiter = makeStaff(
        role: StaffRole.waiter,
        permissions: {
          AppRoutes.billing: ['view', 'create'],
          AppRoutes.tables: ['view', 'update'],
        },
      );

      expect(
        PermissionCenter.canView(
          route: AppRoutes.billing,
          isOwner: false,
          staff: customWaiter,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.kitchen,
          isOwner: false,
          staff: customWaiter,
        ),
        isFalse,
      );
    });
  });

  group('Integration: navigation and route resolution', () {
    test('staff home routes are role-appropriate when permitted', () {
      expect(
        PermissionCenter.homeRoute(
          isOwner: false,
          staff: _roleStaff(StaffRole.waiter),
        ),
        AppRoutes.tables,
      );
      expect(
        PermissionCenter.homeRoute(
          isOwner: false,
          staff: _roleStaff(StaffRole.chef),
        ),
        AppRoutes.kitchen,
      );
      expect(
        PermissionCenter.homeRoute(
          isOwner: false,
          staff: _roleStaff(StaffRole.cashier),
        ),
        AppRoutes.billing,
      );
    });

    test('child route permissions inherit from parent route', () {
      final waiter = _roleStaff(StaffRole.waiter);
      expect(
        PermissionCenter.canView(
          route: AppRoutes.orderDetail,
          isOwner: false,
          staff: waiter,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.customerDetail,
          isOwner: false,
          staff: waiter,
        ),
        isFalse,
      );
    });

    test('deprecated wrapper remains parity-compatible', () {
      final waiter = _roleStaff(StaffRole.waiter);
      expect(
        StaffPermissions.canAccess(waiter, AppRoutes.tables),
        PermissionCenter.canView(
          route: AppRoutes.tables,
          isOwner: false,
          staff: waiter,
        ),
      );
    });
  });
}
