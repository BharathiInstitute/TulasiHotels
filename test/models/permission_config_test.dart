/// Tests for PermissionConfig — role templates, category grouping,
/// route resolution, permission action enums.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

void main() {
  group('PermissionAction', () {
    test('has 4 values', () {
      expect(PermissionAction.values.length, 4);
    });

    test('keys are view, create, update, delete', () {
      expect(PermissionAction.view.key, 'view');
      expect(PermissionAction.create.key, 'create');
      expect(PermissionAction.update.key, 'update');
      expect(PermissionAction.delete.key, 'delete');
    });

    test('labels are capitalized', () {
      expect(PermissionAction.view.label, 'View');
      expect(PermissionAction.delete.label, 'Delete');
    });
  });

  group('ScreenDef', () {
    test('stores route, label, category', () {
      const def = ScreenDef(
        route: '/test',
        label: 'Test Screen',
        category: 'Core',
      );
      expect(def.route, '/test');
      expect(def.label, 'Test Screen');
      expect(def.category, 'Core');
    });

    test('defaults to full CRUD supported actions', () {
      const def = ScreenDef(
        route: '/test',
        label: 'Test Screen',
        category: 'Core',
      );
      expect(def.supportedActionKeys, ['view', 'create', 'update', 'delete']);
    });
  });

  group('PermissionConfig.categories', () {
    test('has 8 categories', () {
      expect(PermissionConfig.categories.length, 8);
    });

    test('includes Core and Compliance', () {
      expect(PermissionConfig.categories, contains('Core'));
      expect(PermissionConfig.categories, contains('Compliance'));
    });
  });

  group('PermissionConfig.allScreens', () {
    test('has at least 27 screens', () {
      expect(PermissionConfig.allScreens.length, greaterThanOrEqualTo(27));
    });

    test('every screen has a non-empty route starting with /', () {
      for (final s in PermissionConfig.allScreens) {
        expect(s.route, startsWith('/'), reason: '${s.label} route invalid');
      }
    });

    test('every screen belongs to a known category', () {
      for (final s in PermissionConfig.allScreens) {
        expect(
          PermissionConfig.categories,
          contains(s.category),
          reason: '${s.label} has unknown category ${s.category}',
        );
      }
    });

    test('view-only modules only expose view action', () {
      expect(
        PermissionConfig.screenForRoute(AppRoutes.dashboard)?.supportedActionKeys,
        ['view'],
      );
      expect(
        PermissionConfig.screenForRoute(AppRoutes.advancedReports)
            ?.supportedActionKeys,
        ['view'],
      );
    });

    test('partial modules expose only supported actions', () {
      expect(
        PermissionConfig.screenForRoute(AppRoutes.kitchen)?.supportedActionKeys,
        ['view', 'update'],
      );
      expect(
        PermissionConfig.screenForRoute(AppRoutes.wastage)?.supportedActionKeys,
        ['view', 'create'],
      );
    });
  });

  group('PermissionConfig.screensForCategory', () {
    test('Core category has multiple screens', () {
      final core = PermissionConfig.screensForCategory('Core');
      expect(core.length, greaterThanOrEqualTo(4));
      expect(core.any((s) => s.route == AppRoutes.billing), isTrue);
    });

    test('unknown category returns empty', () {
      expect(PermissionConfig.screensForCategory('Nonexistent'), isEmpty);
    });

    test('every category has at least one screen', () {
      for (final cat in PermissionConfig.categories) {
        expect(
          PermissionConfig.screensForCategory(cat),
          isNotEmpty,
          reason: '$cat has no screens',
        );
      }
    });
  });

  group('PermissionConfig.defaultTemplate', () {
    test('manager gets all screens with each screen\'s supported actions', () {
      final perms = PermissionConfig.defaultTemplate(StaffRole.manager);
      expect(perms.length, PermissionConfig.allScreens.length);
      for (final screen in PermissionConfig.allScreens) {
        expect(
          perms[screen.route],
          equals(screen.supportedActionKeys),
          reason: '${screen.route} should match supported actions',
        );
      }
    });

    test('cashier has billing with full CRUD', () {
      final perms = PermissionConfig.defaultTemplate(StaffRole.cashier);
      expect(
        perms[AppRoutes.billing],
        containsAll(['view', 'create', 'update', 'delete']),
      );
    });

    test('cashier has khata with full CRUD', () {
      final perms = PermissionConfig.defaultTemplate(StaffRole.cashier);
      expect(perms[AppRoutes.khata], isNotNull);
    });

    test('cashier does NOT have kitchen access', () {
      final perms = PermissionConfig.defaultTemplate(StaffRole.cashier);
      expect(perms.containsKey(AppRoutes.kitchen), isFalse);
    });

    test('waiter has tables and orders', () {
      final perms = PermissionConfig.defaultTemplate(StaffRole.waiter);
      expect(perms.containsKey(AppRoutes.tables), isTrue);
      expect(perms.containsKey(AppRoutes.orders), isTrue);
    });

    test('waiter does NOT have billing', () {
      final perms = PermissionConfig.defaultTemplate(StaffRole.waiter);
      expect(perms.containsKey(AppRoutes.billing), isFalse);
    });

    test('chef has kitchen and orders', () {
      final perms = PermissionConfig.defaultTemplate(StaffRole.chef);
      expect(perms.containsKey(AppRoutes.kitchen), isTrue);
      expect(perms.containsKey(AppRoutes.orders), isTrue);
    });

    test('chef has ingredients view', () {
      final perms = PermissionConfig.defaultTemplate(StaffRole.chef);
      expect(perms[AppRoutes.ingredients], contains('view'));
    });

    test('chef does NOT have billing or staff', () {
      final perms = PermissionConfig.defaultTemplate(StaffRole.chef);
      expect(perms.containsKey(AppRoutes.billing), isFalse);
      expect(perms.containsKey(AppRoutes.staff), isFalse);
    });

    test('all roles include myAttendance', () {
      for (final role in StaffRole.values) {
        final perms = PermissionConfig.defaultTemplate(role);
        expect(
          perms.containsKey(AppRoutes.myAttendance),
          isTrue,
          reason: '$role missing myAttendance',
        );
      }
    });

    test('attendance is only included for roles that manage attendance', () {
      expect(
        PermissionConfig.defaultTemplate(StaffRole.manager)
            .containsKey(AppRoutes.attendance),
        isTrue,
      );
      expect(
        PermissionConfig.defaultTemplate(StaffRole.cashier)
            .containsKey(AppRoutes.attendance),
        isFalse,
      );
      expect(
        PermissionConfig.defaultTemplate(StaffRole.waiter)
            .containsKey(AppRoutes.attendance),
        isFalse,
      );
      expect(
        PermissionConfig.defaultTemplate(StaffRole.chef)
            .containsKey(AppRoutes.attendance),
        isFalse,
      );
    });
  });

  group('PermissionConfig.normalizePermissions', () {
    test('removes unsupported actions from known routes', () {
      final normalized = PermissionConfig.normalizePermissions({
        AppRoutes.dashboard: ['view', 'create', 'delete'],
        AppRoutes.kitchen: ['view', 'create', 'update'],
      });

      expect(normalized[AppRoutes.dashboard], ['view']);
      expect(normalized[AppRoutes.kitchen], ['view', 'update']);
    });

    test('preserves unknown routes', () {
      final normalized = PermissionConfig.normalizePermissions({
        '/custom-route': ['view', 'create'],
      });

      expect(normalized['/custom-route'], ['view', 'create']);
    });
  });

  group('PermissionConfig.resolvePermissionRoute', () {
    test('child route resolves to parent', () {
      expect(
        PermissionConfig.resolvePermissionRoute(AppRoutes.orderDetail),
        AppRoutes.orders,
      );
    });

    test('newOrder resolves to orders', () {
      expect(
        PermissionConfig.resolvePermissionRoute(AppRoutes.newOrder),
        AppRoutes.orders,
      );
    });

    test('productDetail resolves to products', () {
      expect(
        PermissionConfig.resolvePermissionRoute(AppRoutes.productDetail),
        AppRoutes.products,
      );
    });

    test('customerDetail resolves to khata', () {
      expect(
        PermissionConfig.resolvePermissionRoute(AppRoutes.customerDetail),
        AppRoutes.khata,
      );
    });

    test('parent route resolves to itself', () {
      expect(
        PermissionConfig.resolvePermissionRoute(AppRoutes.billing),
        AppRoutes.billing,
      );
    });

    test('unknown route resolves to itself', () {
      expect(PermissionConfig.resolvePermissionRoute('/random'), '/random');
    });

    test('report sub-routes resolve to advancedReports', () {
      expect(
        PermissionConfig.resolvePermissionRoute(AppRoutes.menuPerformance),
        AppRoutes.advancedReports,
      );
      expect(
        PermissionConfig.resolvePermissionRoute(AppRoutes.weeklyReport),
        AppRoutes.advancedReports,
      );
    });
  });
}
