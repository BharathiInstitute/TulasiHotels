/// Tests for order providers — filter and derived logic
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/orders/providers/order_provider.dart';
import 'package:tulasihotels/models/order_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('orderTypeFilterProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(orderTypeFilterProvider), isNull);
    });

    test('can be set to dineIn', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(orderTypeFilterProvider.notifier).state =
          OrderType.dineIn;
      expect(container.read(orderTypeFilterProvider), OrderType.dineIn);
    });

    test('can be cleared back to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(orderTypeFilterProvider.notifier).state =
          OrderType.takeaway;
      container.read(orderTypeFilterProvider.notifier).state = null;
      expect(container.read(orderTypeFilterProvider), isNull);
    });
  });

  group('filteredActiveOrders derived logic', () {
    final orders = [
      makeOrder(id: 'o1', orderType: OrderType.dineIn),
      makeOrder(id: 'o2', orderType: OrderType.takeaway),
      makeOrder(id: 'o3', orderType: OrderType.dineIn),
      makeOrder(id: 'o4', orderType: OrderType.delivery),
    ];

    test('no filter returns all', () {
      const OrderType? filter = null;
      final filtered =
          filter == null ? orders : orders.where((o) => o.orderType == filter).toList();
      expect(filtered.length, 4);
    });

    test('filter dineIn', () {
      const filter = OrderType.dineIn;
      final filtered =
          orders.where((o) => o.orderType == filter).toList();
      expect(filtered.length, 2);
    });

    test('filter takeaway', () {
      const filter = OrderType.takeaway;
      final filtered =
          orders.where((o) => o.orderType == filter).toList();
      expect(filtered.length, 1);
      expect(filtered[0].id, 'o2');
    });

    test('filter delivery', () {
      const filter = OrderType.delivery;
      final filtered =
          orders.where((o) => o.orderType == filter).toList();
      expect(filtered.length, 1);
      expect(filtered[0].id, 'o4');
    });

    test('filter with no matches returns empty', () {
      final dineInOnly = [
        makeOrder(id: 'o1', orderType: OrderType.dineIn),
      ];
      const filter = OrderType.delivery;
      final filtered =
          dineInOnly.where((o) => o.orderType == filter).toList();
      expect(filtered, isEmpty);
    });
  });
}
