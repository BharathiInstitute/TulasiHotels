/// Complaint management service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/services/module_mutation_guard.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/complaint_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class ComplaintService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _complaintsRef =>
      _firestore.collection('$_basePath/complaints');

  /// Stream active complaints
  static Stream<List<ComplaintModel>> activeComplaintsStream() {
    return _complaintsRef
        .where('status', whereIn: ['open', 'investigating'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ComplaintModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream all complaints
  static Stream<List<ComplaintModel>> allComplaintsStream() {
    return _complaintsRef
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ComplaintModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Create a complaint
  static Future<void> createComplaint(
    ComplaintModel complaint,
    RoutePermissionState permissions,
  ) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.complaints,
      PermissionAction.create,
    );
    if (!permissions.canCreate) {
      throw StateError(
        PermissionCenter.deniedActionMessage(
          AppRoutes.complaints,
          PermissionAction.create,
        ),
      );
    }
    await _complaintsRef
        .doc(complaint.id)
        .set(complaint.toFirestore());
  }

  /// Update complaint status
  static Future<void> updateStatus(
    String complaintId,
    ComplaintStatus status,
    RoutePermissionState permissions,
  ) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.complaints,
      PermissionAction.update,
    );
    if (!permissions.canUpdate) {
      throw StateError(
        PermissionCenter.deniedActionMessage(
          AppRoutes.complaints,
          PermissionAction.update,
        ),
      );
    }
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == ComplaintStatus.resolved) {
      updates['resolvedAt'] = FieldValue.serverTimestamp();
    }
    await _complaintsRef.doc(complaintId).update(updates);
  }

  /// Update a complaint
  static Future<void> updateComplaint(
    ComplaintModel complaint,
    RoutePermissionState permissions,
  ) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.complaints,
      PermissionAction.update,
    );
    if (!permissions.canUpdate) {
      throw StateError(
        PermissionCenter.deniedActionMessage(
          AppRoutes.complaints,
          PermissionAction.update,
        ),
      );
    }
    await _complaintsRef
        .doc(complaint.id)
        .update(complaint.toFirestore());
  }

  /// Delete a complaint
  static Future<void> deleteComplaint(
    String complaintId,
    RoutePermissionState permissions,
  ) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.complaints,
      PermissionAction.delete,
    );
    if (!permissions.canDelete) {
      throw StateError(
        PermissionCenter.deniedActionMessage(
          AppRoutes.complaints,
          PermissionAction.delete,
        ),
      );
    }
    await _complaintsRef.doc(complaintId).delete();
  }
}
