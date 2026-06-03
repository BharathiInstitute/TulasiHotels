/// Integration test: Two orders on same table → merge
///
/// Tests order merging workflow: two orders on same table get combined
/// into one with correct KOT numbering and totals.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/order_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('Integration: Order Merge Flow', () {
    test('Step 1: Two separate orders on same table', () {
      final order1 = makeOrder(
        id: 'ord-1',
        orderNumber: 101,
        tableId: 'tbl-3',
        tableName: 'Table 3',
        items: [
          makeOrderItem(name: 'Biryani', price: 250, quantity: 2, kotNumber: 1),
          makeOrderItem(name: 'Raita', price: 50, quantity: 2, kotNumber: 1),
        ],
        currentKotNumber: 1,
      );
      final order2 = makeOrder(
        id: 'ord-2',
        orderNumber: 102,
        tableId: 'tbl-3',
        tableName: 'Table 3',
        items: [
          makeOrderItem(name: 'Naan', price: 60, quantity: 4, kotNumber: 1),
          makeOrderItem(name: 'Dal', price: 150, quantity: 1, kotNumber: 1),
        ],
        currentKotNumber: 1,
      );

      expect(order1.total, 600); // 250*2 + 50*2
      expect(order2.total, 390); // 60*4 + 150*1
      expect(order1.isActive, isTrue);
      expect(order2.isActive, isTrue);
    });

    test('Step 2: Simulate merge — combine items with new KOT', () {
      final target = makeOrder(
        id: 'ord-1',
        orderNumber: 101,
        tableId: 'tbl-3',
        items: [
          makeOrderItem(name: 'Biryani', price: 250, quantity: 2, kotNumber: 1),
          makeOrderItem(name: 'Raita', price: 50, quantity: 2, kotNumber: 1),
        ],
        currentKotNumber: 1,
      );
      final source = makeOrder(
        id: 'ord-2',
        orderNumber: 102,
        tableId: 'tbl-3',
        items: [
          makeOrderItem(name: 'Naan', price: 60, quantity: 4, kotNumber: 1),
          makeOrderItem(name: 'Dal', price: 150, quantity: 1, kotNumber: 1),
        ],
        currentKotNumber: 1,
      );

      // Merge logic (mirrors OrderService.mergeOrders)
      final nextKot = target.currentKotNumber + 1;
      final sourceItems = source.items
          .map((item) => item.copyWith(kotNumber: nextKot))
          .toList();

      final merged = target.copyWith(
        items: [...target.items, ...sourceItems],
        currentKotNumber: nextKot,
      );

      expect(merged.items, hasLength(4));
      expect(merged.total, 990); // 600 + 390
      expect(merged.currentKotNumber, 2);
    });

    test('Step 3: Source items get new KOT number', () {
      final sourceItems = [
        makeOrderItem(name: 'Naan', price: 60, quantity: 4, kotNumber: 1),
        makeOrderItem(name: 'Dal', price: 150, quantity: 1, kotNumber: 1),
      ];

      final reTagged = sourceItems
          .map((item) => item.copyWith(kotNumber: 2))
          .toList();

      expect(reTagged.every((item) => item.kotNumber == 2), isTrue);
      // Original names and prices preserved
      expect(reTagged[0].name, 'Naan');
      expect(reTagged[0].price, 60);
      expect(reTagged[1].name, 'Dal');
    });

    test('Step 4: Source order cancelled after merge', () {
      final cancelled = makeOrder(
        id: 'ord-2',
        status: OrderStatus.cancelled,
        items: [
          makeOrderItem(name: 'Naan', price: 60, quantity: 4),
          makeOrderItem(name: 'Dal', price: 150, quantity: 1),
        ],
      );

      expect(cancelled.isActive, isFalse);
      expect(cancelled.status, OrderStatus.cancelled);
    });

    test('Step 5: Merged order total spans both original orders', () {
      final merged = makeOrder(
        id: 'ord-1',
        items: [
          // From original order (KOT 1)
          makeOrderItem(name: 'Biryani', price: 250, quantity: 2, kotNumber: 1),
          makeOrderItem(name: 'Raita', price: 50, quantity: 2, kotNumber: 1),
          // From merged order (KOT 2)
          makeOrderItem(name: 'Naan', price: 60, quantity: 4, kotNumber: 2),
          makeOrderItem(name: 'Dal', price: 150, quantity: 1, kotNumber: 2),
        ],
        currentKotNumber: 2,
      );

      expect(merged.total, 990);
      expect(merged.itemCount, 9); // 2+2+4+1
      expect(merged.items.where((i) => i.kotNumber == 1), hasLength(2));
      expect(merged.items.where((i) => i.kotNumber == 2), hasLength(2));
    });

    test('Step 6: Adding items post-merge bumps KOT again', () {
      final merged = makeOrder(
        id: 'ord-1',
        items: [
          makeOrderItem(name: 'Biryani', price: 250, quantity: 2, kotNumber: 1),
          makeOrderItem(name: 'Raita', price: 50, quantity: 2, kotNumber: 1),
          makeOrderItem(name: 'Naan', price: 60, quantity: 4, kotNumber: 2),
          makeOrderItem(name: 'Dal', price: 150, quantity: 1, kotNumber: 2),
        ],
        currentKotNumber: 2,
      );

      // Add dessert as KOT 3
      final newItem = makeOrderItem(
        name: 'Gulab Jamun',
        price: 80,
        quantity: 2,
        kotNumber: 3,
      );
      final updated = merged.copyWith(
        items: [...merged.items, newItem],
        currentKotNumber: 3,
      );

      expect(updated.items, hasLength(5));
      expect(updated.total, 1150); // 990 + 160
      expect(updated.currentKotNumber, 3);
    });
  });

  group('Integration: Order type variations', () {
    test('takeaway order has no table', () {
      final order = makeOrder(
        id: 'ord-10',
        orderType: OrderType.takeaway,
        items: [makeOrderItem(name: 'Biryani Parcel', price: 280, quantity: 1)],
      );

      expect(order.orderType, OrderType.takeaway);
      expect(order.tableId, isNull);
      expect(order.isActive, isTrue);
    });

    test('delivery order tracks customer info', () {
      final order = makeOrder(
        id: 'ord-11',
        orderType: OrderType.delivery,
        customerName: 'Ravi Kumar',
        customerPhone: '9876543210',
        items: [makeOrderItem(name: 'Pizza', price: 350, quantity: 2)],
      );

      expect(order.orderType, OrderType.delivery);
      expect(order.customerName, 'Ravi Kumar');
      expect(order.customerPhone, '9876543210');
      expect(order.total, 700);
    });
  });
}
