/// Vendor management service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/vendor_model.dart';

class VendorService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _vendorsRef =>
      _firestore.collection('$_basePath/vendors');

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
    await _vendorsRef.doc(vendor.id).set(vendor.toFirestore());
  }

  /// Update a vendor
  static Future<void> updateVendor(VendorModel vendor) async {
    await _vendorsRef.doc(vendor.id).update(vendor.toFirestore());
  }

  /// Delete a vendor
  static Future<void> deleteVendor(String vendorId) async {
    await _vendorsRef.doc(vendorId).delete();
  }
}
