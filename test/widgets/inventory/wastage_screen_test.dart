import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/inventory/providers/inventory_provider.dart';
import 'package:tulasihotels/features/inventory/screens/wastage_screen.dart';
import 'package:tulasihotels/models/wastage_model.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('WastageScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const WastageScreen(), overrides: [
        wastageProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.text('Wastage Log'), findsOneWidget);
    });

    testWidgets('shows FAB for logging wastage', (tester) async {
      await pumpWidget(tester, const WastageScreen(), overrides: [
        wastageProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Log Wastage'), findsOneWidget);
    });

    testWidgets('shows wastage ingredient name in list', (tester) async {
      final items = [
        makeWastage(ingredientName: 'Chicken'),
        makeWastage(
          id: 'w2',
          ingredientName: 'Tomatoes',
          reason: WastageReason.expired,
        ),
      ];
      await pumpWidget(tester, const WastageScreen(), overrides: [
        wastageProvider.overrideWith((_) => Stream.value(items)),
      ]);
      expect(find.text('Chicken'), findsOneWidget);
      expect(find.text('Tomatoes'), findsOneWidget);
    });

    testWidgets('shows estimated cost', (tester) async {
      final items = [
        makeWastage(ingredientName: 'Paneer', estimatedCost: 350),
      ];
      await pumpWidget(tester, const WastageScreen(), overrides: [
        wastageProvider.overrideWith((_) => Stream.value(items)),
      ]);
      expect(find.textContaining('350'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wastageProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: WastageScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
