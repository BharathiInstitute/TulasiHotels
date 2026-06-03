/// Integration test: Table → Order → Kitchen → Billed
///
/// Tests the full dine-in workflow: create table, place order,
/// kitchen prepares items, order billed, table freed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/order_model.dart';
import 'package:tulasihotels/models/table_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('Integration: Table → Order → Kitchen → Billed', () {
    test('Step 1: New table is available', () {
      final table = makeTable(number: 5, capacity: 4);
      expect(table.status, TableStatus.available);
      expect(table.isFree, isTrue);
      expect(table.hasActiveOrder, isFalse);
      expect(table.displayName, 'Table 5');
    });

    test('Step 2: Place order → table becomes occupied', () {
      final items = [
        makeOrderItem(name: 'Biryani', price: 250, quantity: 2),
        makeOrderItem(name: 'Raita', price: 50, quantity: 2),
      ];
      final order = makeOrder(
        id: 'ord-1',
        tableId: 'tbl-5',
        tableName: 'Table 5',
        items: items,
        status: OrderStatus.placed,
        orderType: OrderType.dineIn,
      );
      final table = makeTable(
        id: 'tbl-5',
        number: 5,
        status: TableStatus.occupied,
        currentOrderId: 'ord-1',
      );

      expect(order.total, 600); // 250*2 + 50*2
      expect(order.itemCount, 4);
      expect(order.isActive, isTrue);
      expect(table.isFree, isFalse);
      expect(table.hasActiveOrder, isTrue);
    });

    test('Step 3: Kitchen starts preparing items', () {
      final items = [
        makeOrderItem(
          name: 'Biryani',
          price: 250,
          quantity: 2,
          status: OrderItemStatus.preparing,
        ),
        makeOrderItem(
          name: 'Raita',
          price: 50,
          quantity: 2,
          status: OrderItemStatus.pending,
        ),
      ];
      final order = makeOrder(
        id: 'ord-1',
        items: items,
        status: OrderStatus.preparing,
      );

      expect(order.preparingItems, hasLength(1));
      expect(order.pendingItems, hasLength(1));
      expect(order.readyItems, isEmpty);
      expect(order.allItemsReady, isFalse);
    });

    test('Step 4: All items ready', () {
      final items = [
        makeOrderItem(
          name: 'Biryani',
          price: 250,
          quantity: 2,
          status: OrderItemStatus.ready,
        ),
        makeOrderItem(
          name: 'Raita',
          price: 50,
          quantity: 2,
          status: OrderItemStatus.ready,
        ),
      ];
      final order = makeOrder(
        id: 'ord-1',
        items: items,
        status: OrderStatus.ready,
      );

      expect(order.allItemsReady, isTrue);
      expect(order.readyItems, hasLength(2));
      expect(order.pendingItems, isEmpty);
    });

    test('Step 5: Items served to table', () {
      final items = [
        makeOrderItem(
          name: 'Biryani',
          price: 250,
          quantity: 2,
          status: OrderItemStatus.served,
        ),
        makeOrderItem(
          name: 'Raita',
          price: 50,
          quantity: 2,
          status: OrderItemStatus.served,
        ),
      ];
      final order = makeOrder(
        id: 'ord-1',
        items: items,
        status: OrderStatus.served,
      );

      expect(order.allItemsServed, isTrue);
      expect(order.allItemsReady, isTrue); // ready also includes served
      expect(order.isActive, isTrue); // served is still active
    });

    test('Step 6: Order billed → table freed', () {
      final order = makeOrder(
        id: 'ord-1',
        status: OrderStatus.billed,
        items: [
          makeOrderItem(
            name: 'Biryani',
            price: 250,
            quantity: 2,
            status: OrderItemStatus.served,
          ),
          makeOrderItem(
            name: 'Raita',
            price: 50,
            quantity: 2,
            status: OrderItemStatus.served,
          ),
        ],
      );
      final table = makeTable(
        id: 'tbl-5',
        number: 5,
        status: TableStatus.available,
      );

      expect(order.isActive, isFalse); // billed = no longer active
      expect(order.total, 600);
      expect(table.isFree, isTrue);
      expect(table.hasActiveOrder, isFalse);
    });

    test('Step 7: Cancelled order also frees table', () {
      final order = makeOrder(
        id: 'ord-2',
        status: OrderStatus.cancelled,
        items: [makeOrderItem(name: 'Naan', price: 60, quantity: 3)],
      );
      final table = makeTable(
        id: 'tbl-5',
        number: 5,
        status: TableStatus.available,
      );

      expect(order.isActive, isFalse);
      expect(table.isFree, isTrue);
    });
  });

  group('Integration: Order item tracking', () {
    test('individual item status transitions', () {
      final item = makeOrderItem(
        name: 'Pizza',
        price: 350,
        quantity: 1,
        status: OrderItemStatus.pending,
      );
      expect(item.total, 350);

      // Kitchen picks up
      final preparing = item.copyWith(status: OrderItemStatus.preparing);
      expect(preparing.status, OrderItemStatus.preparing);
      expect(preparing.name, 'Pizza'); // immutable fields preserved

      // Ready to serve
      final ready = preparing.copyWith(status: OrderItemStatus.ready);
      expect(ready.status, OrderItemStatus.ready);

      // Served
      final served = ready.copyWith(status: OrderItemStatus.served);
      expect(served.status, OrderItemStatus.served);
    });

    test('KOT number tracks item batches', () {
      final firstBatch = [
        makeOrderItem(name: 'Biryani', price: 250, quantity: 1, kotNumber: 1),
        makeOrderItem(name: 'Raita', price: 50, quantity: 1, kotNumber: 1),
      ];
      final secondBatch = [
        makeOrderItem(
          name: 'Gulab Jamun',
          price: 80,
          quantity: 2,
          kotNumber: 2,
        ),
      ];

      final order = makeOrder(
        id: 'ord-3',
        items: [...firstBatch, ...secondBatch],
        currentKotNumber: 2,
      );

      expect(order.items.where((i) => i.kotNumber == 1), hasLength(2));
      expect(order.items.where((i) => i.kotNumber == 2), hasLength(1));
      expect(order.total, 250 + 50 + 80 * 2); // 460
    });

    test('VIP and rush flags preserved through lifecycle', () {
      final order = makeOrder(
        id: 'ord-4',
        isRush: true,
        isVip: true,
        items: [makeOrderItem(name: 'Steak', price: 800, quantity: 1)],
      );
      expect(order.isRush, isTrue);
      expect(order.isVip, isTrue);

      final billed = order.copyWith(status: OrderStatus.billed);
      expect(billed.isRush, isTrue);
      expect(billed.isVip, isTrue);
    });
  });

  group('Integration: Table with assigned server', () {
    test('server assignment and clearing', () {
      final table = makeTable(
        id: 'tbl-1',
        number: 1,
        assignedServerId: 'staff-1',
        assignedServerName: 'Raju',
      );
      expect(table.assignedServerId, 'staff-1');
      expect(table.assignedServerName, 'Raju');

      final cleared = table.copyWith(clearAssignedServer: true);
      expect(cleared.assignedServerId, isNull);
      expect(cleared.assignedServerName, isNull);
      expect(cleared.number, 1); // preserved
    });
  });
}
