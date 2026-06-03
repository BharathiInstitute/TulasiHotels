/// Integration test: License lifecycle — create, approach expiry, renew
///
/// Tests the compliance flow: create license, watch urgency change
/// as expiry approaches, renew to reset.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/license_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('Integration: License Lifecycle', () {
    test('Step 1: New license with distant expiry is OK', () {
      final license = makeLicense(
        id: 'lic-1',
        type: LicenseType.fssai,
        licenseNumber: 'FSSAI-2026-12345',
        issueDate: DateTime(2026, 1, 1),
        expiryDate: DateTime.now().add(const Duration(days: 180)),
        issuingAuthority: 'FSSAI India',
      );

      expect(license.isExpired, isFalse);
      expect(license.urgency, 'ok');
      expect(license.daysUntilExpiry, greaterThanOrEqualTo(90));
      expect(license.isActive, isTrue);
    });

    test('Step 2: License enters warning zone (< 90 days)', () {
      final warning = makeLicense(
        id: 'lic-1',
        type: LicenseType.fssai,
        expiryDate: DateTime.now().add(const Duration(days: 60)),
      );

      expect(warning.isExpired, isFalse);
      expect(warning.urgency, 'warning');
      expect(warning.daysUntilExpiry, lessThan(90));
      expect(warning.daysUntilExpiry, greaterThanOrEqualTo(30));
    });

    test('Step 3: License enters critical zone (< 30 days)', () {
      final critical = makeLicense(
        id: 'lic-1',
        type: LicenseType.fssai,
        expiryDate: DateTime.now().add(const Duration(days: 15)),
      );

      expect(critical.isExpired, isFalse);
      expect(critical.urgency, 'critical');
      expect(critical.daysUntilExpiry, lessThan(30));
    });

    test('Step 4: License expires', () {
      final expired = makeLicense(
        id: 'lic-1',
        type: LicenseType.fssai,
        expiryDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      expect(expired.isExpired, isTrue);
      expect(expired.urgency, 'expired');
      expect(expired.daysUntilExpiry, isNegative);
    });

    test('Step 5: Renew license — new dates reset urgency', () {
      final renewed = makeLicense(
        id: 'lic-1',
        type: LicenseType.fssai,
        licenseNumber: 'FSSAI-2027-67890',
        issueDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        isActive: true,
      );

      expect(renewed.isExpired, isFalse);
      expect(renewed.urgency, 'ok');
      expect(renewed.daysUntilExpiry, greaterThan(90));
    });

    test('Step 6: Deactivated license', () {
      final deactivated = makeLicense(
        id: 'lic-1',
        type: LicenseType.fssai,
        isActive: false,
        expiryDate: DateTime.now().add(const Duration(days: 200)),
      );

      expect(deactivated.isActive, isFalse);
      // Still technically not expired by date
      expect(deactivated.isExpired, isFalse);
    });
  });

  group('Integration: Multiple license types', () {
    test('hotel tracks multiple license types simultaneously', () {
      final licenses = [
        makeLicense(
          id: 'lic-1',
          type: LicenseType.fssai,
          licenseNumber: 'FSSAI-001',
          expiryDate: DateTime.now().add(const Duration(days: 200)),
        ),
        makeLicense(
          id: 'lic-2',
          type: LicenseType.liquor,
          licenseNumber: 'LIQ-002',
          expiryDate: DateTime.now().add(const Duration(days: 45)),
        ),
        makeLicense(
          id: 'lic-3',
          type: LicenseType.fireNoc,
          licenseNumber: 'FIRE-003',
          expiryDate: DateTime.now().subtract(const Duration(days: 10)),
        ),
        makeLicense(
          id: 'lic-4',
          type: LicenseType.healthCert,
          licenseNumber: 'HEALTH-004',
          expiryDate: DateTime.now().add(const Duration(days: 20)),
        ),
      ];

      final expired = licenses.where((l) => l.isExpired).toList();
      final critical = licenses.where((l) => l.urgency == 'critical').toList();
      final warning = licenses.where((l) => l.urgency == 'warning').toList();
      final ok = licenses.where((l) => l.urgency == 'ok').toList();

      expect(expired, hasLength(1)); // fireNoc
      expect(expired.first.type, LicenseType.fireNoc);
      expect(critical, hasLength(1)); // healthCert (< 30 days)
      expect(warning, hasLength(1)); // liquor (< 90 days)
      expect(ok, hasLength(1)); // fssai
    });

    test('license type display names', () {
      expect(LicenseType.fssai.displayName, 'FSSAI');
      expect(LicenseType.liquor.displayName, 'Liquor License');
      expect(LicenseType.fireNoc.displayName, 'Fire NOC');
      expect(LicenseType.shopAct.displayName, 'Shop & Establishment');
    });

    test('copyWith preserves ID while updating dates', () {
      final original = makeLicense(
        id: 'lic-1',
        type: LicenseType.fssai,
        licenseNumber: 'OLD-123',
        expiryDate: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(original.isExpired, isTrue);

      final renewed = original.copyWith(
        licenseNumber: 'NEW-456',
        issueDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 365)),
      );

      expect(renewed.id, 'lic-1'); // same ID
      expect(renewed.type, LicenseType.fssai); // same type
      expect(renewed.licenseNumber, 'NEW-456');
      expect(renewed.isExpired, isFalse);
      expect(renewed.urgency, 'ok');
    });
  });
}
