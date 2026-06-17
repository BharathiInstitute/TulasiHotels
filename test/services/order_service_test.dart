/// Tests for OrderService — CRUD, queries, item status auto-advance
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/order_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String basePath;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    basePath = 'users/test-uid/orders';
  });

  group('create and read', () {
    test('writes and reads back all fields', () async {
      final order = makeOrder(
        id: 'o-1',
        orderNumber: 42,
        tableId: 'table-1',
        tableName: 'Table 1',
        waiterId: 'w-1',
        waiterName: 'Ravi',
        notes: 'Extra spicy',
        isRush: true,
        isVip: true,
      );

      await fakeFirestore
          .collection(basePath)
          .doc(order.id)
          .set(order.toFirestore());

      final doc = await fakeFirestore.collection(basePath).doc('o-1').get();
      final parsed = OrderModel.fromFirestore(doc);
      expect(parsed.orderNumber, 42);
      expect(parsed.tableId, 'table-1');
      expect(parsed.tableName, 'Table 1');
      expect(parsed.orderType, OrderType.dineIn);
      expect(parsed.waiterId, 'w-1');
      expect(parsed.waiterName, 'Ravi');
      expect(parsed.notes, 'Extra spicy');
      expect(parsed.isRush, isTrue);
      expect(parsed.isVip, isTrue);
      expect(parsed.items.length, 1);
    });
  });

  group('activeOrders query', () {
    test('filters by active statuses', () async {
      final activeStatuses = [
        OrderStatus.placed,
        OrderStatus.preparing,
        OrderStatus.ready,
        OrderStatus.served,
      ];
      final inactiveStatuses = [
        OrderStatus.billed,
        OrderStatus.cancelled,
      ];

      for (final s in activeStatuses) {
        final o = makeOrder(id: 'active-${s.name}', status: s);
        await fakeFirestore
            .collection(basePath)
            .doc(o.id)
            .set(o.toFirestore());
      }
      for (final s in inactiveStatuses) {
        final o = makeOrder(id: 'inactive-${s.name}', status: s);
        await fakeFirestore
            .collection(basePath)
            .doc(o.id)
            .set(o.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('status',
              whereIn: ['placed', 'preparing', 'ready', 'served'])
          .get();

      expect(snapshot.docs.length, 4);
    });
  });

  group('kitchenOrders query', () {
    test('filters placed and preparing only', () async {
      final o1 = makeOrder(id: 'k1');
      final o2 = makeOrder(id: 'k2', status: OrderStatus.preparing);
      final o3 = makeOrder(id: 'k3', status: OrderStatus.ready);
      final o4 = makeOrder(id: 'k4', status: OrderStatus.served);

      for (final o in [o1, o2, o3, o4]) {
        await fakeFirestore
            .collection(basePath)
            .doc(o.id)
            .set(o.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('status', whereIn: ['placed', 'preparing'])
          .get();

      expect(snapshot.docs.length, 2);
      final ids = snapshot.docs.map((d) => d.id).toSet();
      expect(ids, {'k1', 'k2'});
    });
  });

  group('tableOrders query', () {
    test('filters by tableId and active statuses', () async {
      final o1 = makeOrder(
          id: 't1', tableId: 'table-1');
      final o2 = makeOrder(
          id: 't2', tableId: 'table-2');
      final o3 = makeOrder(
          id: 't3', tableId: 'table-1', status: OrderStatus.billed);

      for (final o in [o1, o2, o3]) {
        await fakeFirestore
            .collection(basePath)
            .doc(o.id)
            .set(o.toFirestore());
      }

      final snapshot = await fakeFirestore
          .collection(basePath)
          .where('tableId', isEqualTo: 'table-1')
          .where('status',
              whereIn: ['placed', 'preparing', 'ready', 'served'])
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 't1');
    });
  });

  group('addItemsToOrder simulation', () {
    test('appends items and increments KOT', () async {
      final order = makeOrder(
        id: 'o-add',
        items: [makeOrderItem(name: 'Dosa')],
      );
      await fakeFirestore
          .collection(basePath)
          .doc(order.id)
          .set(order.toFirestore());

      // Simulate addItemsToOrder
      final nextKot = order.currentKotNumber + 1;
      final newItem =
          makeOrderItem(name: 'Idli', kotNumber: nextKot);
      final updatedOrder = order.copyWith(
        items: [...order.items, newItem],
        currentKotNumber: nextKot,
      );

      await fakeFirestore
          .collection(basePath)
          .doc(order.id)
          .update(updatedOrder.toFirestore());

      final doc =
          await fakeFirestore.collection(basePath).doc('o-add').get();
      final parsed = OrderModel.fromFirestore(doc);
      expect(parsed.items.length, 2);
      expect(parsed.currentKotNumber, 2);
      expect(parsed.items[1].name, 'Idli');
      expect(parsed.items[1].kotNumber, 2);
    });
  });

  group('updateItemStatus auto-advance logic', () {
    test('all items served → order status served', () {
      final items = [
        makeOrderItem(name: 'A', status: OrderItemStatus.served),
        makeOrderItem(name: 'B', status: OrderItemStatus.served),
      ];

      final allServed = items.every((i) => i.status == OrderItemStatus.served);
      expect(allServed, isTrue);
    });

    test('all items ready/served → order status ready', () {
      final items = [
        makeOrderItem(name: 'A', status: OrderItemStatus.ready),
        makeOrderItem(name: 'B', status: OrderItemStatus.served),
      ];

      final allReady = items.every(
        (i) =>
            i.status == OrderItemStatus.ready ||
            i.status == OrderItemStatus.served,
      );
      final allServed = items.every((i) => i.status == OrderItemStatus.served);
      expect(allServed, isFalse);
      expect(allReady, isTrue);
    });

    test('any item preparing → order status preparing', () {
      final items = [
        makeOrderItem(name: 'A', status: OrderItemStatus.preparing),
        makeOrderItem(name: 'B'),
      ];

      final anyPreparing =
          items.any((i) => i.status == OrderItemStatus.preparing);
      expect(anyPreparing, isTrue);
    });

    test('all pending → no auto-advance', () {
      final items = [
        makeOrderItem(name: 'A'),
        makeOrderItem(name: 'B'),
      ];

      final anyPreparing =
          items.any((i) => i.status == OrderItemStatus.preparing);
      final allReady = items.every(
        (i) =>
            i.status == OrderItemStatus.ready ||
            i.status == OrderItemStatus.served,
      );
      final allServed = items.every((i) => i.status == OrderItemStatus.served);
      expect(anyPreparing, isFalse);
      expect(allReady, isFalse);
      expect(allServed, isFalse);
    });
  });

  group('OrderStatus round-trip', () {
    test('all statuses survive Firestore', () async {
      for (final status in OrderStatus.values) {
        final o = makeOrder(id: 'os-${status.name}', status: status);
        await fakeFirestore
            .collection(basePath)
            .doc(o.id)
            .set(o.toFirestore());

        final doc =
            await fakeFirestore.collection(basePath).doc(o.id).get();
        final parsed = OrderModel.fromFirestore(doc);
        expect(parsed.status, status);
      }
    });
  });

  group('OrderType round-trip', () {
    test('all order types survive Firestore', () async {
      for (final type in OrderType.values) {
        final o = makeOrder(id: 'ot-${type.name}', orderType: type);
        await fakeFirestore
            .collection(basePath)
            .doc(o.id)
            .set(o.toFirestore());

        final doc =
            await fakeFirestore.collection(basePath).doc(o.id).get();
        final parsed = OrderModel.fromFirestore(doc);
        expect(parsed.orderType, type);
      }
    });
  });

  group('delete order', () {
    test('removes from collection', () async {
      final o = makeOrder(id: 'o-del');
      await fakeFirestore
          .collection(basePath)
          .doc(o.id)
          .set(o.toFirestore());

      await fakeFirestore.collection(basePath).doc('o-del').delete();
      final doc =
          await fakeFirestore.collection(basePath).doc('o-del').get();
      expect(doc.exists, isFalse);
    });
  });
}
