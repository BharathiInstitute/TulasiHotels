/// Tests for StaffPermissions — pure logic, no Firestore
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/features/staff/services/staff_permissions.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('canAccess', () {
    test('manager can access all screens', () {
      final staff = makeStaff(role: StaffRole.manager);
      for (final screen in PermissionConfig.allScreens) {
        // Skip screens whose route resolves to a different parent
        // (child routes like feedbackDashboard → feedback)
        final resolved = PermissionConfig.resolvePermissionRoute(screen.route);
        if (resolved != screen.route) continue;
        expect(
          StaffPermissions.canAccess(staff, screen.route),
          isTrue,
          reason: 'Manager should access ${screen.route}',
        );
      }
    });

    test('waiter can access tables', () {
      final staff = makeStaff(role: StaffRole.waiter);
      expect(StaffPermissions.canAccess(staff, AppRoutes.tables), isTrue);
    });

    test('waiter cannot access billing', () {
      final staff = makeStaff(role: StaffRole.waiter);
      expect(StaffPermissions.canAccess(staff, AppRoutes.billing), isFalse);
    });

    test('cashier can access billing', () {
      final staff = makeStaff(role: StaffRole.cashier);
      expect(StaffPermissions.canAccess(staff, AppRoutes.billing), isTrue);
    });

    test('chef can access kitchen', () {
      final staff = makeStaff(role: StaffRole.chef);
      expect(StaffPermissions.canAccess(staff, AppRoutes.kitchen), isTrue);
    });

    test('chef cannot access billing', () {
      final staff = makeStaff(role: StaffRole.chef);
      expect(StaffPermissions.canAccess(staff, AppRoutes.billing), isFalse);
    });

    test('child route resolves to parent — order detail inherits orders', () {
      final staff = makeStaff(role: StaffRole.waiter);
      expect(StaffPermissions.canAccess(staff, AppRoutes.orderDetail), isTrue);
    });

    test('unknown route returns false', () {
      final staff = makeStaff(role: StaffRole.waiter);
      expect(StaffPermissions.canAccess(staff, '/unknown-route'), isFalse);
    });
  });

  group('hasAction', () {
    test('cashier has create on billing', () {
      final staff = makeStaff(role: StaffRole.cashier);
      expect(
        StaffPermissions.hasAction(
          staff,
          AppRoutes.billing,
          PermissionAction.create,
        ),
        isTrue,
      );
    });

    test('waiter has create on orders', () {
      final staff = makeStaff(role: StaffRole.waiter);
      expect(
        StaffPermissions.hasAction(
          staff,
          AppRoutes.orders,
          PermissionAction.create,
        ),
        isTrue,
      );
    });

    test('waiter does not have delete on orders', () {
      final staff = makeStaff(role: StaffRole.waiter);
      expect(
        StaffPermissions.hasAction(
          staff,
          AppRoutes.orders,
          PermissionAction.delete,
        ),
        isFalse,
      );
    });

    test('chef has update on kitchen', () {
      final staff = makeStaff(role: StaffRole.chef);
      expect(
        StaffPermissions.hasAction(
          staff,
          AppRoutes.kitchen,
          PermissionAction.update,
        ),
        isTrue,
      );
    });

    test('returns false for route without access', () {
      final staff = makeStaff(role: StaffRole.waiter);
      expect(
        StaffPermissions.hasAction(
          staff,
          AppRoutes.billing,
          PermissionAction.view,
        ),
        isFalse,
      );
    });
  });

  group('permittedRoutes', () {
    test('waiter gets expected routes', () {
      final staff = makeStaff(role: StaffRole.waiter);
      final routes = StaffPermissions.permittedRoutes(staff);
      expect(routes, contains(AppRoutes.tables));
      expect(routes, contains(AppRoutes.orders));
      expect(routes, contains(AppRoutes.kitchen));
      expect(routes, contains(AppRoutes.attendance));
      expect(routes, isNot(contains(AppRoutes.billing)));
      expect(routes, isNot(contains(AppRoutes.staff)));
    });

    test('cashier gets expected routes', () {
      final staff = makeStaff(role: StaffRole.cashier);
      final routes = StaffPermissions.permittedRoutes(staff);
      expect(routes, contains(AppRoutes.billing));
      expect(routes, contains(AppRoutes.khata));
      expect(routes, contains(AppRoutes.cashRegister));
      expect(routes, isNot(contains(AppRoutes.kitchen)));
    });

    test('chef gets expected routes', () {
      final staff = makeStaff(role: StaffRole.chef);
      final routes = StaffPermissions.permittedRoutes(staff);
      expect(routes, contains(AppRoutes.kitchen));
      expect(routes, contains(AppRoutes.orders));
      expect(routes, contains(AppRoutes.ingredients));
      expect(routes, contains(AppRoutes.wastage));
      expect(routes, isNot(contains(AppRoutes.billing)));
    });

    test('manager has all screens', () {
      final staff = makeStaff(role: StaffRole.manager);
      final routes = StaffPermissions.permittedRoutes(staff);
      for (final screen in PermissionConfig.allScreens) {
        expect(
          routes,
          contains(screen.route),
          reason: 'Manager should have ${screen.route}',
        );
      }
    });
  });

  group('homeRoute', () {
    test('manager → billing', () {
      final staff = makeStaff(role: StaffRole.manager);
      expect(StaffPermissions.homeRoute(staff), AppRoutes.billing);
    });

    test('cashier → billing', () {
      final staff = makeStaff(role: StaffRole.cashier);
      expect(StaffPermissions.homeRoute(staff), AppRoutes.billing);
    });

    test('waiter → tables', () {
      final staff = makeStaff(role: StaffRole.waiter);
      expect(StaffPermissions.homeRoute(staff), AppRoutes.tables);
    });

    test('chef → kitchen', () {
      final staff = makeStaff(role: StaffRole.chef);
      expect(StaffPermissions.homeRoute(staff), AppRoutes.kitchen);
    });

    test('falls back when preferred route removed by custom perms', () {
      // Waiter whose tables permission is removed
      final staff = makeStaff(
        role: StaffRole.waiter,
        permissions: {
          AppRoutes.orders: ['view', 'create'],
          AppRoutes.attendance: ['view'],
        },
      );
      // Should NOT be tables since it's not in custom permissions
      expect(StaffPermissions.homeRoute(staff), isNot(AppRoutes.tables));
      // Should be one of the permitted routes
      final permitted = StaffPermissions.permittedRoutes(staff);
      expect(permitted, contains(StaffPermissions.homeRoute(staff)));
    });
  });

  group('visibleNavIndices', () {
    test('null staff (owner) returns all unique indices', () {
      final indices = StaffPermissions.visibleNavIndices(null);
      // Should include indices 0-9
      expect(indices, contains(0)); // billing
      expect(indices, contains(5)); // tables
      expect(indices, contains(7)); // kitchen
      expect(indices, contains(9)); // attendance / myAttendance
      expect(indices, isSorted);
    });

    test('waiter sees limited nav items', () {
      final staff = makeStaff(role: StaffRole.waiter);
      final indices = StaffPermissions.visibleNavIndices(staff);
      expect(indices, contains(5)); // tables
      expect(indices, contains(6)); // orders
      expect(indices, contains(7)); // kitchen
      expect(indices, contains(9)); // attendance / myAttendance
      expect(indices, isNot(contains(0))); // no billing
      expect(indices, isNot(contains(1))); // no khata
      expect(indices, isSorted);
    });

    test('cashier sees billing + khata nav items', () {
      final staff = makeStaff(role: StaffRole.cashier);
      final indices = StaffPermissions.visibleNavIndices(staff);
      expect(indices, contains(0)); // billing
      expect(indices, contains(1)); // khata
      expect(indices, isNot(contains(7))); // no kitchen
      expect(indices, isSorted);
    });
  });

  group('canViewRoute', () {
    test('null staff can view any route', () {
      expect(StaffPermissions.canViewRoute(null, AppRoutes.billing), isTrue);
      expect(StaffPermissions.canViewRoute(null, AppRoutes.staff), isTrue);
    });

    test('delegates to canAccess for non-null staff', () {
      final staff = makeStaff(role: StaffRole.waiter);
      expect(StaffPermissions.canViewRoute(staff, AppRoutes.tables), isTrue);
      expect(StaffPermissions.canViewRoute(staff, AppRoutes.billing), isFalse);
    });
  });

  group('custom permissions override role defaults', () {
    test('waiter with custom billing access', () {
      final staff = makeStaff(
        role: StaffRole.waiter,
        permissions: {
          AppRoutes.billing: ['view', 'create'],
          AppRoutes.tables: ['view'],
        },
      );
      expect(StaffPermissions.canAccess(staff, AppRoutes.billing), isTrue);
      expect(
        StaffPermissions.hasAction(
          staff,
          AppRoutes.billing,
          PermissionAction.create,
        ),
        isTrue,
      );
      // Custom perms don't include kitchen, so waiter loses default kitchen
      expect(StaffPermissions.canAccess(staff, AppRoutes.kitchen), isFalse);
    });

    test('custom empty permissions means no access', () {
      final staff = makeStaff(role: StaffRole.manager, permissions: {});
      expect(StaffPermissions.canAccess(staff, AppRoutes.billing), isFalse);
    });
  });
}

/// Custom matcher for sorted list
class _IsSorted extends Matcher {
  const _IsSorted();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! List<int>) return false;
    for (var i = 1; i < item.length; i++) {
      if (item[i] < item[i - 1]) return false;
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('is sorted in ascending order');
}

const Matcher isSorted = _IsSorted();
