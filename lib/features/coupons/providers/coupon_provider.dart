/// Coupon and discount providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/coupons/services/coupon_service.dart';
import 'package:tulasihotels/models/coupon_model.dart';

/// Stream active coupons
final activeCouponsProvider =
    StreamProvider.autoDispose<List<CouponModel>>((ref) {
  return CouponService.activeCouponsStream();
});

/// Stream all coupons
final allCouponsProvider = StreamProvider.autoDispose<List<CouponModel>>((ref) {
  return CouponService.allCouponsStream();
});

/// Currently active happy hour coupon
final happyHourCouponProvider =
    FutureProvider.autoDispose<CouponModel?>((ref) {
  return CouponService.getActiveHappyHourCoupon();
});
