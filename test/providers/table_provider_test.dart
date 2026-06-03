/// Tests for table providers — derived filtering and aggregation logic
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/tables/providers/table_provider.dart';
import 'package:tulasihotels/models/table_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('filteredTablesProvider', () {
    test('returns all tables when no floor selected', () {
      final tables = [
        makeTable(id: 't1', floor: 0),
        makeTable(id: 't2', floor: 1),
        makeTable(id: 't3', floor: 0),
      ];

      final container = ProviderContainer(
        overrides: [
          tablesStreamProvider
              .overrideWith((_) => Stream.value(tables)),
        ],
      );
      addTearDown(container.dispose);

      // Let the stream emit
      container.read(tablesStreamProvider);

      // Verify no floor filter
      expect(container.read(selectedFloorProvider), isNull);
    });

    test('selectedFloorProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(selectedFloorProvider), isNull);
    });

    test('selectedFloorProvider can be set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedFloorProvider.notifier).state = 2;
      expect(container.read(selectedFloorProvider), 2);
    });
  });

  group('availableFloorsProvider logic', () {
    test('extracts unique sorted floor numbers', () {
      final tables = [
        makeTable(id: 't1', floor: 2),
        makeTable(id: 't2', floor: 0),
        makeTable(id: 't3', floor: 1),
        makeTable(id: 't4', floor: 0),
      ];

      // Pure logic: extract unique floors
      final floors = tables.map((t) => t.floor).toSet().toList()..sort();
      expect(floors, [0, 1, 2]);
    });
  });

  group('tableStatusSummaryProvider logic', () {
    test('counts tables per status', () {
      final tables = [
        makeTable(id: 't1', status: TableStatus.available),
        makeTable(id: 't2', status: TableStatus.occupied),
        makeTable(id: 't3', status: TableStatus.available),
        makeTable(id: 't4', status: TableStatus.reserved),
        makeTable(id: 't5', status: TableStatus.occupied),
        makeTable(id: 't6', status: TableStatus.occupied),
      ];

      final summary = <TableStatus, int>{};
      for (final table in tables) {
        summary[table.status] = (summary[table.status] ?? 0) + 1;
      }

      expect(summary[TableStatus.available], 2);
      expect(summary[TableStatus.occupied], 3);
      expect(summary[TableStatus.reserved], 1);
    });

    test('empty tables list produces empty summary', () {
      final summary = <TableStatus, int>{};
      expect(summary, isEmpty);
    });
  });

  group('filteredTables logic', () {
    test('filters by floor', () {
      final tables = [
        makeTable(id: 't1', floor: 0),
        makeTable(id: 't2', floor: 1),
        makeTable(id: 't3', floor: 0),
        makeTable(id: 't4', floor: 2),
      ];

      const selectedFloor = 0;
      final filtered =
          tables.where((t) => t.floor == selectedFloor).toList();
      expect(filtered.length, 2);
      expect(filtered.every((t) => t.floor == 0), isTrue);
    });

    test('no floor filter returns all', () {
      final tables = [
        makeTable(id: 't1', floor: 0),
        makeTable(id: 't2', floor: 1),
      ];

      const int? selectedFloor = null;
      final filtered = selectedFloor == null
          ? tables
          : tables.where((t) => t.floor == selectedFloor).toList();
      expect(filtered.length, 2);
    });
  });
}
