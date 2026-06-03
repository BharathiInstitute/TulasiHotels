/// Tests for AdminFirestoreService — static constants, admin email validation,
/// primary owner protection, and AdminStats model.
///
/// Note: The service uses FirebaseFirestore.instance directly (static methods)
/// so we test the pure logic aspects and the AdminStats model rather than
/// CRUD operations which would require Firebase emulator.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/super_admin/models/admin_user_model.dart';
import 'package:tulasihotels/features/super_admin/services/admin_firestore_service.dart';

void main() {
  group('AdminFirestoreService constants', () {
    test('primaryOwnerEmail is set', () {
      expect(AdminFirestoreService.primaryOwnerEmail, isNotEmpty);
      expect(AdminFirestoreService.primaryOwnerEmail, contains('@'));
    });

    test('primaryOwnerEmail is lowercase', () {
      expect(
        AdminFirestoreService.primaryOwnerEmail,
        AdminFirestoreService.primaryOwnerEmail.toLowerCase(),
      );
    });
  });

  group('AdminStats', () {
    test('default constructor has all zeros', () {
      const stats = AdminStats();
      expect(stats.totalUsers, 0);
      expect(stats.freeUsers, 0);
      expect(stats.proUsers, 0);
      expect(stats.businessUsers, 0);
      expect(stats.mrr, 0);
      expect(stats.activeToday, 0);
      expect(stats.activeThisWeek, 0);
      expect(stats.activeThisMonth, 0);
      expect(stats.newUsersToday, 0);
      expect(stats.newUsersThisWeek, 0);
    });

    test('paidUsers is proUsers + businessUsers', () {
      const stats = AdminStats(proUsers: 15, businessUsers: 5);
      expect(stats.paidUsers, 20);
    });

    test('conversionRate is paidUsers / totalUsers * 100', () {
      const stats = AdminStats(totalUsers: 100, proUsers: 15, businessUsers: 5);
      expect(stats.conversionRate, 20.0);
    });

    test('conversionRate is 0 when totalUsers is 0', () {
      const stats = AdminStats(totalUsers: 0, proUsers: 5);
      expect(stats.conversionRate, 0);
    });

    test('mrr stores monthly recurring revenue', () {
      const stats = AdminStats(mrr: 2999.0);
      expect(stats.mrr, 2999.0);
    });

    test('fields with named params', () {
      const stats = AdminStats(
        totalUsers: 50,
        activeToday: 10,
        activeThisWeek: 30,
        activeThisMonth: 45,
        newUsersToday: 2,
        newUsersThisWeek: 8,
        freeUsers: 30,
        proUsers: 15,
        businessUsers: 5,
        mrr: 9470.0,
      );
      expect(stats.totalUsers, 50);
      expect(stats.activeToday, 10);
      expect(stats.activeThisWeek, 30);
      expect(stats.activeThisMonth, 45);
      expect(stats.newUsersToday, 2);
      expect(stats.newUsersThisWeek, 8);
    });

    test('paidUsers is 0 when no paid subscriptions', () {
      const stats = AdminStats(freeUsers: 100);
      expect(stats.paidUsers, 0);
    });

    test('conversionRate handles all free users', () {
      const stats = AdminStats(totalUsers: 100, freeUsers: 100);
      expect(stats.conversionRate, 0.0);
    });

    test('conversionRate handles 100% conversion', () {
      const stats = AdminStats(totalUsers: 10, proUsers: 10);
      expect(stats.conversionRate, 100.0);
    });
  });

  group('AdminUser model', () {
    test('SubscriptionPlan has 3 values', () {
      expect(SubscriptionPlan.values.length, 3);
      expect(SubscriptionPlan.values, contains(SubscriptionPlan.free));
      expect(SubscriptionPlan.values, contains(SubscriptionPlan.pro));
      expect(SubscriptionPlan.values, contains(SubscriptionPlan.business));
    });
  });
}
