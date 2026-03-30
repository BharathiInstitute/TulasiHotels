/// Table management providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/tables/services/table_service.dart';
import 'package:tulasihotels/models/table_model.dart';

/// Real-time stream of all tables
final tablesStreamProvider = StreamProvider.autoDispose<List<TableModel>>((ref) {
  return TableService.tablesStream();
});

/// Selected floor filter (null = show all floors)
final selectedFloorProvider = StateProvider<int?>((ref) => null);

/// Filtered tables by floor
final filteredTablesProvider = Provider.autoDispose<AsyncValue<List<TableModel>>>((ref) {
  final tablesAsync = ref.watch(tablesStreamProvider);
  final selectedFloor = ref.watch(selectedFloorProvider);

  return tablesAsync.whenData((tables) {
    if (selectedFloor == null) return tables;
    return tables.where((t) => t.floor == selectedFloor).toList();
  });
});

/// Available floors (derived from tables data)
final availableFloorsProvider = Provider.autoDispose<List<int>>((ref) {
  final tablesAsync = ref.watch(tablesStreamProvider);
  return tablesAsync.whenOrNull(
        data: (tables) {
          final floors = tables.map((t) => t.floor).toSet().toList()..sort();
          return floors;
        },
      ) ??
      [];
});

/// Table count summary per status
final tableStatusSummaryProvider =
    Provider.autoDispose<Map<TableStatus, int>>((ref) {
  final tablesAsync = ref.watch(tablesStreamProvider);
  return tablesAsync.whenOrNull(
        data: (tables) {
          final summary = <TableStatus, int>{};
          for (final status in TableStatus.values) {
            summary[status] = tables.where((t) => t.status == status).length;
          }
          return summary;
        },
      ) ??
      {};
});
