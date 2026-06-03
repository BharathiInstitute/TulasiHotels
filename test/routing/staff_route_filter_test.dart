/// Integration test: StaffPermissions.permittedRoutes integration
///
/// Tests that each staff role gets the correct set of permitted routes
/// and that custom permissions properly override defaults.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/features/staff/services/staff_permissions.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('Staff Route Filter: Waiter', () {
    late StaffModel waiter;

    setUp(() {
      waiter = makeStaff(role: StaffRole.waiter, pin: '1234');
    });

    test('waiter sees tables, orders, kitchen, attendance', () {
      final routes = StaffPermissions.permittedRoutes(waiter);
      expect(routes, contains(AppRoutes.tables));
      expect(routes, contains(AppRoutes.orders));
      expect(routes, contains(AppRoutes.kitchen));
      expect(routes, contains(AppRoutes.attendance));
      expect(routes, contains(AppRoutes.myAttendance));
    });

    test('waiter sees reservations and feedback (view only)', () {
      final routes = StaffPermissions.permittedRoutes(waiter);
      expect(routes, contains(AppRoutes.reservations));
      expect(routes, contains(AppRoutes.feedback));
    });

    test('waiter does NOT see billing, staff, reports', () {
      final routes = StaffPermissions.permittedRoutes(waiter);
      expect(routes, isNot(contains(AppRoutes.billing)));
      expect(routes, isNot(contains(AppRoutes.staff)));
      expect(routes, isNot(contains(AppRoutes.advancedReports)));
      expect(routes, isNot(contains(AppRoutes.salary)));
      expect(routes, isNot(contains(AppRoutes.khata)));
    });
  });

  group('Staff Route Filter: Chef', () {
    late StaffModel chef;

    setUp(() {
      chef = makeStaff(role: StaffRole.chef, pin: '5678');
    });

    test('chef sees kitchen, orders, attendance', () {
      final routes = StaffPermissions.permittedRoutes(chef);
      expect(routes, contains(AppRoutes.kitchen));
      expect(routes, contains(AppRoutes.orders));
      expect(routes, contains(AppRoutes.attendance));
      expect(routes, contains(AppRoutes.myAttendance));
    });

    test('chef sees ingredients and wastage', () {
      final routes = StaffPermissions.permittedRoutes(chef);
      expect(routes, contains(AppRoutes.ingredients));
      expect(routes, contains(AppRoutes.wastage));
    });

    test('chef does NOT see billing, khata, staff', () {
      final routes = StaffPermissions.permittedRoutes(chef);
      expect(routes, isNot(contains(AppRoutes.billing)));
      expect(routes, isNot(contains(AppRoutes.khata)));
      expect(routes, isNot(contains(AppRoutes.staff)));
    });
  });

  group('Staff Route Filter: Cashier', () {
    late StaffModel cashier;

    setUp(() {
      cashier = makeStaff(role: StaffRole.cashier, pin: '9012');
    });

    test('cashier sees billing, khata, cash register', () {
      final routes = StaffPermissions.permittedRoutes(cashier);
      expect(routes, contains(AppRoutes.billing));
      expect(routes, contains(AppRoutes.khata));
      expect(routes, contains(AppRoutes.cashRegister));
    });

    test('cashier sees bills, tables, orders, attendance', () {
      final routes = StaffPermissions.permittedRoutes(cashier);
      expect(routes, contains(AppRoutes.bills));
      expect(routes, contains(AppRoutes.tables));
      expect(routes, contains(AppRoutes.orders));
      expect(routes, contains(AppRoutes.attendance));
      expect(routes, contains(AppRoutes.myAttendance));
    });

    test('cashier does NOT see kitchen, staff, reports', () {
      final routes = StaffPermissions.permittedRoutes(cashier);
      expect(routes, isNot(contains(AppRoutes.kitchen)));
      expect(routes, isNot(contains(AppRoutes.staff)));
      expect(routes, isNot(contains(AppRoutes.advancedReports)));
    });
  });

  group('Staff Route Filter: Manager', () {
    late StaffModel manager;

    setUp(() {
      manager = makeStaff(role: StaffRole.manager, pin: '0000');
    });

    test('manager sees all core routes', () {
      final routes = StaffPermissions.permittedRoutes(manager);
      expect(routes, contains(AppRoutes.billing));
      expect(routes, contains(AppRoutes.products));
      expect(routes, contains(AppRoutes.dashboard));
      expect(routes, contains(AppRoutes.tables));
      expect(routes, contains(AppRoutes.orders));
      expect(routes, contains(AppRoutes.kitchen));
      expect(routes, contains(AppRoutes.staff));
      expect(routes, contains(AppRoutes.khata));
    });

    test('manager sees all feature routes', () {
      final routes = StaffPermissions.permittedRoutes(manager);
      expect(routes, contains(AppRoutes.reservations));
      expect(routes, contains(AppRoutes.coupons));
      expect(routes, contains(AppRoutes.events));
      expect(routes, contains(AppRoutes.ingredients));
      expect(routes, contains(AppRoutes.vendors));
      expect(routes, contains(AppRoutes.wastage));
    });

    test('manager sees compliance and reports', () {
      final routes = StaffPermissions.permittedRoutes(manager);
      expect(routes, contains(AppRoutes.advancedReports));
      expect(routes, contains(AppRoutes.gstExport));
      expect(routes, contains(AppRoutes.equipment));
      expect(routes, contains(AppRoutes.licenses));
      expect(routes, contains(AppRoutes.complaints));
    });

    test('manager has most routes of any role', () {
      final waiter = makeStaff(role: StaffRole.waiter, pin: '1111');
      final chef = makeStaff(role: StaffRole.chef, pin: '2222');
      final cashier = makeStaff(role: StaffRole.cashier, pin: '3333');

      final managerCount = StaffPermissions.permittedRoutes(manager).length;
      expect(
        managerCount,
        greaterThan(StaffPermissions.permittedRoutes(waiter).length),
      );
      expect(
        managerCount,
        greaterThan(StaffPermissions.permittedRoutes(chef).length),
      );
      expect(
        managerCount,
        greaterThan(StaffPermissions.permittedRoutes(cashier).length),
      );
    });
  });

  group('Staff Route Filter: Owner (null staff)', () {
    test('owner sees all routes', () {
      expect(StaffPermissions.canViewRoute(null, AppRoutes.billing), isTrue);
      expect(StaffPermissions.canViewRoute(null, AppRoutes.staff), isTrue);
      expect(
        StaffPermissions.canViewRoute(null, AppRoutes.advancedReports),
        isTrue,
      );
      expect(StaffPermissions.canViewRoute(null, AppRoutes.salary), isTrue);
      expect(StaffPermissions.canViewRoute(null, AppRoutes.equipment), isTrue);
    });
  });

  group('Staff Route Filter: Custom permissions', () {
    test('custom permissions override defaults', () {
      // Give a waiter billing access
      final customWaiter = makeStaff(
        role: StaffRole.waiter,
        pin: '4444',
        permissions: {
          AppRoutes.billing: ['view', 'create'],
          AppRoutes.tables: ['view', 'update'],
          AppRoutes.orders: ['view', 'create', 'update'],
        },
      );

      final routes = StaffPermissions.permittedRoutes(customWaiter);
      expect(routes, contains(AppRoutes.billing)); // custom: added
      expect(routes, contains(AppRoutes.tables));
      expect(routes, isNot(contains(AppRoutes.kitchen))); // custom: removed
    });

    test('empty custom permissions give no access', () {
      final noAccess = makeStaff(
        role: StaffRole.waiter,
        pin: '5555',
        permissions: {},
      );

      final routes = StaffPermissions.permittedRoutes(noAccess);
      expect(routes, isEmpty);
    });
  });

  group('Staff Route Filter: Nav indices', () {
    test('waiter visible nav indices include tables and orders', () {
      final waiter = makeStaff(role: StaffRole.waiter, pin: '1234');
      final indices = StaffPermissions.visibleNavIndices(waiter);
      // Tables = index 5, Orders = index 6, Kitchen = index 7
      expect(indices, contains(5)); // tables
      expect(indices, contains(6)); // orders
      expect(indices, contains(7)); // kitchen
    });

    test('cashier visible nav indices include billing', () {
      final cashier = makeStaff(role: StaffRole.cashier, pin: '9012');
      final indices = StaffPermissions.visibleNavIndices(cashier);
      expect(indices, contains(0)); // billing = index 0
      expect(indices, contains(1)); // khata = index 1
    });

    test('owner sees all nav indices', () {
      final indices = StaffPermissions.visibleNavIndices(null);
      // Should have all unique indices from nav routes: 0-9
      expect(indices.length, greaterThanOrEqualTo(9));
    });

    test('nav indices are sorted', () {
      final waiter = makeStaff(role: StaffRole.waiter, pin: '1234');
      final indices = StaffPermissions.visibleNavIndices(waiter);
      for (var i = 1; i < indices.length; i++) {
        expect(indices[i], greaterThanOrEqualTo(indices[i - 1]));
      }
    });
  });

  group('Staff Route Filter: CRUD actions', () {
    test('waiter cannot delete from tables', () {
      final waiter = makeStaff(role: StaffRole.waiter, pin: '1234');
      expect(
        StaffPermissions.hasAction(
          waiter,
          AppRoutes.tables,
          PermissionAction.delete,
        ),
        isFalse,
      );
    });

    test('manager can delete from products', () {
      final manager = makeStaff(role: StaffRole.manager, pin: '0000');
      expect(
        StaffPermissions.hasAction(
          manager,
          AppRoutes.products,
          PermissionAction.delete,
        ),
        isTrue,
      );
    });

    test('chef can create wastage records', () {
      final chef = makeStaff(role: StaffRole.chef, pin: '5678');
      expect(
        StaffPermissions.hasAction(
          chef,
          AppRoutes.wastage,
          PermissionAction.create,
        ),
        isTrue,
      );
    });

    test('cashier can create bills', () {
      final cashier = makeStaff(role: StaffRole.cashier, pin: '9012');
      expect(
        StaffPermissions.hasAction(
          cashier,
          AppRoutes.billing,
          PermissionAction.create,
        ),
        isTrue,
      );
    });
  });
}
