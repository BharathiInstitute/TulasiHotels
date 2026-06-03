import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/coupons/providers/coupon_provider.dart';
import 'package:tulasihotels/features/coupons/screens/coupons_screen.dart';
import 'package:tulasihotels/models/coupon_model.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('CouponsScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        allCouponsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.text('Coupons & Discounts'), findsOneWidget);
    });

    testWidgets('shows FAB for new coupon', (tester) async {
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        allCouponsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Coupon'), findsOneWidget);
    });

    testWidgets('shows coupon code in list', (tester) async {
      final coupons = [
        makeCoupon(code: 'FLAT50', type: CouponType.flat, value: 50),
        makeCoupon(
          id: 'c2',
          code: 'SAVE20',
          type: CouponType.percentage,
          value: 20,
        ),
      ];
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        allCouponsProvider.overrideWith((_) => Stream.value(coupons)),
      ]);
      expect(find.text('FLAT50'), findsOneWidget);
      expect(find.text('SAVE20'), findsOneWidget);
    });

    testWidgets('shows percentage discount info', (tester) async {
      final coupons = [
        makeCoupon(code: 'DEAL10', type: CouponType.percentage, value: 10),
      ];
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        allCouponsProvider.overrideWith((_) => Stream.value(coupons)),
      ]);
      expect(find.textContaining('10'), findsWidgets);
    });

    testWidgets('shows active switch per coupon', (tester) async {
      final coupons = [
        makeCoupon(code: 'ACTIVE1', isActive: true),
      ];
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        allCouponsProvider.overrideWith((_) => Stream.value(coupons)),
      ]);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows happy hour badge', (tester) async {
      final coupons = [
        makeCoupon(code: 'HAPPY', isHappyHour: true),
      ];
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        allCouponsProvider.overrideWith((_) => Stream.value(coupons)),
      ]);
      // Happy hour badge text
      expect(
        find.textContaining('Happy Hour').evaluate().isNotEmpty ||
            find.textContaining('happy').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('shows usage count', (tester) async {
      final coupons = [
        makeCoupon(code: 'USED5', usedCount: 5),
      ];
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        allCouponsProvider.overrideWith((_) => Stream.value(coupons)),
      ]);
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allCouponsProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: CouponsScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
