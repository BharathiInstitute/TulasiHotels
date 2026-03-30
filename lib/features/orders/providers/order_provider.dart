/// Order management providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/orders/services/order_service.dart';
import 'package:tulasihotels/models/order_model.dart';

/// Real-time stream of all active orders (not billed/cancelled)
final activeOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  return OrderService.activeOrdersStream();
});

/// Real-time stream of orders for kitchen display (placed + preparing)
final kitchenOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  return OrderService.kitchenOrdersStream();
});

/// Real-time stream of orders for a specific table
final tableOrdersProvider =
    StreamProvider.autoDispose.family<List<OrderModel>, String>((ref, tableId) {
  return OrderService.tableOrdersStream(tableId);
});

/// Filter for order type in the orders list
final orderTypeFilterProvider = StateProvider<OrderType?>((ref) => null);

/// Filtered active orders by type
final filteredActiveOrdersProvider =
    Provider.autoDispose<AsyncValue<List<OrderModel>>>((ref) {
  final ordersAsync = ref.watch(activeOrdersProvider);
  final typeFilter = ref.watch(orderTypeFilterProvider);

  return ordersAsync.whenData((orders) {
    if (typeFilter == null) return orders;
    return orders.where((o) => o.orderType == typeFilter).toList();
  });
});
