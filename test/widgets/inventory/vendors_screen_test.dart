import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/inventory/providers/inventory_provider.dart';
import 'package:tulasihotels/features/inventory/screens/vendors_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('VendorsScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const VendorsScreen(), overrides: [
        vendorsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.text('Vendors'), findsOneWidget);
    });

    testWidgets('shows FAB for adding vendor', (tester) async {
      await pumpWidget(tester, const VendorsScreen(), overrides: [
        vendorsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Vendor'), findsOneWidget);
    });

    testWidgets('shows vendor name in list', (tester) async {
      final items = [
        makeVendor(name: 'Fresh Farms'),
        makeVendor(id: 'v2', name: 'Spice World'),
      ];
      await pumpWidget(tester, const VendorsScreen(), overrides: [
        vendorsProvider.overrideWith((_) => Stream.value(items)),
      ]);
      expect(find.text('Fresh Farms'), findsOneWidget);
      expect(find.text('Spice World'), findsOneWidget);
    });

    testWidgets('shows vendor phone number', (tester) async {
      final items = [
        makeVendor(name: 'Fresh Farms', phone: '9876543210'),
      ];
      await pumpWidget(tester, const VendorsScreen(), overrides: [
        vendorsProvider.overrideWith((_) => Stream.value(items)),
      ]);
      expect(find.textContaining('9876543210'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vendorsProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: VendorsScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
