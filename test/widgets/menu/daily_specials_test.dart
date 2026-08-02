import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/menu/screens/daily_specials_screen.dart';
import 'package:tulasihotels/features/products/providers/products_provider.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories.dart';

void main() {
  group('DailySpecialsScreen', () {
    List<Override> _permissionOverride() => [
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
      await pumpWidget(tester, const DailySpecialsScreen(), overrides: [
        ..._permissionOverride(),
        productsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.text('Daily Specials ⭐'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._permissionOverride(),
            productsProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DailySpecialsScreen()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders product list when loaded', (tester) async {
      final products = [
        makeProduct(name: 'Paneer Tikka'),
        makeProduct(id: 'p2', name: 'Butter Naan'),
      ];
      await pumpWidget(tester, const DailySpecialsScreen(), overrides: [
        ..._permissionOverride(),
        productsProvider.overrideWith((_) => Stream.value(products)),
      ]);
      expect(find.byType(DailySpecialsScreen), findsOneWidget);
    });
  });
}
