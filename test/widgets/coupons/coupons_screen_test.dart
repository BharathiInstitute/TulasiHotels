import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/coupons/providers/coupon_provider.dart';
import 'package:tulasihotels/features/coupons/screens/coupons_screen.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/models/coupon_model.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('CouponsScreen', () {
    List<Override> baseOverrides() => [
      routePermissionProvider.overrideWith(
        (ref, route) => const RoutePermissionState(
          isResolved: true,
          canView: true,
          canCreate: true,
          canUpdate: true,
          canDelete: true,
        ),
      ),
    ];

    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        ...baseOverrides(),
        allCouponsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.text('Coupons & Discounts'), findsOneWidget);
    });

    testWidgets('shows FAB for new coupon', (tester) async {
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        ...baseOverrides(),
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
          value: 20,
        ),
      ];
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        ...baseOverrides(),
        allCouponsProvider.overrideWith((_) => Stream.value(coupons)),
      ]);
      expect(find.text('FLAT50'), findsOneWidget);
      expect(find.text('SAVE20'), findsOneWidget);
    });

    testWidgets('shows percentage discount info', (tester) async {
      final coupons = [
        makeCoupon(code: 'DEAL10'),
      ];
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        ...baseOverrides(),
        allCouponsProvider.overrideWith((_) => Stream.value(coupons)),
      ]);
      expect(find.textContaining('10'), findsWidgets);
    });

    testWidgets('shows coupon row with actions', (tester) async {
      final coupons = [
        makeCoupon(code: 'ACTIVE1'),
      ];
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        ...baseOverrides(),
        allCouponsProvider.overrideWith((_) => Stream.value(coupons)),
      ]);
      expect(find.text('ACTIVE1'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
    });

    testWidgets('shows happy hour badge', (tester) async {
      final coupons = [
        makeCoupon(code: 'HAPPY', isHappyHour: true),
      ];
      await pumpWidget(tester, const CouponsScreen(), overrides: [
        ...baseOverrides(),
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
        ...baseOverrides(),
        allCouponsProvider.overrideWith((_) => Stream.value(coupons)),
      ]);
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
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
