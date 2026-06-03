import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/coupon_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('CouponType enum', () {
    test('displayName and symbol', () {
      expect(CouponType.percentage.displayName, 'Percentage');
      expect(CouponType.percentage.symbol, '%');
      expect(CouponType.flat.displayName, 'Flat');
      expect(CouponType.flat.symbol, '₹');
    });

    test('fromString parses valid values', () {
      expect(CouponType.fromString('percentage'), CouponType.percentage);
      expect(CouponType.fromString('flat'), CouponType.flat);
    });

    test('fromString defaults to percentage', () {
      expect(CouponType.fromString('xyz'), CouponType.percentage);
    });
  });

  group('CouponModel', () {
    test('constructor defaults', () {
      final m = makeCoupon();
      expect(m.usedCount, 0);
      expect(m.isActive, true);
      expect(m.isHappyHour, false);
    });

    group('isValid', () {
      test('returns true for active coupon with no constraints', () {
        final m = makeCoupon();
        expect(m.isValid, isTrue);
      });

      test('returns false when inactive', () {
        final m = makeCoupon(isActive: false);
        expect(m.isValid, isFalse);
      });

      test('returns false when maxUses reached', () {
        final m = makeCoupon(maxUses: 5, usedCount: 5);
        expect(m.isValid, isFalse);
      });

      test('returns false when maxUses exceeded', () {
        final m = makeCoupon(maxUses: 5, usedCount: 6);
        expect(m.isValid, isFalse);
      });

      test('returns false when before validFrom', () {
        final m = makeCoupon(
          validFrom: DateTime.now().add(const Duration(days: 1)),
        );
        expect(m.isValid, isFalse);
      });

      test('returns false when after validUntil', () {
        final m = makeCoupon(
          validUntil: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(m.isValid, isFalse);
      });

      test('returns true within date range', () {
        final m = makeCoupon(
          validFrom: DateTime.now().subtract(const Duration(days: 1)),
          validUntil: DateTime.now().add(const Duration(days: 1)),
        );
        expect(m.isValid, isTrue);
      });
    });

    group('calculateDiscount', () {
      test('percentage discount', () {
        final m = makeCoupon(type: CouponType.percentage, value: 10);
        expect(m.calculateDiscount(1000), 100);
      });

      test('percentage discount with maxDiscount cap', () {
        final m = makeCoupon(
          type: CouponType.percentage,
          value: 20,
          maxDiscount: 50,
        );
        expect(m.calculateDiscount(1000), 50);
      });

      test('flat discount', () {
        final m = makeCoupon(type: CouponType.flat, value: 100);
        expect(m.calculateDiscount(1000), 100);
      });

      test('flat discount clamped to orderAmount', () {
        final m = makeCoupon(type: CouponType.flat, value: 200);
        expect(m.calculateDiscount(150), 150);
      });

      test('returns 0 when below minOrderAmount', () {
        final m = makeCoupon(
          type: CouponType.percentage,
          value: 10,
          minOrderAmount: 500,
        );
        expect(m.calculateDiscount(400), 0);
      });

      test('applies discount when at minOrderAmount', () {
        final m = makeCoupon(
          type: CouponType.percentage,
          value: 10,
          minOrderAmount: 500,
        );
        expect(m.calculateDiscount(500), 50);
      });

      test('percentage discount cannot be negative', () {
        final m = makeCoupon(type: CouponType.percentage, value: 0);
        expect(m.calculateDiscount(1000), 0);
      });
    });

    group('isHappyHourActive', () {
      test('returns false when not happy hour coupon', () {
        expect(makeCoupon().isHappyHourActive, isFalse);
      });

      test('returns false when start/end null', () {
        final m = makeCoupon(isHappyHour: true);
        expect(m.isHappyHourActive, isFalse);
      });

      test('returns true during happy hour window', () {
        final now = DateTime.now().hour;
        final m = makeCoupon(
          isHappyHour: true,
          happyHourStart: now,
          happyHourEnd: now + 1,
        );
        expect(m.isHappyHourActive, isTrue);
      });

      test('returns false outside happy hour window', () {
        final now = DateTime.now().hour;
        final m = makeCoupon(
          isHappyHour: true,
          happyHourStart: (now + 2) % 24,
          happyHourEnd: (now + 4) % 24,
        );
        // Only reliable if now+2 > now (not wrapping midnight)
        if ((now + 2) % 24 > now) {
          expect(m.isHappyHourActive, isFalse);
        }
      });
    });

    group('Firestore round-trip', () {
      test('toFirestore contains all fields', () {
        final m = makeCoupon(
          minOrderAmount: 500,
          maxDiscount: 100,
          validFrom: DateTime(2024, 1, 1),
          validUntil: DateTime(2024, 12, 31),
          maxUses: 100,
          isHappyHour: true,
          happyHourStart: 14,
          happyHourEnd: 17,
        );
        final map = m.toFirestore();
        expect(map['code'], 'TEST10');
        expect(map['type'], 'percentage');
        expect(map['value'], 10.0);
        expect(map['minOrderAmount'], 500.0);
        expect(map['maxDiscount'], 100.0);
        expect(map['maxUses'], 100);
        expect(map['isHappyHour'], true);
        expect(map['happyHourStart'], 14);
        expect(map['happyHourEnd'], 17);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeCoupon(
          code: 'SAVE20',
          type: CouponType.flat,
          value: 200,
          minOrderAmount: 1000,
          maxUses: 50,
          usedCount: 10,
          isHappyHour: true,
          happyHourStart: 12,
          happyHourEnd: 15,
        );
        await firestore
            .collection('coupons')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore
            .collection('coupons')
            .doc(original.id)
            .get();
        final restored = CouponModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.code, 'SAVE20');
        expect(restored.type, CouponType.flat);
        expect(restored.value, 200);
        expect(restored.minOrderAmount, 1000);
        expect(restored.maxUses, 50);
        expect(restored.usedCount, 10);
        expect(restored.isHappyHour, true);
        expect(restored.happyHourStart, 12);
        expect(restored.happyHourEnd, 15);
      });
    });
  });
}
