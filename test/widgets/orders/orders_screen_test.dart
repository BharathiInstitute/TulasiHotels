import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/orders/providers/order_provider.dart';
import 'package:tulasihotels/features/orders/screens/orders_screen.dart';
import 'package:tulasihotels/models/order_model.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('OrdersScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const OrdersScreen(), overrides: [
        filteredActiveOrdersProvider
            .overrideWithValue(const AsyncValue.data(<OrderModel>[])),
      ]);
      expect(find.text('Active Orders'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredActiveOrdersProvider
                .overrideWithValue(const AsyncValue<List<OrderModel>>.loading()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: OrdersScreen()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders when data loaded', (tester) async {
      await pumpWidget(tester, const OrdersScreen(), overrides: [
        filteredActiveOrdersProvider
            .overrideWithValue(const AsyncValue.data(<OrderModel>[])),
      ]);
      expect(find.byType(OrdersScreen), findsOneWidget);
    });
  });
}
