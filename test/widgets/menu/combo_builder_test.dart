import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/menu/providers/combo_provider.dart';
import 'package:tulasihotels/features/menu/screens/combo_builder_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('ComboBuilderScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(
        tester,
        const ComboBuilderScreen(),
        overrides: [combosStreamProvider.overrideWith((_) => Stream.value([]))],
      );
      expect(find.text('Combo Meals'), findsOneWidget);
    });

    testWidgets('shows combo name in list', (tester) async {
      final combos = [
        makeCombo(name: 'Family Thali'),
        makeCombo(id: 'c2', name: 'Lunch Special'),
      ];
      await pumpWidget(
        tester,
        const ComboBuilderScreen(),
        overrides: [
          combosStreamProvider.overrideWith((_) => Stream.value(combos)),
        ],
      );
      expect(find.text('Family Thali'), findsOneWidget);
      expect(find.text('Lunch Special'), findsOneWidget);
    });

    testWidgets('shows FAB for creating combo', (tester) async {
      await pumpWidget(
        tester,
        const ComboBuilderScreen(),
        overrides: [combosStreamProvider.overrideWith((_) => Stream.value([]))],
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows combo price', (tester) async {
      final combos = [makeCombo(name: 'Deluxe', price: 499)];
      await pumpWidget(
        tester,
        const ComboBuilderScreen(),
        overrides: [
          combosStreamProvider.overrideWith((_) => Stream.value(combos)),
        ],
      );
      expect(find.textContaining('499'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            combosStreamProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: ComboBuilderScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
