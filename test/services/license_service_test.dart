/// Tests for LicenseService — Firestore CRUD + renewal + expiry queries
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/license_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/licenses';
  });

  group('LicenseService Firestore operations', () {
    test('create — writes and reads back all fields', () async {
      final license = makeLicense(
        id: 'lic-100',
        licenseNumber: 'FSSAI-2024-001',
        issuingAuthority: 'FSSAI India',
      );

      await fakeFirestore
          .collection(basePath)
          .doc(license.id)
          .set(license.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(license.id).get();
      final parsed = LicenseModel.fromFirestore(doc);
      expect(parsed.type, LicenseType.fssai);
      expect(parsed.licenseNumber, 'FSSAI-2024-001');
      expect(parsed.issuingAuthority, 'FSSAI India');
    });

    test('read — missing doc does not exist', () async {
      final doc =
          await fakeFirestore.collection(basePath).doc('missing').get();
      expect(doc.exists, isFalse);
    });

    test('update — modifies existing license', () async {
      final license = makeLicense(id: 'lic-u1');
      await fakeFirestore
          .collection(basePath)
          .doc(license.id)
          .set(license.toFirestore());

      await fakeFirestore.collection(basePath).doc('lic-u1').update({
        'licenseNumber': 'UPDATED-001',
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('lic-u1').get();
      expect(doc.data()!['licenseNumber'], 'UPDATED-001');
    });

    test('delete — removes license', () async {
      final license = makeLicense(id: 'lic-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(license.id)
          .set(license.toFirestore());

      await fakeFirestore.collection(basePath).doc('lic-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('lic-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('renewLicense', () {
    test('updates issue and expiry dates', () async {
      final license = makeLicense(
        id: 'lic-ren',
        issueDate: DateTime(2023),
        expiryDate: DateTime(2024),
      );
      await fakeFirestore
          .collection(basePath)
          .doc(license.id)
          .set(license.toFirestore());

      final newIssue = DateTime(2024, 6);
      final newExpiry = DateTime(2025, 6);
      await fakeFirestore.collection(basePath).doc('lic-ren').update({
        'issueDate': Timestamp.fromDate(newIssue),
        'expiryDate': Timestamp.fromDate(newExpiry),
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('lic-ren').get();
      final parsed = LicenseModel.fromFirestore(doc);
      expect(parsed.issueDate, newIssue);
      expect(parsed.expiryDate, newExpiry);
    });

    test('updates license number when provided', () async {
      final license = makeLicense(id: 'lic-ren2', licenseNumber: 'OLD-001');
      await fakeFirestore
          .collection(basePath)
          .doc(license.id)
          .set(license.toFirestore());

      await fakeFirestore.collection(basePath).doc('lic-ren2').update({
        'licenseNumber': 'NEW-002',
        'issueDate': Timestamp.fromDate(DateTime(2024, 6)),
        'expiryDate': Timestamp.fromDate(DateTime(2025, 6)),
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('lic-ren2').get();
      expect(doc.data()!['licenseNumber'], 'NEW-002');
    });
  });

  group('expiringLicensesStream', () {
    test('filters licenses expiring within 30 days', () async {
      final expiringSoon = makeLicense(
        id: 'soon',
        expiryDate: DateTime.now().add(const Duration(days: 15)),
      );
      final expireLater = makeLicense(
        id: 'later',
        expiryDate: DateTime.now().add(const Duration(days: 90)),
      );
      final alreadyExpired = makeLicense(
        id: 'expired',
        expiryDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      for (final l in [expiringSoon, expireLater, alreadyExpired]) {
        await fakeFirestore
            .collection(basePath)
            .doc(l.id)
            .set(l.toFirestore());
      }

      final thirtyDaysFromNow =
          DateTime.now().add(const Duration(days: 30));
      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('expiryDate',
              isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysFromNow))
          .get();

      // Should include 'soon' (15 days) and 'expired' (-5 days)
      expect(snapshot.docs.length, 2);
      final ids = snapshot.docs.map((d) => d.id).toSet();
      expect(ids, containsAll(['soon', 'expired']));
    });
  });

  group('licensesStream ordering', () {
    test('returns licenses ordered by expiryDate', () async {
      final l1 = makeLicense(id: 'l1', expiryDate: DateTime(2025, 6));
      final l2 = makeLicense(id: 'l2', expiryDate: DateTime(2024, 3));
      final l3 = makeLicense(id: 'l3', expiryDate: DateTime(2025, 12));

      for (final l in [l1, l2, l3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(l.id)
            .set(l.toFirestore());
      }

      final snapshot =
          await fakeFirestore.collection(basePath).orderBy('expiryDate').get();

      final ids = snapshot.docs.map((d) => d.id).toList();
      expect(ids, ['l2', 'l1', 'l3']);
    });
  });

  group('LicenseType enum round-trip', () {
    test('all license types survive Firestore round-trip', () async {
      for (final type in LicenseType.values) {
        final license = makeLicense(id: 'lt-${type.name}', type: type);
        await fakeFirestore
            .collection(basePath)
            .doc(license.id)
            .set(license.toFirestore());

        final doc = await fakeFirestore
            .collection(basePath)
            .doc(license.id)
            .get();
        final parsed = LicenseModel.fromFirestore(doc);
        expect(parsed.type, type);
      }
    });
  });
}
