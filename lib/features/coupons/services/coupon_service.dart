/// Coupon and discount management service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/coupon_model.dart';

class CouponService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _couponsRef =>
      _firestore.collection('$_basePath/coupons');

  /// Stream all active coupons
  static Stream<List<CouponModel>> activeCouponsStream() {
    return _couponsRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CouponModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream all coupons
  static Stream<List<CouponModel>> allCouponsStream() {
    return _couponsRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => CouponModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Validate a coupon code against an order amount
  static Future<CouponModel?> validateCoupon(
      String code, double orderAmount) async {
    final snapshot =
        await _couponsRef.where('code', isEqualTo: code.toUpperCase()).get();

    if (snapshot.docs.isEmpty) return null;

    final coupon = CouponModel.fromFirestore(snapshot.docs.first);
    if (!coupon.isValid) return null;
    if (coupon.minOrderAmount != null && orderAmount < coupon.minOrderAmount!) {
      return null;
    }

    return coupon;
  }

  /// Increment coupon usage count
  static Future<void> applyCoupon(String couponId) async {
    await _couponsRef.doc(couponId).update({
      'usedCount': FieldValue.increment(1),
    });
  }

  /// Get currently active happy hour coupon
  static Future<CouponModel?> getActiveHappyHourCoupon() async {
    final snapshot = await _couponsRef
        .where('isActive', isEqualTo: true)
        .where('isHappyHour', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) return null;

    for (final doc in snapshot.docs) {
      final coupon = CouponModel.fromFirestore(doc);
      if (coupon.isHappyHourActive) return coupon;
    }
    return null;
  }

  /// Create a coupon
  static Future<void> createCoupon(CouponModel coupon) async {
    await _couponsRef.doc(coupon.id).set(coupon.toFirestore());
  }

  /// Update a coupon
  static Future<void> updateCoupon(CouponModel coupon) async {
    await _couponsRef.doc(coupon.id).update(coupon.toFirestore());
  }

  /// Toggle coupon active state
  static Future<void> toggleActive(String couponId, bool isActive) async {
    await _couponsRef.doc(couponId).update({'isActive': isActive});
  }

  /// Delete a coupon
  static Future<void> deleteCoupon(String couponId) async {
    await _couponsRef.doc(couponId).delete();
  }
}
