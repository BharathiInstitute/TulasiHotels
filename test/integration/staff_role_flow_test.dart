/// Integration test: Staff login → role-based access → permissions
///
/// Tests that staff roles (waiter, chef, cashier, manager) get the
/// correct default permissions and that custom overrides work.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/features/staff/services/staff_permissions.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('Integration: Staff Role-Based Access', () {
    test('Step 1: Waiter can access tables, orders, kitchen', () {
      final waiter = makeStaff(
        name: 'Raju',
      );

      expect(StaffPermissions.canAccess(waiter, AppRoutes.tables), isTrue);
      expect(StaffPermissions.canAccess(waiter, AppRoutes.orders), isTrue);
      expect(StaffPermissions.canAccess(waiter, AppRoutes.kitchen), isTrue);
      expect(
        StaffPermissions.canAccess(waiter, AppRoutes.myAttendance),
        isTrue,
      );
      expect(
        StaffPermissions.canAccess(waiter, AppRoutes.reservations),
        isTrue,
      );
    });

    test('Step 2: Waiter cannot access billing, staff, reports', () {
      final waiter = makeStaff(
        name: 'Raju',
      );

      expect(StaffPermissions.canAccess(waiter, AppRoutes.billing), isFalse);
      expect(StaffPermissions.canAccess(waiter, AppRoutes.staff), isFalse);
      expect(
        StaffPermissions.canAccess(waiter, AppRoutes.advancedReports),
        isFalse,
      );
      expect(StaffPermissions.canAccess(waiter, AppRoutes.salary), isFalse);
    });

    test('Step 3: Chef can access kitchen, orders but not billing', () {
      final chef = makeStaff(
        id: 'staff-2',
        name: 'Suresh',
        role: StaffRole.chef,
        pin: '5678',
      );

      expect(StaffPermissions.canAccess(chef, AppRoutes.kitchen), isTrue);
      expect(StaffPermissions.canAccess(chef, AppRoutes.orders), isTrue);
      expect(StaffPermissions.canAccess(chef, AppRoutes.ingredients), isTrue);
      expect(StaffPermissions.canAccess(chef, AppRoutes.wastage), isTrue);
      expect(StaffPermissions.canAccess(chef, AppRoutes.billing), isFalse);
      expect(StaffPermissions.canAccess(chef, AppRoutes.khata), isFalse);
    });

    test('Step 4: Cashier can access billing, khata, cash register', () {
      final cashier = makeStaff(
        id: 'staff-3',
        name: 'Priya',
        role: StaffRole.cashier,
        pin: '9012',
      );

      expect(StaffPermissions.canAccess(cashier, AppRoutes.billing), isTrue);
      expect(StaffPermissions.canAccess(cashier, AppRoutes.khata), isTrue);
      expect(
        StaffPermissions.canAccess(cashier, AppRoutes.cashRegister),
        isTrue,
      );
      expect(StaffPermissions.canAccess(cashier, AppRoutes.tables), isTrue);
      expect(StaffPermissions.canAccess(cashier, AppRoutes.kitchen), isFalse);
    });

    test('Step 5: Manager has full access to all screens', () {
      final manager = makeStaff(
        id: 'staff-4',
        name: 'Mohan',
        role: StaffRole.manager,
        pin: '0000',
      );

      // Manager should access all core routes
      final coreRoutes = [
        AppRoutes.billing,
        AppRoutes.products,
        AppRoutes.dashboard,
        AppRoutes.bills,
        AppRoutes.tables,
        AppRoutes.orders,
        AppRoutes.kitchen,
        AppRoutes.staff,
        AppRoutes.attendance,
        AppRoutes.khata,
        AppRoutes.cashRegister,
        AppRoutes.salary,
      ];

      for (final route in coreRoutes) {
        expect(
          StaffPermissions.canAccess(manager, route),
          isTrue,
          reason: 'Manager should access $route',
        );
      }
    });

    test('Step 6: Manager has CRUD actions (not just view)', () {
      final manager = makeStaff(
        id: 'staff-4',
        name: 'Mohan',
        role: StaffRole.manager,
        pin: '0000',
      );

      expect(
        StaffPermissions.hasAction(
          manager,
          AppRoutes.products,
          PermissionAction.create,
        ),
        isTrue,
      );
      expect(
        StaffPermissions.hasAction(
          manager,
          AppRoutes.products,
          PermissionAction.delete,
        ),
        isTrue,
      );
    });

    test('Step 7: Waiter has limited CRUD actions', () {
      final waiter = makeStaff(
        name: 'Raju',
      );

      // Waiter can view+update tables, but not create/delete
      expect(
        StaffPermissions.hasAction(
          waiter,
          AppRoutes.tables,
          PermissionAction.view,
        ),
        isTrue,
      );
      expect(
        StaffPermissions.hasAction(
          waiter,
          AppRoutes.tables,
          PermissionAction.update,
        ),
        isTrue,
      );
      expect(
        StaffPermissions.hasAction(
          waiter,
          AppRoutes.tables,
          PermissionAction.delete,
        ),
        isFalse,
      );
    });

    test('Step 8: Custom permissions override role defaults', () {
      final customWaiter = makeStaff(
        id: 'staff-5',
        name: 'Custom Raju',
        pin: '1111',
        permissions: {
          AppRoutes.billing: ['view', 'create'],
          AppRoutes.tables: ['view', 'update'],
        },
      );

      // Custom: can access billing (not default for waiter)
      expect(
        StaffPermissions.canAccess(customWaiter, AppRoutes.billing),
        isTrue,
      );
      // Custom: lost kitchen access (was in default waiter)
      expect(
        StaffPermissions.canAccess(customWaiter, AppRoutes.kitchen),
        isFalse,
      );
    });
  });

  group('Integration: Staff route navigation', () {
    test('waiter home route is tables', () {
      final waiter = makeStaff();
      expect(StaffPermissions.homeRoute(waiter), AppRoutes.tables);
    });

    test('chef home route is kitchen', () {
      final chef = makeStaff(role: StaffRole.chef, pin: '5678');
      expect(StaffPermissions.homeRoute(chef), AppRoutes.kitchen);
    });

    test('cashier home route is billing', () {
      final cashier = makeStaff(role: StaffRole.cashier, pin: '9012');
      expect(StaffPermissions.homeRoute(cashier), AppRoutes.billing);
    });

    test('manager home route is billing', () {
      final manager = makeStaff(role: StaffRole.manager, pin: '0000');
      expect(StaffPermissions.homeRoute(manager), AppRoutes.billing);
    });

    test('permitted routes count matches role scope', () {
      final waiter = makeStaff();
      final chef = makeStaff(role: StaffRole.chef, pin: '5678');
      final manager = makeStaff(role: StaffRole.manager, pin: '0000');

      final waiterRoutes = StaffPermissions.permittedRoutes(waiter);
      final chefRoutes = StaffPermissions.permittedRoutes(chef);
      final managerRoutes = StaffPermissions.permittedRoutes(manager);

      // Manager has most routes
      expect(managerRoutes.length, greaterThan(chefRoutes.length));
      expect(managerRoutes.length, greaterThan(waiterRoutes.length));
    });
  });

  group('Integration: Child route resolution', () {
    test('order detail resolves to orders permission', () {
      final waiter = makeStaff();
      // Waiter can access /orders, so also /orders/:id
      expect(StaffPermissions.canAccess(waiter, AppRoutes.orderDetail), isTrue);
    });

    test('product detail resolves to products permission', () {
      final waiter = makeStaff();
      // Waiter cannot access /products, so also not /product/:id
      expect(
        StaffPermissions.canAccess(waiter, AppRoutes.productDetail),
        isFalse,
      );
    });

    test('customer detail resolves to khata permission', () {
      final chef = makeStaff(role: StaffRole.chef, pin: '5678');
      // Chef cannot access /khata, so also not /customer/:id
      expect(
        StaffPermissions.canAccess(chef, AppRoutes.customerDetail),
        isFalse,
      );
    });

    test('report sub-routes resolve to advancedReports', () {
      final manager = makeStaff(role: StaffRole.manager, pin: '0000');
      // Manager can access /reports, so all sub-routes too
      expect(
        StaffPermissions.canAccess(manager, AppRoutes.menuPerformance),
        isTrue,
      );
      expect(
        StaffPermissions.canAccess(manager, AppRoutes.weeklyReport),
        isTrue,
      );
    });
  });
}
