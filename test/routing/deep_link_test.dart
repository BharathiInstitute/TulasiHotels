/// Integration test: All AppRoutes constants resolve correctly
///
/// Verifies all 40+ route constants are valid paths, cover all features,
/// and have correct parameter patterns.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/router/app_router.dart';

void main() {
  group('Deep Link: Shell routes (main app)', () {
    test('core business routes exist', () {
      expect(AppRoutes.billing, '/billing');
      expect(AppRoutes.khata, '/khata');
      expect(AppRoutes.products, '/products');
      expect(AppRoutes.dashboard, '/dashboard');
      expect(AppRoutes.bills, '/bills');
    });

    test('hotel feature routes exist', () {
      expect(AppRoutes.tables, '/tables');
      expect(AppRoutes.orders, '/orders');
      expect(AppRoutes.kitchen, '/kitchen');
    });

    test('staff management routes exist', () {
      expect(AppRoutes.staff, '/staff');
      expect(AppRoutes.staffLogin, '/staff-login');
      expect(AppRoutes.attendance, '/attendance');
      expect(AppRoutes.myAttendance, '/my-attendance');
    });

    test('new feature routes exist', () {
      expect(AppRoutes.combos, '/combos');
      expect(AppRoutes.dailySpecials, '/daily-specials');
      expect(AppRoutes.tableLayout, '/table-layout');
      expect(AppRoutes.reservations, '/reservations');
      expect(AppRoutes.coupons, '/coupons');
      expect(AppRoutes.shifts, '/shifts');
      expect(AppRoutes.tasks, '/tasks');
      expect(AppRoutes.messages, '/messages');
      expect(AppRoutes.cashRegister, '/cash-register');
      expect(AppRoutes.feedback, '/feedback');
      expect(AppRoutes.feedbackDashboard, '/feedback-dashboard');
    });

    test('inventory routes exist', () {
      expect(AppRoutes.ingredients, '/ingredients');
      expect(AppRoutes.vendors, '/vendors');
      expect(AppRoutes.wastage, '/wastage');
    });

    test('reports routes exist', () {
      expect(AppRoutes.advancedReports, '/reports');
      expect(AppRoutes.gstExport, '/gst-export');
      expect(AppRoutes.menuPerformance, '/reports/menu-performance');
      expect(AppRoutes.weeklyReport, '/reports/weekly');
      expect(AppRoutes.pnlReport, '/reports/pnl');
      expect(AppRoutes.peakHours, '/reports/peak-hours');
      expect(AppRoutes.itemSales, '/reports/item-sales');
      expect(AppRoutes.comparative, '/reports/comparative');
      expect(AppRoutes.feedbackReport, '/reports/feedback');
    });

    test('compliance routes exist', () {
      expect(AppRoutes.licenses, '/licenses');
      expect(AppRoutes.equipment, '/equipment');
      expect(AppRoutes.complaints, '/complaints');
      expect(AppRoutes.events, '/events');
    });

    test('finance routes exist', () {
      expect(AppRoutes.salary, '/salary');
    });
  });

  group('Deep Link: Auth routes', () {
    test('login route', () {
      expect(AppRoutes.login, '/login');
    });

    test('register route', () {
      expect(AppRoutes.register, '/register');
    });

    test('forgot password route', () {
      expect(AppRoutes.forgotPassword, '/forgot-password');
    });

    test('loading route', () {
      expect(AppRoutes.loading, '/loading');
    });

    test('shop setup route', () {
      expect(AppRoutes.shopSetup, '/shop-setup');
    });
  });

  group('Deep Link: Settings routes', () {
    test('settings base route', () {
      expect(AppRoutes.settings, '/settings');
    });

    test('settings tab has :tab parameter', () {
      expect(AppRoutes.settingsTab, '/settings/:tab');
    });

    test('theme settings route', () {
      expect(AppRoutes.themeSettings, '/settings/theme');
    });
  });

  group('Deep Link: Parameterized routes', () {
    test('customer detail has :id', () {
      expect(AppRoutes.customerDetail, '/customer/:id');
    });

    test('product detail has :id', () {
      expect(AppRoutes.productDetail, '/product/:id');
    });

    test('order detail has :id', () {
      expect(AppRoutes.orderDetail, '/orders/:id');
    });

    test('new order route', () {
      expect(AppRoutes.newOrder, '/orders/new');
    });

    test('order billing has :id', () {
      expect(AppRoutes.orderBilling, '/orders/:id/bill');
    });

    test('split bill has :id', () {
      expect(AppRoutes.splitBill, '/orders/:id/split');
    });

    test('super admin user detail has :id', () {
      expect(AppRoutes.superAdminUserDetail, '/super-admin/users/:id');
    });
  });

  group('Deep Link: Customer-facing public routes', () {
    test('customer menu has :hotelId', () {
      expect(AppRoutes.customerMenu, '/menu/:hotelId');
    });

    test('customer order has :hotelId', () {
      expect(AppRoutes.customerOrder, '/order/:hotelId');
    });

    test('customer feedback has :hotelId', () {
      expect(AppRoutes.customerFeedback, '/rate/:hotelId');
    });

    test('customer reservation has :hotelId', () {
      expect(AppRoutes.customerReservation, '/reserve/:hotelId');
    });

    test('order status has both :hotelId and :orderId', () {
      expect(AppRoutes.customerOrderStatus, contains(':hotelId'));
      expect(AppRoutes.customerOrderStatus, contains(':orderId'));
    });
  });

  group('Deep Link: Super admin routes', () {
    test('super admin base routes', () {
      expect(AppRoutes.superAdmin, '/super-admin');
      expect(AppRoutes.superAdminLogin, '/super-admin/login');
    });

    test('super admin sub-routes', () {
      expect(AppRoutes.superAdminUsers, '/super-admin/users');
      expect(AppRoutes.superAdminSubscriptions, '/super-admin/subscriptions');
      expect(AppRoutes.superAdminAnalytics, '/super-admin/analytics');
      expect(AppRoutes.superAdminErrors, '/super-admin/errors');
      expect(AppRoutes.superAdminPerformance, '/super-admin/performance');
      expect(AppRoutes.superAdminUserCosts, '/super-admin/user-costs');
      expect(AppRoutes.superAdminManageAdmins, '/super-admin/manage-admins');
      expect(AppRoutes.superAdminNotifications, '/super-admin/notifications');
    });

    test('all super admin routes are under /super-admin', () {
      final adminRoutes = [
        AppRoutes.superAdmin,
        AppRoutes.superAdminLogin,
        AppRoutes.superAdminUsers,
        AppRoutes.superAdminUserDetail,
        AppRoutes.superAdminSubscriptions,
        AppRoutes.superAdminAnalytics,
        AppRoutes.superAdminErrors,
        AppRoutes.superAdminPerformance,
        AppRoutes.superAdminUserCosts,
        AppRoutes.superAdminManageAdmins,
        AppRoutes.superAdminNotifications,
      ];

      for (final route in adminRoutes) {
        expect(
          route,
          startsWith('/super-admin'),
          reason: '$route should be under /super-admin',
        );
      }
    });
  });

  group('Deep Link: Report sub-routes are under /reports', () {
    test('all report sub-routes start with /reports/', () {
      final reportRoutes = [
        AppRoutes.menuPerformance,
        AppRoutes.weeklyReport,
        AppRoutes.pnlReport,
        AppRoutes.peakHours,
        AppRoutes.itemSales,
        AppRoutes.comparative,
        AppRoutes.feedbackReport,
      ];

      for (final route in reportRoutes) {
        expect(
          route,
          startsWith('/reports/'),
          reason: '$route should be under /reports/',
        );
      }
    });
  });

  group('Deep Link: Notifications route', () {
    test('notifications route exists', () {
      expect(AppRoutes.notifications, '/notifications');
    });

    test('subscription route exists', () {
      expect(AppRoutes.subscription, '/subscription');
    });
  });
}
