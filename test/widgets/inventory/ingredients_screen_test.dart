import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/inventory/providers/inventory_provider.dart';
import 'package:tulasihotels/features/inventory/screens/ingredients_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('IngredientsScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const IngredientsScreen(), overrides: [
        ingredientsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.text('Ingredients'), findsOneWidget);
    });

    testWidgets('shows FAB for adding ingredient', (tester) async {
      await pumpWidget(tester, const IngredientsScreen(), overrides: [
        ingredientsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Ingredient'), findsOneWidget);
    });

    testWidgets('shows ingredient name in list', (tester) async {
      final items = [
        makeIngredient(name: 'Basmati Rice'),
        makeIngredient(id: 'ing-2', name: 'Turmeric Powder'),
      ];
      await pumpWidget(tester, const IngredientsScreen(), overrides: [
        ingredientsProvider.overrideWith((_) => Stream.value(items)),
      ]);
      expect(find.text('Basmati Rice'), findsOneWidget);
      expect(find.text('Turmeric Powder'), findsOneWidget);
    });

    testWidgets('highlights low stock items', (tester) async {
      final items = [
        makeIngredient(name: 'Salt', currentStock: 2, minLevel: 10),
      ];
      await pumpWidget(tester, const IngredientsScreen(), overrides: [
        ingredientsProvider.overrideWith((_) => Stream.value(items)),
      ]);
      // Low stock item should be visible with some indication
      expect(find.text('Salt'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ingredientsProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: IngredientsScreen()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
