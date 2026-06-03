/// Tests for KotPrinter — ESC/POS byte generation for kitchen order tickets.
///
/// Validates ticket structure, item formatting, station grouping,
/// and amendment KOT generation.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/kitchen/services/kot_printer_service.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('KotPrinter.buildKOT', () {
    test('returns non-empty byte list', () {
      final order = makeOrder(
        orderNumber: 42,
        items: [makeOrderItem(name: 'Dosa', quantity: 2)],
      );
      final bytes = KotPrinter.buildKOT(order: order);
      expect(bytes, isNotEmpty);
    });

    test('starts with ESC/POS init sequence', () {
      final order = makeOrder(items: [makeOrderItem()]);
      final bytes = KotPrinter.buildKOT(order: order);
      // Init: 0x1B, 0x40 = ESC @
      expect(bytes[0], 0x1B);
      expect(bytes[1], 0x40);
    });

    test('ends with cut command', () {
      final order = makeOrder(items: [makeOrderItem()]);
      final bytes = KotPrinter.buildKOT(order: order);
      // Cut: 0x1D, 0x56, 0x00
      expect(bytes[bytes.length - 3], 0x1D);
      expect(bytes[bytes.length - 2], 0x56);
      expect(bytes[bytes.length - 1], 0x00);
    });

    test('contains KOT header text', () {
      final order = makeOrder(items: [makeOrderItem()]);
      final bytes = KotPrinter.buildKOT(order: order);
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('** KOT **'));
    });

    test('contains order number', () {
      final order = makeOrder(orderNumber: 99, items: [makeOrderItem()]);
      final bytes = KotPrinter.buildKOT(order: order);
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('Order #99'));
    });

    test('contains KOT number', () {
      final order = makeOrder(items: [makeOrderItem()], currentKotNumber: 3);
      final bytes = KotPrinter.buildKOT(order: order, kotNumber: 5);
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('KOT #5'));
    });

    test('uses order currentKotNumber when kotNumber not specified', () {
      final order = makeOrder(items: [makeOrderItem()], currentKotNumber: 7);
      final bytes = KotPrinter.buildKOT(order: order);
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('KOT #7'));
    });

    test('contains table name when set', () {
      final order = makeOrder(tableName: 'Table 5', items: [makeOrderItem()]);
      final bytes = KotPrinter.buildKOT(order: order);
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('Table 5'));
    });

    test('contains item quantities and names', () {
      final order = makeOrder(
        items: [
          makeOrderItem(name: 'Idli', quantity: 3),
          makeOrderItem(name: 'Vada', quantity: 1, productId: 'p2'),
        ],
      );
      final bytes = KotPrinter.buildKOT(order: order);
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('3x Idli'));
      expect(text, contains('1x Vada'));
    });

    test('contains item notes when present', () {
      final order = makeOrder(
        items: [makeOrderItem(name: 'Dosa', itemNotes: 'Extra crispy')],
      );
      final bytes = KotPrinter.buildKOT(order: order);
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('Extra crispy'));
    });

    test('contains order notes when present', () {
      final order = makeOrder(items: [makeOrderItem()], notes: 'Urgent table');
      final bytes = KotPrinter.buildKOT(order: order);
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('NOTE: Urgent table'));
    });

    test('contains total items count', () {
      final order = makeOrder(
        items: [
          makeOrderItem(name: 'A'),
          makeOrderItem(name: 'B', productId: 'p2'),
          makeOrderItem(name: 'C', productId: 'p3'),
        ],
      );
      final bytes = KotPrinter.buildKOT(order: order);
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('Total items: 3'));
    });

    test('itemsOverride replaces order items', () {
      final order = makeOrder(items: [makeOrderItem(name: 'Original')]);
      final overrideItems = [
        makeOrderItem(name: 'Override1'),
        makeOrderItem(name: 'Override2', productId: 'p2'),
      ];
      final bytes = KotPrinter.buildKOT(
        order: order,
        itemsOverride: overrideItems,
      );
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('Override1'));
      expect(text, contains('Override2'));
      expect(text, isNot(contains('Original')));
    });

    test('waiter name is included when set', () {
      final order = makeOrder(items: [makeOrderItem()], waiterName: 'Rahul');
      final bytes = KotPrinter.buildKOT(order: order);
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('Waiter: Rahul'));
    });
  });

  group('KotPrinter.buildAmendmentKOT', () {
    test('contains ADD KOT header', () {
      final order = makeOrder(items: [makeOrderItem()]);
      final newItems = [makeOrderItem(name: 'Juice')];
      final bytes = KotPrinter.buildAmendmentKOT(
        order: order,
        newItems: newItems,
        kotNumber: 2,
      );
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('** ADD KOT **'));
    });

    test('contains ADDITIONAL ITEMS footer', () {
      final order = makeOrder(items: [makeOrderItem()]);
      final newItems = [makeOrderItem(name: 'Juice')];
      final bytes = KotPrinter.buildAmendmentKOT(
        order: order,
        newItems: newItems,
        kotNumber: 2,
      );
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('ADDITIONAL ITEMS'));
    });

    test('only contains new items, not original items', () {
      final order = makeOrder(items: [makeOrderItem(name: 'OldItem')]);
      final newItems = [makeOrderItem(name: 'NewItem')];
      final bytes = KotPrinter.buildAmendmentKOT(
        order: order,
        newItems: newItems,
        kotNumber: 2,
      );
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('NewItem'));
      expect(text, isNot(contains('OldItem')));
    });

    test('contains order number', () {
      final order = makeOrder(orderNumber: 55, items: [makeOrderItem()]);
      final bytes = KotPrinter.buildAmendmentKOT(
        order: order,
        newItems: [makeOrderItem()],
        kotNumber: 3,
      );
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('Order #55'));
      expect(text, contains('KOT #3'));
    });

    test('ends with cut command', () {
      final order = makeOrder(items: [makeOrderItem()]);
      final bytes = KotPrinter.buildAmendmentKOT(
        order: order,
        newItems: [makeOrderItem()],
        kotNumber: 1,
      );
      expect(bytes[bytes.length - 3], 0x1D);
      expect(bytes[bytes.length - 2], 0x56);
    });
  });

  group('KotPrinter.buildStationKOTs', () {
    test('groups items by kitchenStation', () {
      final order = makeOrder(
        items: [
          makeOrderItem(name: 'Dosa', kitchenStation: 'Grill'),
          makeOrderItem(
            name: 'Chai',
            productId: 'p2',
            kitchenStation: 'Drinks',
          ),
          makeOrderItem(
            name: 'Paratha',
            productId: 'p3',
            kitchenStation: 'Grill',
          ),
        ],
      );
      final result = KotPrinter.buildStationKOTs(order: order);
      expect(result.keys, containsAll(['Grill', 'Drinks']));
      expect(result.length, 2);
    });

    test('items without station go to Main Kitchen', () {
      final order = makeOrder(
        items: [
          makeOrderItem(name: 'Dosa'),
          makeOrderItem(
            name: 'Chai',
            productId: 'p2',
            kitchenStation: 'Drinks',
          ),
        ],
      );
      final result = KotPrinter.buildStationKOTs(order: order);
      expect(result.keys, contains('Main Kitchen'));
      expect(result.keys, contains('Drinks'));
    });

    test('each station KOT is valid byte sequence', () {
      final order = makeOrder(
        items: [
          makeOrderItem(name: 'A', kitchenStation: 'S1'),
          makeOrderItem(name: 'B', productId: 'p2', kitchenStation: 'S2'),
        ],
      );
      final result = KotPrinter.buildStationKOTs(order: order);
      for (final bytes in result.values) {
        expect(bytes, isNotEmpty);
        // Starts with init
        expect(bytes[0], 0x1B);
        expect(bytes[1], 0x40);
        // Ends with cut
        expect(bytes[bytes.length - 3], 0x1D);
      }
    });

    test('station KOT contains only that station items', () {
      final order = makeOrder(
        items: [
          makeOrderItem(name: 'Dosa', kitchenStation: 'Grill'),
          makeOrderItem(name: 'Chai', productId: 'p2', kitchenStation: 'Bar'),
        ],
      );
      final result = KotPrinter.buildStationKOTs(order: order);
      final grillText = utf8.decode(result['Grill']!, allowMalformed: true);
      final barText = utf8.decode(result['Bar']!, allowMalformed: true);
      expect(grillText, contains('Dosa'));
      expect(grillText, isNot(contains('Chai')));
      expect(barText, contains('Chai'));
      expect(barText, isNot(contains('Dosa')));
    });

    test('single station returns single entry', () {
      final order = makeOrder(
        items: [
          makeOrderItem(name: 'A', kitchenStation: 'Only'),
          makeOrderItem(name: 'B', productId: 'p2', kitchenStation: 'Only'),
        ],
      );
      final result = KotPrinter.buildStationKOTs(order: order);
      expect(result.length, 1);
      expect(result.keys.first, 'Only');
    });
  });
}
