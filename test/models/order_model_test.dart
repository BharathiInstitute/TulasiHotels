import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/order_model.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('OrderStatus enum', () {
    test('fromString parses all values', () {
      for (final s in OrderStatus.values) {
        expect(OrderStatus.fromString(s.name), s);
      }
    });

    test('fromString defaults to placed', () {
      expect(OrderStatus.fromString('xyz'), OrderStatus.placed);
    });
  });

  group('OrderItemStatus enum', () {
    test('fromString parses all values', () {
      for (final s in OrderItemStatus.values) {
        expect(OrderItemStatus.fromString(s.name), s);
      }
    });

    test('fromString defaults to pending', () {
      expect(OrderItemStatus.fromString('xyz'), OrderItemStatus.pending);
    });
  });

  group('OrderType enum', () {
    test('fromString parses all values', () {
      for (final t in OrderType.values) {
        expect(OrderType.fromString(t.name), t);
      }
    });

    test('fromString defaults to dineIn', () {
      expect(OrderType.fromString('xyz'), OrderType.dineIn);
    });
  });

  group('OrderItem', () {
    test('total calculates price * quantity', () {
      final item = makeOrderItem(price: 200, quantity: 3);
      expect(item.total, 600);
    });

    test('toCartItem converts correctly', () {
      final item = makeOrderItem(
        productId: 'p1',
        name: 'Rice',
        price: 100,
        quantity: 2,
        unit: 'plate',
      );
      final cart = item.toCartItem();
      expect(cart.productId, 'p1');
      expect(cart.name, 'Rice');
      expect(cart.price, 100);
      expect(cart.quantity, 2);
      expect(cart.unit, 'plate');
    });

    test('copyWith updates status', () {
      final item = makeOrderItem();
      final updated = item.copyWith(status: OrderItemStatus.ready);
      expect(updated.status, OrderItemStatus.ready);
      expect(updated.productId, item.productId);
    });

    test('toMap serialises all fields', () {
      final item = makeOrderItem(
        itemNotes: 'Extra spicy',
        kitchenStation: 'Grill',
        preparationStartedAt: DateTime(2024, 1, 15, 12, 0),
      );
      final map = item.toMap();
      expect(map['productId'], 'prod-1');
      expect(map['status'], 'pending');
      expect(map['itemNotes'], 'Extra spicy');
      expect(map['kitchenStation'], 'Grill');
      expect(map['preparationStartedAt'], isA<int>());
    });

    test('fromMap deserialises correctly', () {
      final map = {
        'productId': 'p1',
        'name': 'Biryani',
        'price': 250.0,
        'quantity': 2,
        'unit': 'plate',
        'status': 'preparing',
        'kotNumber': 2,
      };
      final item = OrderItem.fromMap(map);
      expect(item.productId, 'p1');
      expect(item.name, 'Biryani');
      expect(item.price, 250);
      expect(item.status, OrderItemStatus.preparing);
      expect(item.kotNumber, 2);
    });

    test('fromMap handles missing fields with defaults', () {
      final item = OrderItem.fromMap({});
      expect(item.productId, '');
      expect(item.quantity, 1);
      expect(item.status, OrderItemStatus.pending);
      expect(item.kotNumber, 1);
    });
  });

  group('OrderModel', () {
    test('constructor defaults', () {
      final m = makeOrder();
      expect(m.status, OrderStatus.placed);
      expect(m.orderType, OrderType.dineIn);
      expect(m.isRush, false);
      expect(m.isCustomerOrder, false);
      expect(m.isVip, false);
    });

    test('total sums all item totals', () {
      final m = makeOrder(
        items: [
          makeOrderItem(price: 100, quantity: 2),
          makeOrderItem(price: 200, quantity: 1),
        ],
      );
      expect(m.total, 400);
    });

    test('total is 0 for empty items', () {
      final m = makeOrder(items: []);
      expect(m.total, 0);
    });

    test('itemCount sums all quantities', () {
      final m = makeOrder(
        items: [makeOrderItem(quantity: 2), makeOrderItem(quantity: 3)],
      );
      expect(m.itemCount, 5);
    });

    group('isActive', () {
      test('true for placed', () {
        expect(makeOrder(status: OrderStatus.placed).isActive, isTrue);
      });
      test('true for preparing', () {
        expect(makeOrder(status: OrderStatus.preparing).isActive, isTrue);
      });
      test('true for ready', () {
        expect(makeOrder(status: OrderStatus.ready).isActive, isTrue);
      });
      test('true for served', () {
        expect(makeOrder(status: OrderStatus.served).isActive, isTrue);
      });
      test('false for billed', () {
        expect(makeOrder(status: OrderStatus.billed).isActive, isFalse);
      });
      test('false for cancelled', () {
        expect(makeOrder(status: OrderStatus.cancelled).isActive, isFalse);
      });
    });

    group('allItemsServed', () {
      test('true when all served', () {
        final m = makeOrder(
          items: [
            makeOrderItem(status: OrderItemStatus.served),
            makeOrderItem(status: OrderItemStatus.served),
          ],
        );
        expect(m.allItemsServed, isTrue);
      });

      test('false when some not served', () {
        final m = makeOrder(
          items: [
            makeOrderItem(status: OrderItemStatus.served),
            makeOrderItem(status: OrderItemStatus.ready),
          ],
        );
        expect(m.allItemsServed, isFalse);
      });

      test('false when empty', () {
        final m = makeOrder(items: []);
        expect(m.allItemsServed, isFalse);
      });
    });

    group('allItemsReady', () {
      test('true when all ready or served', () {
        final m = makeOrder(
          items: [
            makeOrderItem(status: OrderItemStatus.ready),
            makeOrderItem(status: OrderItemStatus.served),
          ],
        );
        expect(m.allItemsReady, isTrue);
      });

      test('false when some still pending', () {
        final m = makeOrder(
          items: [
            makeOrderItem(status: OrderItemStatus.ready),
            makeOrderItem(status: OrderItemStatus.pending),
          ],
        );
        expect(m.allItemsReady, isFalse);
      });
    });

    group('filtered item lists', () {
      test('pendingItems returns only pending', () {
        final m = makeOrder(
          items: [
            makeOrderItem(productId: 'p1', status: OrderItemStatus.pending),
            makeOrderItem(productId: 'p2', status: OrderItemStatus.ready),
          ],
        );
        expect(m.pendingItems.length, 1);
        expect(m.pendingItems.first.productId, 'p1');
      });

      test('preparingItems returns only preparing', () {
        final m = makeOrder(
          items: [
            makeOrderItem(status: OrderItemStatus.preparing),
            makeOrderItem(status: OrderItemStatus.ready),
          ],
        );
        expect(m.preparingItems.length, 1);
      });

      test('readyItems returns only ready', () {
        final m = makeOrder(
          items: [
            makeOrderItem(status: OrderItemStatus.pending),
            makeOrderItem(status: OrderItemStatus.ready),
            makeOrderItem(status: OrderItemStatus.ready),
          ],
        );
        expect(m.readyItems.length, 2);
      });
    });

    test('elapsed returns positive duration', () {
      final m = makeOrder(
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(m.elapsed.inMinutes, greaterThanOrEqualTo(59));
    });

    test('copyWith updates status and isRush', () {
      final m = makeOrder();
      final updated = m.copyWith(status: OrderStatus.preparing, isRush: true);
      expect(updated.status, OrderStatus.preparing);
      expect(updated.isRush, true);
      expect(updated.id, m.id);
      expect(updated.orderNumber, m.orderNumber);
    });

    test('copyWith preserves values when not overridden', () {
      final m = makeOrder(waiterId: 'w1', waiterName: 'Ravi', isVip: true);
      final updated = m.copyWith();
      expect(updated.waiterId, 'w1');
      expect(updated.waiterName, 'Ravi');
      expect(updated.isVip, true);
    });

    group('Firestore round-trip', () {
      test('toFirestore serialises all fields', () {
        final m = makeOrder(
          tableId: 't1',
          tableName: 'Table 1',
          waiterId: 'w1',
          waiterName: 'Ravi',
          notes: 'VIP guest',
          isRush: true,
          isVip: true,
          customerName: 'Kumar',
        );
        final map = m.toFirestore();
        expect(map['orderNumber'], 1);
        expect(map['tableId'], 't1');
        expect(map['status'], 'placed');
        expect(map['orderType'], 'dineIn');
        expect(map['isRush'], true);
        expect(map['isVip'], true);
        expect(map['customerName'], 'Kumar');
        expect(map['items'], isList);
      });

      test('fromFirestore round-trip with FakeFirestore', () async {
        final firestore = FakeFirebaseFirestore();
        final original = makeOrder(
          orderNumber: 42,
          tableId: 't1',
          tableName: 'Table 1',
          items: [
            makeOrderItem(name: 'Biryani', price: 250, quantity: 2),
            makeOrderItem(
              name: 'Raita',
              price: 50,
              quantity: 1,
              status: OrderItemStatus.ready,
            ),
          ],
          status: OrderStatus.preparing,
          orderType: OrderType.dineIn,
          waiterId: 'w1',
          waiterName: 'Ravi',
          isRush: true,
          isVip: true,
          customerName: 'Kumar',
        );
        await firestore
            .collection('orders')
            .doc(original.id)
            .set(original.toFirestore());
        final doc = await firestore.collection('orders').doc(original.id).get();
        final restored = OrderModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.orderNumber, 42);
        expect(restored.tableId, 't1');
        expect(restored.items.length, 2);
        expect(restored.items[0].name, 'Biryani');
        expect(restored.items[1].status, OrderItemStatus.ready);
        expect(restored.status, OrderStatus.preparing);
        expect(restored.isRush, true);
        expect(restored.isVip, true);
        expect(restored.customerName, 'Kumar');
        expect(restored.total, 550);
      });
    });
  });
}
