/// KOT (Kitchen Order Ticket) printing service
/// Extends the existing EscPosBuilder for kitchen tickets
library;

import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:tulasihotels/core/services/offline_storage_service.dart';
import 'package:tulasihotels/models/order_model.dart';

/// Builds KOT (Kitchen Order Ticket) byte sequences for thermal printers
class KotPrinter {
  KotPrinter._();

  static final _timeFormat = DateFormat('hh:mm a');

  // ESC/POS commands (same as EscPosBuilder)
  static List<int> _init() => [0x1B, 0x40, 0x1B, 0x74, 0x6F];
  static List<int> _center() => [0x1B, 0x61, 0x01];
  static List<int> _left() => [0x1B, 0x61, 0x00];
  static List<int> _bold(bool on) => [0x1B, 0x45, on ? 0x01 : 0x00];
  static List<int> _doubleHeight(bool on) => [0x1B, 0x21, on ? 0x10 : 0x00];
  static List<int> _feed(int lines) => [0x1B, 0x64, lines];
  static List<int> _cut() => [0x1D, 0x56, 0x00];
  static List<int> _text(String t) => utf8.encode(t);

  static int _getWidth() {
    final custom = PrinterStorage.getSavedCustomWidth();
    if (custom > 0) return custom;
    return 32; // Default for 58mm
  }

  /// Build KOT bytes for a newly placed order
  static List<int> buildKOT({
    required OrderModel order,
    int? kotNumber,
    List<OrderItem>? itemsOverride,
  }) {
    final items = itemsOverride ?? order.items;
    final kot = kotNumber ?? order.currentKotNumber;
    final chars = _getWidth();
    final bytes = <int>[];

    bytes.addAll(_init());

    // Header: KOT
    bytes.addAll(_center());
    bytes.addAll(_bold(true));
    bytes.addAll(_doubleHeight(true));
    bytes.addAll(_text('** KOT **\n'));
    bytes.addAll(_doubleHeight(false));
    bytes.addAll(_bold(false));

    bytes.addAll(_text('${'=' * chars}\n'));

    // Order info
    bytes.addAll(_left());
    bytes.addAll(_bold(true));
    bytes.addAll(_text('Order #${order.orderNumber}'));
    bytes.addAll(_bold(false));
    bytes.addAll(_text('  KOT #$kot\n'));

    // Table
    if (order.tableName != null) {
      bytes.addAll(_bold(true));
      bytes.addAll(_doubleHeight(true));
      bytes.addAll(_text('${order.tableName}\n'));
      bytes.addAll(_doubleHeight(false));
      bytes.addAll(_bold(false));
    } else {
      bytes.addAll(_text('${order.orderType.displayName}\n'));
    }

    // Time & Waiter
    bytes.addAll(_text('Time: ${_timeFormat.format(order.createdAt)}\n'));
    if (order.waiterName != null) {
      bytes.addAll(_text('Waiter: ${order.waiterName}\n'));
    }

    bytes.addAll(_text('${'-' * chars}\n'));

    // Items — large and clear for kitchen
    bytes.addAll(_bold(true));
    for (final item in items) {
      // Quantity × Item name
      bytes.addAll(_text('${item.quantity}x ${item.name}\n'));

      // Item notes (important for kitchen)
      if (item.itemNotes != null && item.itemNotes!.isNotEmpty) {
        bytes.addAll(_bold(false));
        bytes.addAll(_text('   >> ${item.itemNotes}\n'));
        bytes.addAll(_bold(true));
      }
    }
    bytes.addAll(_bold(false));

    bytes.addAll(_text('${'-' * chars}\n'));

    // Order notes
    if (order.notes != null && order.notes!.isNotEmpty) {
      bytes.addAll(_text('NOTE: ${order.notes}\n'));
      bytes.addAll(_text('${'-' * chars}\n'));
    }

    // Footer
    bytes.addAll(_center());
    bytes.addAll(_text('Total items: ${items.length}\n'));
    bytes.addAll(_text('${_timeFormat.format(DateTime.now())}\n'));

    bytes.addAll(_feed(3));
    bytes.addAll(_cut());

    return bytes;
  }

  /// Build KOT for amendment (only new items)
  static List<int> buildAmendmentKOT({
    required OrderModel order,
    required List<OrderItem> newItems,
    required int kotNumber,
  }) {
    final chars = _getWidth();
    final bytes = <int>[];

    bytes.addAll(_init());

    // Header: AMENDMENT KOT
    bytes.addAll(_center());
    bytes.addAll(_bold(true));
    bytes.addAll(_doubleHeight(true));
    bytes.addAll(_text('** ADD KOT **\n'));
    bytes.addAll(_doubleHeight(false));
    bytes.addAll(_bold(false));

    bytes.addAll(_text('${'=' * chars}\n'));

    // Reuse the same body format
    bytes.addAll(_left());
    bytes.addAll(_bold(true));
    bytes.addAll(_text('Order #${order.orderNumber}'));
    bytes.addAll(_bold(false));
    bytes.addAll(_text('  KOT #$kotNumber\n'));

    if (order.tableName != null) {
      bytes.addAll(_bold(true));
      bytes.addAll(_doubleHeight(true));
      bytes.addAll(_text('${order.tableName}\n'));
      bytes.addAll(_doubleHeight(false));
      bytes.addAll(_bold(false));
    }

    bytes.addAll(_text('Time: ${_timeFormat.format(DateTime.now())}\n'));
    bytes.addAll(_text('${'-' * chars}\n'));

    // New items only
    bytes.addAll(_bold(true));
    for (final item in newItems) {
      bytes.addAll(_text('${item.quantity}x ${item.name}\n'));
      if (item.itemNotes != null && item.itemNotes!.isNotEmpty) {
        bytes.addAll(_bold(false));
        bytes.addAll(_text('   >> ${item.itemNotes}\n'));
        bytes.addAll(_bold(true));
      }
    }
    bytes.addAll(_bold(false));

    bytes.addAll(_text('${'-' * chars}\n'));
    bytes.addAll(_center());
    bytes.addAll(_text('ADDITIONAL ITEMS\n'));

    bytes.addAll(_feed(3));
    bytes.addAll(_cut());

    return bytes;
  }

  /// Build station-wise KOTs — groups items by kitchenStation and returns
  /// a map of station name → KOT bytes. Stations without a name fall
  /// into the "Main Kitchen" bucket.
  static Map<String, List<int>> buildStationKOTs({
    required OrderModel order,
    int? kotNumber,
  }) {
    final stationMap = <String, List<OrderItem>>{};
    for (final item in order.items) {
      final station = item.kitchenStation ?? 'Main Kitchen';
      stationMap.putIfAbsent(station, () => []).add(item);
    }

    final result = <String, List<int>>{};
    for (final entry in stationMap.entries) {
      result[entry.key] = buildKOT(
        order: order,
        kotNumber: kotNumber,
        itemsOverride: entry.value,
      );
    }
    return result;
  }
}
