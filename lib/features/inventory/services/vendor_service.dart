/// Vendor management service
library;

import 'dart:async';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/features/permissions/services/module_mutation_guard.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/vendor_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class VendorService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _vendorsRef =>
      _firestore.collection('$_basePath/vendors');

  /// Firestore writes should not block UX in offline/flaky networks.
  /// If the write doesn't resolve quickly, we assume it is queued locally.
  static Future<void> _commitWithOfflineFallback(Future<void> write) async {
    try {
      await write.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      debugPrint('⚠️ Vendor write timed out; treating as queued local write');
    }
  }

  /// Stream all vendors
  static Stream<List<VendorModel>> vendorsStream() {
    return _vendorsRef.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => VendorModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream active vendors only
  static Stream<List<VendorModel>> activeVendorsStream() {
    return _vendorsRef
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VendorModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get a single vendor
  static Future<VendorModel?> getVendor(String vendorId) async {
    final doc = await _vendorsRef.doc(vendorId).get();
    if (!doc.exists) return null;
    return VendorModel.fromFirestore(doc);
  }

  /// Create a vendor
  static Future<void> createVendor(VendorModel vendor) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.vendors,
      PermissionAction.create,
    );
    await _commitWithOfflineFallback(
      _vendorsRef.doc(vendor.id).set(vendor.toFirestore()),
    );
  }

  /// Update a vendor
  static Future<void> updateVendor(VendorModel vendor) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.vendors,
      PermissionAction.update,
    );
    await _commitWithOfflineFallback(
      _vendorsRef.doc(vendor.id).update(vendor.toFirestore()),
    );
  }

  /// Delete a vendor
  static Future<void> deleteVendor(String vendorId) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.vendors,
      PermissionAction.delete,
    );
    await _vendorsRef.doc(vendorId).delete();
  }
}
