library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/models/store_role.dart';
import 'package:tulasihotels/features/admin/services/member_permission_guard.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('PermissionCenter.resolveRouteState', () {
    test('returns unresolved state when context is not ready', () {
      final state = PermissionCenter.resolveRouteState(
        route: AppRoutes.billing,
        contextResolved: false,
        isOwner: false,
      );

      expect(state.isResolved, isFalse);
      expect(state.canView, isFalse);
      expect(state.canCreate, isFalse);
      expect(state.canUpdate, isFalse);
      expect(state.canDelete, isFalse);
    });

    test('owner has full access', () {
      final state = PermissionCenter.resolveRouteState(
        route: AppRoutes.products,
        contextResolved: true,
        isOwner: true,
      );

      expect(state.isResolved, isTrue);
      expect(state.canView, isTrue);
      expect(state.canCreate, isTrue);
      expect(state.canUpdate, isTrue);
      expect(state.canDelete, isTrue);
    });

    test('staff custom permissions drive action state', () {
      final staff = makeStaff(
        role: StaffRole.waiter,
        permissions: {
          AppRoutes.orders: [
            PermissionAction.view.key,
            PermissionAction.create.key,
          ],
        },
      );

      final state = PermissionCenter.resolveRouteState(
        route: AppRoutes.orders,
        contextResolved: true,
        isOwner: false,
        staff: staff,
      );

      expect(state.canView, isTrue);
      expect(state.canCreate, isTrue);
      expect(state.canUpdate, isFalse);
      expect(state.canDelete, isFalse);
    });

    test('member minimal baseline is deny-by-default except my attendance', () {
      final member = StoreMember(
        uid: 'u1',
        email: 'staff@example.com',
        displayName: 'Staff Member',
        role: StoreRole.staff,
        joinedAt: DateTime(2024, 1, 1),
      );

      final billingState = PermissionCenter.resolveRouteState(
        route: AppRoutes.billing,
        contextResolved: true,
        isOwner: false,
        member: member,
      );
      final attendanceState = PermissionCenter.resolveRouteState(
        route: AppRoutes.myAttendance,
        contextResolved: true,
        isOwner: false,
        member: member,
      );

      expect(billingState.canView, isFalse);
      expect(attendanceState.canView, isTrue);
    });

    test('owner member role defaults provide full access', () {
      final ownerMember = StoreMember(
        uid: 'owner-uid',
        email: 'owner@example.com',
        displayName: 'Owner',
        role: StoreRole.owner,
        joinedAt: DateTime(2024, 1, 1),
      );

      final products = PermissionCenter.resolveRouteState(
        route: AppRoutes.products,
        contextResolved: true,
        isOwner: false,
        member: ownerMember,
      );

      expect(products.canView, isTrue);
      expect(products.canCreate, isTrue);
      expect(products.canUpdate, isTrue);
      expect(products.canDelete, isTrue);
    });

    test('panel permission grants access to mapped child route', () {
      final staff = makeStaff(
        role: StaffRole.waiter,
        permissions: {
          AppRoutes.advancedReports: [PermissionAction.view.key],
        },
      );

      final canView = PermissionCenter.canView(
        route: AppRoutes.menuPerformance,
        isOwner: false,
        staff: staff,
      );

      expect(canView, isTrue);
    });

    test('panel permission grants CRUD action across mapped route', () {
      final staff = makeStaff(
        role: StaffRole.waiter,
        permissions: {
          AppRoutes.products: [
            PermissionAction.view.key,
            PermissionAction.update.key,
          ],
        },
      );

      final canUpdate = PermissionCenter.hasAction(
        route: AppRoutes.combos,
        action: PermissionAction.update,
        isOwner: false,
        staff: staff,
      );

      expect(canUpdate, isTrue);
    });

    test('panel action deny applies to nested route when not granted', () {
      final staff = makeStaff(
        role: StaffRole.waiter,
        permissions: {
          AppRoutes.orders: [PermissionAction.view.key],
        },
      );

      final canDelete = PermissionCenter.hasAction(
        route: AppRoutes.orderDetail,
        action: PermissionAction.delete,
        isOwner: false,
        staff: staff,
      );

      expect(canDelete, isFalse);
    });
  });

  group('PermissionCenter.messages', () {
    test('denied view message includes action and route label', () {
      final msg = PermissionCenter.deniedViewMessage(AppRoutes.khata);
      expect(msg, startsWith('You do not have permission to view'));
      expect(msg, contains('Khata'));
    });

    test('denied action message includes action label', () {
      final msg = PermissionCenter.deniedActionMessage(
        AppRoutes.products,
        PermissionAction.delete,
      );
      expect(msg, startsWith('You do not have permission to delete'));
      expect(msg, contains('Products'));
    });
  });

  group('PermissionCenter.homeRoute and nav visibility', () {
    test('staff home route falls back to first accessible nav route', () {
      final staff = makeStaff(
        role: StaffRole.waiter,
        permissions: {
          AppRoutes.orders: [PermissionAction.view.key],
        },
      );

      final home = PermissionCenter.homeRoute(
        isOwner: false,
        staff: staff,
      );

      expect(home, AppRoutes.orders);
    });

    test('member accountant prefers dashboard when allowed', () {
      final member = StoreMember(
        uid: 'u2',
        email: 'acct@example.com',
        displayName: 'Accountant',
        role: StoreRole.accountant,
        joinedAt: DateTime(2024, 1, 1),
        permissions: {
          AppRoutes.dashboard: [PermissionAction.view.key],
        },
      );

      final home = PermissionCenter.homeRoute(
        isOwner: false,
        member: member,
      );

      expect(home, AppRoutes.dashboard);
    });

    test('owner nav indices include all shell sections', () {
      final indices = PermissionCenter.visibleNavIndices(
        isOwner: true,
      );

      expect(indices, contains(0));
      expect(indices, contains(9));
      expect(indices.length, greaterThanOrEqualTo(10));
    });

    test('member guard wrapper mirrors center', () {
      final member = StoreMember(
        uid: 'm1',
        email: 'member@example.com',
        displayName: 'Member',
        role: StoreRole.cashier,
        joinedAt: DateTime(2024, 1, 1),
      );

      expect(
        MemberPermissionGuard.canAccess(member, AppRoutes.billing),
        PermissionCenter.canView(
          route: AppRoutes.billing,
          isOwner: false,
          member: member,
        ),
      );
      expect(
        MemberPermissionGuard.hasAction(
          member,
          AppRoutes.billing,
          PermissionAction.create,
        ),
        PermissionCenter.hasAction(
          route: AppRoutes.billing,
          action: PermissionAction.create,
          isOwner: false,
          member: member,
        ),
      );
      expect(
        MemberPermissionGuard.homeRoute(member),
        PermissionCenter.homeRoute(isOwner: false, member: member),
      );
    });
  });
}
