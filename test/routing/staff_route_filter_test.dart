/// Route visibility and action matrix by staff role using PermissionCenter.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/features/staff/services/staff_permissions.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

import '../helpers/test_factories_extended.dart';

StaffModel _roleStaff(StaffRole role, {String pin = '1234'}) {
  return makeStaff(
    role: role,
    pin: pin,
    permissions: PermissionConfig.defaultTemplate(role),
  );
}

Set<String> _visibleRoutes(StaffModel staff) {
  return {
    for (final s in PermissionConfig.allScreens)
      if (PermissionCenter.canView(route: s.route, isOwner: false, staff: staff))
        s.route,
  };
}

void main() {
  group('Role route visibility', () {
    test('waiter routes follow template', () {
      final waiter = _roleStaff(StaffRole.waiter, pin: '1111');
      final routes = _visibleRoutes(waiter);

      expect(routes, contains(AppRoutes.tables));
      expect(routes, contains(AppRoutes.kitchen));
      expect(routes, contains(AppRoutes.myAttendance));
      expect(routes, contains(AppRoutes.reservations));
      expect(routes, contains(AppRoutes.feedback));
      expect(routes, isNot(contains(AppRoutes.billing)));
      expect(routes, isNot(contains(AppRoutes.staff)));
    });

    test('chef routes follow template', () {
      final chef = _roleStaff(StaffRole.chef, pin: '2222');
      final routes = _visibleRoutes(chef);

      expect(routes, contains(AppRoutes.kitchen));
      expect(routes, contains(AppRoutes.myAttendance));
      expect(routes, contains(AppRoutes.wastage));
      expect(routes, isNot(contains(AppRoutes.billing)));
      expect(routes, isNot(contains(AppRoutes.tables)));
    });

    test('cashier routes follow template', () {
      final cashier = _roleStaff(StaffRole.cashier, pin: '3333');
      final routes = _visibleRoutes(cashier);

      expect(routes, contains(AppRoutes.billing));
      expect(routes, contains(AppRoutes.khata));
      expect(routes, contains(AppRoutes.bills));
      expect(routes, contains(AppRoutes.tables));
      expect(routes, contains(AppRoutes.myAttendance));
      expect(routes, isNot(contains(AppRoutes.kitchen)));
    });

    test('manager sees business catalog routes but not owner settings', () {
      final manager = _roleStaff(StaffRole.manager, pin: '0000');
      final routes = _visibleRoutes(manager);

      for (final screen in PermissionConfig.allScreens) {
        if (screen.route == AppRoutes.settings) continue;
        expect(routes, contains(screen.route));
      }
      expect(routes, isNot(contains(AppRoutes.settings)));
      expect(routes, contains(AppRoutes.settingsHardware));
    });
  });

  group('Nav and actions', () {
    test('waiter nav indices include tables/kitchen', () {
      final waiter = _roleStaff(StaffRole.waiter);
      final indices = PermissionCenter.visibleNavIndices(
        isOwner: false,
        staff: waiter,
      );

      expect(indices, contains(5)); // tables
      expect(indices, contains(7)); // kitchen
      expect(indices, contains(9)); // attendance
      expect(indices, isNot(contains(0))); // billing
    });

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

  group('Deprecated wrapper parity', () {
    test('wrapper mirrors center for visibility and nav', () {
      final waiter = _roleStaff(StaffRole.waiter);
      expect(
        StaffPermissions.canAccess(waiter, AppRoutes.tables),
        PermissionCenter.canView(
          route: AppRoutes.tables,
          isOwner: false,
          staff: waiter,
        ),
      );
      expect(
        StaffPermissions.visibleNavIndices(waiter),
        PermissionCenter.visibleNavIndices(
          isOwner: false,
          staff: waiter,
        ),
      );
    });
  });
}
