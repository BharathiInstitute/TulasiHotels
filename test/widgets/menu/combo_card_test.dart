import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/menu/widgets/combo_card.dart';

import '../../helpers/test_factories.dart';

void main() {
  group('ComboCard', () {
    testWidgets('renders combo name', (tester) async {
      final combo = makeProduct(name: 'Thali Combo');
      final items = [
        makeProduct(id: 'p2', name: 'Rice'),
        makeProduct(id: 'p3', name: 'Dal'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComboCard(combo: combo, comboItems: items),
          ),
        ),
      );
      expect(find.text('Thali Combo'), findsOneWidget);
    });

    testWidgets('shows combo item names', (tester) async {
      final combo = makeProduct(name: 'Lunch Special');
      final items = [
        makeProduct(id: 'p2', name: 'Roti'),
        makeProduct(id: 'p3', name: 'Paneer'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComboCard(combo: combo, comboItems: items),
          ),
        ),
      );
      expect(find.text('Roti'), findsOneWidget);
      expect(find.text('Paneer'), findsOneWidget);
    });

    testWidgets('shows add button when onAdd provided', (tester) async {
      final combo = makeProduct(name: 'Dinner Combo');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComboCard(combo: combo, comboItems: const [], onAdd: () {}),
          ),
        ),
      );
      expect(find.byType(ComboCard), findsOneWidget);
    });
  });
}
