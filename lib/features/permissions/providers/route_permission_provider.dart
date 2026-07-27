library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/admin/providers/current_member_provider.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';
import 'package:tulasihotels/features/permissions/permission_panel.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';

final routePermissionProvider =
    Provider.family<RoutePermissionState, String>((ref, route) {
      final staff = ref.watch(loggedInStaffProvider);

      final authUser = FirebaseAuth.instance.currentUser;
      final storeId = ref.watch(currentHotelIdProvider);

      if (authUser == null || storeId == null) {
        return PermissionCenter.resolveRouteState(
          route: PermissionPanels.resolvePanelRoute(route),
          contextResolved: false,
          isOwner: false,
          staff: staff,
          member: null,
        );
      }

      final currentHotel = ref.watch(currentHotelProvider);
      final isOwner = currentHotel?.isOwner == true || storeId == authUser.uid;
      final resolvedRoute = PermissionPanels.resolvePanelRoute(route);

      final memberAsync = ref.watch(currentMemberProvider);
      if (memberAsync.isLoading) {
        return PermissionCenter.resolveRouteState(
          route: resolvedRoute,
          contextResolved: false,
          isOwner: isOwner,
          staff: staff,
          member: null,
        );
      }

      return PermissionCenter.resolveRouteState(
        route: resolvedRoute,
        contextResolved: true,
        isOwner: isOwner,
        staff: staff,
        member: memberAsync.valueOrNull,
      );
    });