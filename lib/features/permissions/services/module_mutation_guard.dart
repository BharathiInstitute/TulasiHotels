library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:tulasihotels/core/services/offline_storage_service.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/permission_panel.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/staff_model.dart';

class ModulePermissionDenied implements Exception {
  final String message;

  const ModulePermissionDenied(this.message);

  @override
  String toString() => message;
}

class ModuleActionRequirement {
  final String route;
  final PermissionAction action;

  const ModuleActionRequirement({required this.route, required this.action});
}

/// Service-layer permission checks for mutations.
///
/// This prevents direct service calls from bypassing screen-level checks.
class ModuleMutationGuard {
  ModuleMutationGuard._();

  static Future<void> requireAction(
    String route,
    PermissionAction action,
  ) async {
    await requireAnyAction([
      ModuleActionRequirement(route: route, action: action),
    ]);
  }

  static Future<void> requireAnyAction(
    List<ModuleActionRequirement> requirements,
  ) async {
    if (requirements.isEmpty) {
      throw const ModulePermissionDenied('No permission requirement provided.');
    }

    final storeId = ActiveStoreManager.storeId;
    if (storeId == null || storeId.isEmpty) {
      throw const ModulePermissionDenied('No active store selected.');
    }

    final staff = _readLoggedInStaff();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ModulePermissionDenied('You must be signed in.');
    }

    // When a staff session is active, enforce staff/member permissions.
    final isOwner = staff == null && storeId == user.uid;

    StoreMember? member;
    if (!isOwner && staff == null) {
      final memberDoc = await FirebaseFirestore.instance
          .collection('users/$storeId/members')
          .doc(user.uid)
          .get();

      if (!memberDoc.exists) {
        throw ModulePermissionDenied(_deniedMessageForAny(requirements));
      }
      member = StoreMember.fromFirestore(memberDoc);
    }

    final normalizedRequirements = requirements
        .map(_normalizeRequirement)
        .toList(growable: false);

    final isAllowed = normalizedRequirements.any(
      (requirement) => PermissionCenter.hasAction(
        route: requirement.route,
        action: requirement.action,
        isOwner: isOwner,
        staff: staff,
        member: member,
      ),
    );
    if (!isAllowed) {
      throw ModulePermissionDenied(
        _deniedMessageForAny(normalizedRequirements),
      );
    }
  }

  static ModuleActionRequirement _normalizeRequirement(
    ModuleActionRequirement requirement,
  ) {
    final normalizedRoute = PermissionPanels.resolvePanelRoute(
      PermissionConfig.resolvePermissionRoute(requirement.route),
    );
    return ModuleActionRequirement(
      route: normalizedRoute,
      action: requirement.action,
    );
  }

  static StaffModel? _readLoggedInStaff() {
    try {
      final json = OfflineStorageService.prefs?.getString(
        'logged_in_staff_session',
      );
      if (json == null || json.isEmpty) return null;
      return StaffModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static String _deniedMessage(String route, PermissionAction action) {
    return PermissionCenter.deniedActionMessage(route, action);
  }

  static String _deniedMessageForAny(
    List<ModuleActionRequirement> requirements,
  ) {
    if (requirements.length == 1) {
      final requirement = requirements.first;
      return _deniedMessage(requirement.route, requirement.action);
    }

    final labels = requirements
        .map(
          (requirement) =>
              PermissionPanels.panelLabelForRoute(requirement.route),
        )
        .toSet()
        .join(' or ');
    return 'You do not have permission to perform this action in $labels.';
  }
}