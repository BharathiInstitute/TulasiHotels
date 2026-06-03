import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/orders/providers/order_provider.dart';
import 'package:tulasihotels/features/kitchen/screens/kitchen_display_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('KitchenDisplayScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(
        tester,
        const KitchenDisplayScreen(),
        overrides: [
          kitchenOrdersProvider.overrideWith((_) => Stream.value([])),
        ],
      );
      expect(find.text('Kitchen Display'), findsOneWidget);
    });

    testWidgets('shows empty state when no orders', (tester) async {
      await pumpWidget(
        tester,
        const KitchenDisplayScreen(),
        overrides: [
          kitchenOrdersProvider.overrideWith((_) => Stream.value([])),
        ],
      );
      expect(find.textContaining('All caught up'), findsOneWidget);
    });

    testWidgets('shows table name on order card', (tester) async {
      final orders = [makeOrder(tableName: 'Table 5')];
      await pumpWidget(
        tester,
        const KitchenDisplayScreen(),
        overrides: [
          kitchenOrdersProvider.overrideWith((_) => Stream.value(orders)),
        ],
      );
      expect(find.textContaining('Table 5'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kitchenOrdersProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: KitchenDisplayScreen()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
