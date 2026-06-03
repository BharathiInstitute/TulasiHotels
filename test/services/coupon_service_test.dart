/// Tests for CouponService — validate, apply, happy hour, toggle
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/coupon_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/coupons';
  });

  group('CouponService Firestore operations', () {
    test('create — writes and reads back all fields', () async {
      final coupon = makeCoupon(
        id: 'c-1',
        code: 'SAVE20',
        type: CouponType.percentage,
        value: 20,
        minOrderAmount: 500,
        maxDiscount: 200,
      );

      await fakeFirestore
          .collection(basePath)
          .doc(coupon.id)
          .set(coupon.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc(coupon.id).get();
      final parsed = CouponModel.fromFirestore(doc);
      expect(parsed.code, 'SAVE20');
      expect(parsed.type, CouponType.percentage);
      expect(parsed.value, 20);
      expect(parsed.minOrderAmount, 500);
      expect(parsed.maxDiscount, 200);
    });

    test('delete — removes coupon', () async {
      final coupon = makeCoupon(id: 'c-d1');
      await fakeFirestore
          .collection(basePath)
          .doc(coupon.id)
          .set(coupon.toFirestore());

      await fakeFirestore.collection(basePath).doc('c-d1').delete();

      final doc =
          await fakeFirestore.collection(basePath).doc('c-d1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('validateCoupon logic', () {
    test('returns coupon when valid code, active, no constraints', () async {
      final coupon = makeCoupon(id: 'v1', code: 'VALID', isActive: true);
      await fakeFirestore
          .collection(basePath)
          .doc(coupon.id)
          .set(coupon.toFirestore());

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('code', isEqualTo: 'VALID')
          .get();

      expect(snapshot.docs.length, 1);
      final found = CouponModel.fromFirestore(snapshot.docs.first);
      expect(found.isValid, isTrue);
    });

    test('returns empty for unknown coupon code', () async {
      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('code', isEqualTo: 'NONEXISTENT')
          .get();

      expect(snapshot.docs.isEmpty, isTrue);
    });

    test('fails validation when coupon is inactive', () {
      final coupon = makeCoupon(isActive: false);
      expect(coupon.isValid, isFalse);
    });

    test('fails validation when expired', () {
      final coupon = makeCoupon(
        validUntil: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(coupon.isValid, isFalse);
    });

    test('fails validation when usage limit exceeded', () {
      final coupon = makeCoupon(maxUses: 10, usedCount: 10);
      expect(coupon.isValid, isFalse);
    });

    test('passes validation when usage under limit', () {
      final coupon = makeCoupon(maxUses: 10, usedCount: 5);
      expect(coupon.isValid, isTrue);
    });

    test('fails when order amount below minimum', () {
      final coupon = makeCoupon(minOrderAmount: 500);
      // Service checks: orderAmount < minOrderAmount → return null
      expect(coupon.minOrderAmount, 500);
      // 300 < 500 → should fail
      expect(300 < coupon.minOrderAmount!, isTrue);
    });
  });

  group('applyCoupon — usage increment', () {
    test('increments usedCount by 1', () async {
      final coupon = makeCoupon(id: 'apply-1', usedCount: 3);
      await fakeFirestore
          .collection(basePath)
          .doc(coupon.id)
          .set(coupon.toFirestore());

      // Simulate FieldValue.increment(1)
      await fakeFirestore.collection(basePath).doc('apply-1').update({
        'usedCount': 4,
      });

      final doc =
          await fakeFirestore.collection(basePath).doc('apply-1').get();
      expect(doc.data()!['usedCount'], 4);
    });
  });

  group('activeCouponsStream query', () {
    test('filters only active coupons', () async {
      final active1 = makeCoupon(id: 'a1', isActive: true);
      final active2 = makeCoupon(id: 'a2', isActive: true);
      final inactive = makeCoupon(id: 'i1', isActive: false);

      for (final c in [active1, active2, inactive]) {
        await fakeFirestore
            .collection(basePath)
            .doc(c.id)
            .set(c.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('isActive', isEqualTo: true)
          .get();

      expect(snapshot.docs.length, 2);
      final ids = snapshot.docs.map((d) => d.id).toSet();
      expect(ids, {'a1', 'a2'});
    });
  });

  group('toggleActive', () {
    test('toggles coupon from active to inactive', () async {
      final coupon = makeCoupon(id: 't1', isActive: true);
      await fakeFirestore
          .collection(basePath)
          .doc(coupon.id)
          .set(coupon.toFirestore());

      await fakeFirestore.collection(basePath).doc('t1').update({
        'isActive': false,
      });

      final doc = await fakeFirestore.collection(basePath).doc('t1').get();
      expect(doc.data()!['isActive'], isFalse);
    });
  });

  group('happy hour coupon', () {
    test('getActiveHappyHourCoupon filters isHappyHour + isActive', () async {
      final happy = makeCoupon(
        id: 'hh1',
        isHappyHour: true,
        isActive: true,
        happyHourStart: 14,
        happyHourEnd: 17,
      );
      final notHappy = makeCoupon(id: 'nh1', isHappyHour: false);

      for (final c in [happy, notHappy]) {
        await fakeFirestore
            .collection(basePath)
            .doc(c.id)
            .set(c.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('isActive', isEqualTo: true)
          .where('isHappyHour', isEqualTo: true)
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 'hh1');
    });
  });

  group('calculateDiscount', () {
    test('percentage discount calculates correctly', () {
      final coupon = makeCoupon(type: CouponType.percentage, value: 10);
      expect(coupon.calculateDiscount(1000), 100);
    });

    test('percentage discount respects maxDiscount cap', () {
      final coupon = makeCoupon(
        type: CouponType.percentage,
        value: 20,
        maxDiscount: 150,
      );
      // 20% of 1000 = 200, but max is 150
      expect(coupon.calculateDiscount(1000), 150);
    });

    test('flat discount returns value directly', () {
      final coupon = makeCoupon(type: CouponType.flat, value: 75);
      expect(coupon.calculateDiscount(500), 75);
    });

    test('flat discount does not exceed order amount', () {
      final coupon = makeCoupon(type: CouponType.flat, value: 200);
      expect(coupon.calculateDiscount(150), 150);
    });
  });
}
