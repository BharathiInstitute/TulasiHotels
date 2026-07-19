library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/admin/providers/current_member_provider.dart';
import 'package:tulasihotels/features/admin/services/member_permission_guard.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/services/staff_permissions.dart';

class RoutePermissionState {
  final bool isResolved;
  final bool canView;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;

  const RoutePermissionState({
    required this.isResolved,
    required this.canView,
    required this.canCreate,
    required this.canUpdate,
    required this.canDelete,
  });

  const RoutePermissionState.fullAccess()
    : isResolved = true,
      canView = true,
      canCreate = true,
      canUpdate = true,
      canDelete = true;

  const RoutePermissionState.none({this.isResolved = true})
    : canView = false,
      canCreate = false,
      canUpdate = false,
      canDelete = false;
}

final routePermissionProvider =
    Provider.family<RoutePermissionState, String>((ref, route) {
      final staff = ref.watch(loggedInStaffProvider);
      if (staff != null) {
        return RoutePermissionState(
          isResolved: true,
          canView: StaffPermissions.canAccess(staff, route),
          canCreate: StaffPermissions.hasAction(
            staff,
            route,
            PermissionAction.create,
          ),
          canUpdate: StaffPermissions.hasAction(
            staff,
            route,
            PermissionAction.update,
          ),
          canDelete: StaffPermissions.hasAction(
            staff,
            route,
            PermissionAction.delete,
          ),
        );
      }

      final authUser = FirebaseAuth.instance.currentUser;
      final storeId = ref.watch(currentHotelIdProvider);

      if (authUser == null || storeId == null) {
        return const RoutePermissionState.none(isResolved: false);
      }

      if (storeId == authUser.uid) {
        return const RoutePermissionState.fullAccess();
      }

      final memberAsync = ref.watch(currentMemberProvider);
      if (memberAsync.isLoading) {
        return const RoutePermissionState.none(isResolved: false);
      }

      final member = memberAsync.valueOrNull;
      if (member == null) {
        return const RoutePermissionState.none();
      }

      return RoutePermissionState(
        isResolved: true,
        canView: MemberPermissionGuard.canAccess(member, route),
        canCreate: MemberPermissionGuard.hasAction(
          member,
          route,
          PermissionAction.create,
        ),
        canUpdate: MemberPermissionGuard.hasAction(
          member,
          route,
          PermissionAction.update,
        ),
        canDelete: MemberPermissionGuard.hasAction(
          member,
          route,
          PermissionAction.delete,
        ),
      );
    });