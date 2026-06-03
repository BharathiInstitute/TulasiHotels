import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/billing/widgets/reorder_button.dart';

import '../../helpers/test_factories_extended.dart';

void main() {
  group('ReorderButton', () {
    testWidgets('shows Reorder text', (tester) async {
      final order = makeOrder();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderButton(previousOrder: order, onReorder: (_) {}),
          ),
        ),
      );
      expect(find.textContaining('Reorder'), findsOneWidget);
    });

    testWidgets('shows replay icon', (tester) async {
      final order = makeOrder();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderButton(previousOrder: order, onReorder: (_) {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.replay), findsOneWidget);
    });

    testWidgets('tap triggers confirmation dialog', (tester) async {
      final order = makeOrder(
        items: [makeOrderItem(name: 'Paneer Tikka', quantity: 2)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderButton(previousOrder: order, onReorder: (_) {}),
          ),
        ),
      );
      await tester.tap(find.textContaining('Reorder'));
      await tester.pumpAndSettle();
      // Confirmation dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
