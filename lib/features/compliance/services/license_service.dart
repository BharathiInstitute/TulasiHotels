/// License and compliance tracking service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/license_model.dart';

class LicenseService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _licensesRef =>
      _firestore.collection('$_basePath/licenses');

  /// Stream all licenses
  static Stream<List<LicenseModel>> licensesStream() {
    return _licensesRef.orderBy('expiryDate').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => LicenseModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream licenses expiring soon (within 30 days)
  static Stream<List<LicenseModel>> expiringLicensesStream() {
    final thirtyDaysFromNow =
        DateTime.now().add(const Duration(days: 30));

    return _licensesRef
        .where('expiryDate',
            isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysFromNow))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LicenseModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Create a license
  static Future<void> createLicense(LicenseModel license) async {
    await _licensesRef.doc(license.id).set(license.toFirestore());
  }

  /// Update a license
  static Future<void> updateLicense(LicenseModel license) async {
    await _licensesRef.doc(license.id).update(license.toFirestore());
  }

  /// Renew a license (update issue and expiry dates)
  static Future<void> renewLicense(
    String licenseId, {
    required DateTime newIssueDate,
    required DateTime newExpiryDate,
    String? newLicenseNumber,
  }) async {
    await _licensesRef.doc(licenseId).update({
      'issueDate': Timestamp.fromDate(newIssueDate),
      'expiryDate': Timestamp.fromDate(newExpiryDate),
      'licenseNumber': newLicenseNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a license
  static Future<void> deleteLicense(String licenseId) async {
    await _licensesRef.doc(licenseId).delete();
  }
}
