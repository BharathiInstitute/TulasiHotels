import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/license_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('LicenseType enum', () {
    test('displayName and emoji for all values', () {
      expect(LicenseType.fssai.displayName, 'FSSAI');
      expect(LicenseType.liquor.displayName, 'Liquor License');
      expect(LicenseType.fireNoc.displayName, 'Fire NOC');
      expect(LicenseType.healthCert.displayName, 'Health Certificate');
      expect(LicenseType.shopAct.displayName, 'Shop & Establishment');
      expect(LicenseType.gst.displayName, 'GST Registration');
      expect(LicenseType.other.displayName, 'Other');
    });

    test('fromString parses all values', () {
      for (final t in LicenseType.values) {
        expect(LicenseType.fromString(t.name), t);
      }
    });

    test('fromString defaults to other for unknown', () {
      expect(LicenseType.fromString('xyz'), LicenseType.other);
    });
  });

  group('LicenseModel', () {
    test('constructor defaults', () {
      final m = makeLicense();
      expect(m.type, LicenseType.fssai);
      expect(m.isActive, true);
    });

    test('isExpired true when past expiryDate', () {
      final m = makeLicense(expiryDate: DateTime(2020, 1, 1));
      expect(m.isExpired, isTrue);
    });

    test('isExpired false when future expiryDate', () {
      final m = makeLicense(expiryDate: DateTime(2099, 1, 1));
      expect(m.isExpired, isFalse);
    });

    test('daysUntilExpiry is positive for future date', () {
      final m = makeLicense(
        expiryDate: DateTime.now().add(const Duration(days: 100)),
      );
      expect(m.daysUntilExpiry, greaterThanOrEqualTo(99));
    });

    test('daysUntilExpiry is negative for past date', () {
      final m = makeLicense(
        expiryDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(m.daysUntilExpiry, lessThan(0));
    });

    group('urgency', () {
      test('returns expired when past', () {
        final m = makeLicense(expiryDate: DateTime(2020, 1, 1));
        expect(m.urgency, 'expired');
      });

      test('returns critical when < 30 days', () {
        final m = makeLicense(
          expiryDate: DateTime.now().add(const Duration(days: 15)),
        );
        expect(m.urgency, 'critical');
      });

      test('returns warning when < 90 days', () {
        final m = makeLicense(
          expiryDate: DateTime.now().add(const Duration(days: 60)),
        );
        expect(m.urgency, 'warning');
      });

      test('returns ok when >= 90 days', () {
        final m = makeLicense(
          expiryDate: DateTime.now().add(const Duration(days: 100)),
        );
        expect(m.urgency, 'ok');
      });
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeLicense(
          licenseNumber: 'FSSAI-12345',
          issuingAuthority: 'FDA',
          documentUrl: 'https://example.com/doc.pdf',
        );
        final map = m.toFirestore();
        expect(map['type'], 'fssai');
        expect(map['licenseNumber'], 'FSSAI-12345');
        expect(map['issuingAuthority'], 'FDA');
        expect(map['documentUrl'], 'https://example.com/doc.pdf');
        expect(map['isActive'], true);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeLicense(
          type: LicenseType.liquor,
          licenseNumber: 'LQ-999',
          issueDate: DateTime(2023, 1, 1),
          expiryDate: DateTime(2025, 1, 1),
          issuingAuthority: 'Excise Dept',
          isActive: true,
        );
        await firestore
            .collection('licenses')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('licenses')
            .doc(original.id)
            .get();
        final restored = LicenseModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.type, LicenseType.liquor);
        expect(restored.licenseNumber, 'LQ-999');
        expect(restored.issuingAuthority, 'Excise Dept');
        expect(restored.isActive, true);
      });
    });
  });
}
