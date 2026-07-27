/// Tests for PermissionCenter staff evaluation and deprecated StaffPermissions wrapper parity.
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
  group('PermissionCenter.canView (staff)', () {
    test('waiter can view tables/kitchen and table-linked orders but not billing', () {
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
          route: AppRoutes.orders,
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

    test('manager can view all catalog screens', () {
      final manager = _roleStaff(StaffRole.manager);

      for (final screen in PermissionConfig.allScreens) {
        expect(
          PermissionCenter.canView(
            route: screen.route,
            isOwner: false,
            staff: manager,
          ),
          isTrue,
          reason: 'Manager should view ${screen.route}',
        );
      }
    });

    test('child route resolution supports dynamic order paths', () {
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
          route: '/orders/runtime-id-123',
          isOwner: false,
          staff: waiter,
        ),
        isTrue,
      );
    });

    test('deny-by-default with empty permissions', () {
      final noAccess = makeStaff(role: StaffRole.manager, permissions: {});

      expect(
        PermissionCenter.canView(
          route: AppRoutes.billing,
          isOwner: false,
          staff: noAccess,
        ),
        isFalse,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.myAttendance,
          isOwner: false,
          staff: noAccess,
        ),
        isFalse,
      );
    });
  });

  group('PermissionCenter.hasAction (staff)', () {
    test('cashier can create bills', () {
      final cashier = _roleStaff(StaffRole.cashier);

      expect(
        PermissionCenter.hasAction(
          route: AppRoutes.billing,
          action: PermissionAction.create,
          isOwner: false,
          staff: cashier,
        ),
        isTrue,
      );
    });

    test('waiter cannot delete tables', () {
      final waiter = _roleStaff(StaffRole.waiter);

      expect(
        PermissionCenter.hasAction(
          route: AppRoutes.tables,
          action: PermissionAction.delete,
          isOwner: false,
          staff: waiter,
        ),
        isFalse,
      );
    });

    test('chef can create wastage', () {
      final chef = _roleStaff(StaffRole.chef);

      expect(
        PermissionCenter.hasAction(
          route: AppRoutes.wastage,
          action: PermissionAction.create,
          isOwner: false,
          staff: chef,
        ),
        isTrue,
      );
    });
  });

  group('PermissionCenter.homeRoute and nav visibility', () {
    test('role preferred homes resolve correctly when allowed', () {
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

    test('home route falls back to first accessible route', () {
      final staff = makeStaff(
        permissions: {
          AppRoutes.orders: [PermissionAction.view.key],
        },
      );

      expect(
        PermissionCenter.homeRoute(
          isOwner: false,
          staff: staff,
        ),
        AppRoutes.tables,
      );
    });

    test('owner nav indices include full shell set', () {
      final indices = PermissionCenter.visibleNavIndices(isOwner: true);
      expect(indices, contains(0));
      expect(indices, contains(9));
      expect(indices.length, greaterThanOrEqualTo(10));
    });
  });

  group('Deprecated wrapper parity', () {
    test('StaffPermissions.canAccess mirrors center', () {
      final waiter = _roleStaff(StaffRole.waiter);
      expect(
        StaffPermissions.canAccess(waiter, AppRoutes.orders),
        PermissionCenter.canView(
          route: AppRoutes.orders,
          isOwner: false,
          staff: waiter,
        ),
      );
    });

    test('StaffPermissions.hasAction mirrors center', () {
      final manager = _roleStaff(StaffRole.manager);
      expect(
        StaffPermissions.hasAction(
          manager,
          AppRoutes.products,
          PermissionAction.delete,
        ),
        PermissionCenter.hasAction(
          route: AppRoutes.products,
          action: PermissionAction.delete,
          isOwner: false,
          staff: manager,
        ),
      );
    });

    test('StaffPermissions.homeRoute and visibleNavIndices mirror center', () {
      final chef = _roleStaff(StaffRole.chef);
      expect(
        StaffPermissions.homeRoute(chef),
        PermissionCenter.homeRoute(isOwner: false, staff: chef),
      );
      expect(
        StaffPermissions.visibleNavIndices(chef),
        PermissionCenter.visibleNavIndices(isOwner: false, staff: chef),
      );
    });
  });
}
