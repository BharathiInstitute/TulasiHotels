/// Integration test: Route guards — auth, admin, staff, public routes
///
/// Tests the route classification logic used by the GoRouter redirect:
/// auth routes, public routes, super admin routes, staff permission checks.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/services/staff_permissions.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  // ── Route classification helpers (mirror redirect logic from app_router) ──
  bool isAuthRoute(String path) {
    return path == AppRoutes.login ||
        path == AppRoutes.register ||
        path == AppRoutes.forgotPassword ||
        path == AppRoutes.superAdminLogin ||
        path == '/desktop-login';
  }

  bool isPublicRoute(String path) {
    return path.startsWith('/menu/') ||
        path.startsWith('/order/') ||
        path.startsWith('/rate/') ||
        path.startsWith('/reserve/');
  }

  bool isSuperAdminRoute(String path) {
    return path.startsWith('/super-admin');
  }

  group('Route Guard: Auth route classification', () {
    test('login is auth route', () {
      expect(isAuthRoute(AppRoutes.login), isTrue);
    });

    test('register is auth route', () {
      expect(isAuthRoute(AppRoutes.register), isTrue);
    });

    test('forgot password is auth route', () {
      expect(isAuthRoute(AppRoutes.forgotPassword), isTrue);
    });

    test('super admin login is auth route', () {
      expect(isAuthRoute(AppRoutes.superAdminLogin), isTrue);
    });

    test('desktop-login is auth route', () {
      expect(isAuthRoute('/desktop-login'), isTrue);
    });

    test('billing is NOT auth route', () {
      expect(isAuthRoute(AppRoutes.billing), isFalse);
    });

    test('products is NOT auth route', () {
      expect(isAuthRoute(AppRoutes.products), isFalse);
    });

    test('staff-login is NOT auth route', () {
      // Staff login is handled separately in redirect logic
      expect(isAuthRoute(AppRoutes.staffLogin), isFalse);
    });
  });

  group('Route Guard: Public route classification', () {
    test('customer menu is public', () {
      expect(isPublicRoute('/menu/hotel123'), isTrue);
    });

    test('customer order is public', () {
      expect(isPublicRoute('/order/hotel123'), isTrue);
    });

    test('customer rating is public', () {
      expect(isPublicRoute('/rate/hotel123'), isTrue);
    });

    test('customer reservation is public', () {
      expect(isPublicRoute('/reserve/hotel123'), isTrue);
    });

    test('customer order status is public', () {
      expect(isPublicRoute('/menu/hotel123/order/ord123/status'), isTrue);
    });

    test('billing is NOT public', () {
      expect(isPublicRoute(AppRoutes.billing), isFalse);
    });

    test('login is NOT public', () {
      expect(isPublicRoute(AppRoutes.login), isFalse);
    });
  });

  group('Route Guard: Super admin route classification', () {
    test('super admin dashboard is admin route', () {
      expect(isSuperAdminRoute(AppRoutes.superAdmin), isTrue);
    });

    test('super admin login is admin route', () {
      expect(isSuperAdminRoute(AppRoutes.superAdminLogin), isTrue);
    });

    test('super admin users is admin route', () {
      expect(isSuperAdminRoute(AppRoutes.superAdminUsers), isTrue);
    });

    test('super admin sub-routes are admin routes', () {
      expect(isSuperAdminRoute(AppRoutes.superAdminAnalytics), isTrue);
      expect(isSuperAdminRoute(AppRoutes.superAdminErrors), isTrue);
      expect(isSuperAdminRoute(AppRoutes.superAdminPerformance), isTrue);
      expect(isSuperAdminRoute(AppRoutes.superAdminUserCosts), isTrue);
      expect(isSuperAdminRoute(AppRoutes.superAdminManageAdmins), isTrue);
      expect(isSuperAdminRoute(AppRoutes.superAdminNotifications), isTrue);
    });

    test('billing is NOT admin route', () {
      expect(isSuperAdminRoute(AppRoutes.billing), isFalse);
    });
  });

  group('Route Guard: Staff permission redirect simulation', () {
    test('unauthenticated staff → redirected from restricted routes', () {
      final waiter = makeStaff();

      // Waiter tries to access billing → blocked
      final canAccessBilling = StaffPermissions.canAccess(
        waiter,
        AppRoutes.billing,
      );
      expect(canAccessBilling, isFalse);
      // Redirect target would be home route
      expect(StaffPermissions.homeRoute(waiter), AppRoutes.tables);
    });

    test('staff can always access attendance routes', () {
      // The router has special bypass for attendance routes
      final waiter = makeStaff();
      expect(StaffPermissions.canAccess(waiter, AppRoutes.attendance), isTrue);
      expect(
        StaffPermissions.canAccess(waiter, AppRoutes.myAttendance),
        isTrue,
      );
    });

    test('chef blocked from billing → redirects to kitchen', () {
      final chef = makeStaff(role: StaffRole.chef, pin: '5678');
      expect(StaffPermissions.canAccess(chef, AppRoutes.billing), isFalse);
      expect(StaffPermissions.homeRoute(chef), AppRoutes.kitchen);
    });

    test('manager has access to all core routes', () {
      final manager = makeStaff(role: StaffRole.manager, pin: '0000');
      expect(StaffPermissions.canAccess(manager, AppRoutes.billing), isTrue);
      expect(StaffPermissions.canAccess(manager, AppRoutes.products), isTrue);
      expect(StaffPermissions.canAccess(manager, AppRoutes.staff), isTrue);
      expect(StaffPermissions.canAccess(manager, AppRoutes.kitchen), isTrue);
    });

    test('owner (null staff) can view all routes', () {
      // canViewRoute(null, ...) = true for owners
      expect(StaffPermissions.canViewRoute(null, AppRoutes.billing), isTrue);
      expect(StaffPermissions.canViewRoute(null, AppRoutes.staff), isTrue);
      expect(
        StaffPermissions.canViewRoute(null, AppRoutes.advancedReports),
        isTrue,
      );
    });
  });

  group('Route Guard: Route path validity', () {
    test('all AppRoutes start with /', () {
      final routes = [
        AppRoutes.loading,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.shopSetup,
        AppRoutes.billing,
        AppRoutes.khata,
        AppRoutes.products,
        AppRoutes.dashboard,
        AppRoutes.bills,
        AppRoutes.tables,
        AppRoutes.orders,
        AppRoutes.kitchen,
        AppRoutes.staff,
        AppRoutes.attendance,
        AppRoutes.myAttendance,
        AppRoutes.combos,
        AppRoutes.dailySpecials,
        AppRoutes.reservations,
        AppRoutes.coupons,
        AppRoutes.shifts,
        AppRoutes.tasks,
        AppRoutes.messages,
        AppRoutes.cashRegister,
        AppRoutes.feedback,
        AppRoutes.ingredients,
        AppRoutes.vendors,
        AppRoutes.wastage,
        AppRoutes.gstExport,
        AppRoutes.advancedReports,
        AppRoutes.licenses,
        AppRoutes.equipment,
        AppRoutes.complaints,
        AppRoutes.events,
        AppRoutes.salary,
        AppRoutes.feedbackDashboard,
        AppRoutes.notifications,
      ];

      for (final route in routes) {
        expect(
          route,
          startsWith('/'),
          reason: 'Route should start with /: $route',
        );
      }
    });

    test('parameterized routes contain :id or :hotelId', () {
      expect(AppRoutes.customerDetail, contains(':id'));
      expect(AppRoutes.productDetail, contains(':id'));
      expect(AppRoutes.orderDetail, contains(':id'));
      expect(AppRoutes.settingsTab, contains(':tab'));
      expect(AppRoutes.customerMenu, contains(':hotelId'));
      expect(AppRoutes.customerFeedback, contains(':hotelId'));
    });

    test('no duplicate route paths', () {
      final routes = [
        AppRoutes.billing,
        AppRoutes.khata,
        AppRoutes.products,
        AppRoutes.dashboard,
        AppRoutes.bills,
        AppRoutes.tables,
        AppRoutes.orders,
        AppRoutes.kitchen,
        AppRoutes.staff,
        AppRoutes.attendance,
        AppRoutes.myAttendance,
        AppRoutes.combos,
        AppRoutes.dailySpecials,
        AppRoutes.reservations,
        AppRoutes.coupons,
        AppRoutes.shifts,
        AppRoutes.tasks,
        AppRoutes.messages,
        AppRoutes.cashRegister,
        AppRoutes.feedback,
        AppRoutes.ingredients,
        AppRoutes.vendors,
        AppRoutes.wastage,
        AppRoutes.gstExport,
        AppRoutes.advancedReports,
        AppRoutes.licenses,
        AppRoutes.equipment,
        AppRoutes.complaints,
        AppRoutes.events,
        AppRoutes.salary,
        AppRoutes.feedbackDashboard,
      ];

      final unique = routes.toSet();
      expect(unique.length, routes.length, reason: 'No duplicate routes');
    });
  });
}
