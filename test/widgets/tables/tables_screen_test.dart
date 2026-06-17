import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/tables/providers/table_provider.dart';
import 'package:tulasihotels/features/tables/screens/tables_screen.dart';
import 'package:tulasihotels/models/table_model.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('TablesScreen', () {
    List<Override> overrides({List<TableModel> tables = const []}) => [
      tablesStreamProvider.overrideWith((_) => Stream.value(tables)),
      selectedFloorProvider.overrideWith((ref) => null),
    ];

    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const TablesScreen(), overrides: overrides());
      expect(find.text('Tables'), findsOneWidget);
    });

    testWidgets('shows table names in grid', (tester) async {
      final tables = [
        makeTable(label: 'Table 1', floor: 1),
        makeTable(id: 't2', label: 'Table 2', floor: 1),
      ];
      await pumpWidget(
        tester,
        const TablesScreen(),
        overrides: overrides(tables: tables),
      );
      expect(find.text('Table 1'), findsOneWidget);
      expect(find.text('Table 2'), findsOneWidget);
    });

    testWidgets('shows add table button in AppBar', (tester) async {
      await pumpWidget(tester, const TablesScreen(), overrides: overrides());
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('shows status summary bar', (tester) async {
      final tables = [
        makeTable(label: 'T1', floor: 1),
        makeTable(
          id: 't2',
          label: 'T2',
          floor: 1,
          status: TableStatus.occupied,
        ),
      ];
      await pumpWidget(
        tester,
        const TablesScreen(),
        overrides: overrides(tables: tables),
      );
      // Status chips should be visible
      expect(find.textContaining('Available'), findsWidgets);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tablesStreamProvider.overrideWith((_) => const Stream.empty()),
            selectedFloorProvider.overrideWith((ref) => null),
          ],
          child: const MaterialApp(home: Scaffold(body: TablesScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no tables', (tester) async {
      await pumpWidget(tester, const TablesScreen(), overrides: overrides());
      expect(find.textContaining('Add Tables'), findsOneWidget);
    });
  });
}
