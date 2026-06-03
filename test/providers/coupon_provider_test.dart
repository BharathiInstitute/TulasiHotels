/// Tests for coupon providers — provider types and data flow
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/coupons/providers/coupon_provider.dart';
import 'package:tulasihotels/models/coupon_model.dart';

void main() {
  group('activeCouponsProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          activeCouponsProvider.overrideWith(
            (_) => Stream.value(<CouponModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(activeCouponsProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          activeCouponsProvider.overrideWith(
            (_) => Stream.value(<CouponModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(activeCouponsProvider),
        isA<AsyncValue<List<CouponModel>>>(),
      );
    });
  });

  group('allCouponsProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          allCouponsProvider.overrideWith((_) => Stream.value(<CouponModel>[])),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(allCouponsProvider).isLoading, isTrue);
    });
  });

  group('happyHourCouponProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          happyHourCouponProvider.overrideWith((_) => Future.value(null)),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(happyHourCouponProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of nullable CouponModel', () {
      final container = ProviderContainer(
        overrides: [
          happyHourCouponProvider.overrideWith((_) => Future.value(null)),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(happyHourCouponProvider),
        isA<AsyncValue<CouponModel?>>(),
      );
    });
  });
}
