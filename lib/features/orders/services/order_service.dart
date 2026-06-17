/// Order management service — Firestore CRUD for orders
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/tables/services/table_service.dart';
import 'package:tulasihotels/models/order_model.dart';
import 'package:tulasihotels/models/table_model.dart';

class OrderService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

  static CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('$_basePath/orders');

  /// Stream all active (non-billed, non-cancelled) orders
  static Stream<List<OrderModel>> activeOrdersStream() {
    return _ordersRef
        .where('status', whereIn: ['placed', 'preparing', 'ready', 'served'])
        .snapshots()
        .map(
          (snapshot) {
            final orders = snapshot.docs
                .map((doc) => OrderModel.fromFirestore(doc))
                .toList();
            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return orders;
          },
        );
  }

  /// Stream orders for a specific table
  static Stream<List<OrderModel>> tableOrdersStream(String tableId) {
    return _ordersRef
        .where('tableId', isEqualTo: tableId)
        .where('status', whereIn: ['placed', 'preparing', 'ready', 'served'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream orders for kitchen display (placed + preparing)
  static Stream<List<OrderModel>> kitchenOrdersStream() {
    return _ordersRef
        .where('status', whereIn: ['placed', 'preparing'])
        .snapshots()
        .map(
          (snapshot) {
            final orders = snapshot.docs
                .map((doc) => OrderModel.fromFirestore(doc))
                .toList();
            orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            return orders;
          },
        );
  }

  /// Get a single order by ID
  static Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc);
  }

  /// Create a new order and update table status
  static Future<OrderModel> createOrder({
    required List<OrderItem> items,
    required OrderType orderType,
    String? tableId,
    String? tableName,
    String? waiterId,
    String? waiterName,
    String? notes,
    bool isRush = false,
    bool isVip = false,
  }) async {
    final id = generateSafeId('order');
    final now = DateTime.now();
    final orderNumber = generateBillNumber(); // reuse the number generator

    final order = OrderModel(
      id: id,
      orderNumber: orderNumber,
      tableId: tableId,
      tableName: tableName,
      items: items,
      orderType: orderType,
      waiterId: waiterId,
      waiterName: waiterName,
      notes: notes,
      isRush: isRush,
      isVip: isVip,
      createdAt: now,
      updatedAt: now,
    );

    await _ordersRef.doc(id).set(order.toFirestore());

    // Update table status to occupied if dine-in
    if (tableId != null && orderType == OrderType.dineIn) {
      await TableService.updateTableStatus(
        tableId,
        TableStatus.occupied,
        currentOrderId: id,
      );
    }

    debugPrint('✅ Created order #$orderNumber for ${tableName ?? orderType.displayName}');
    return order;
  }

  /// Add items to an existing order (amendment — new KOT)
  static Future<OrderModel> addItemsToOrder({
    required String orderId,
    required List<OrderItem> newItems,
  }) async {
    final order = await getOrder(orderId);
    if (order == null) throw Exception('Order not found: $orderId');

    final nextKot = order.currentKotNumber + 1;
    final itemsWithKot =
        newItems.map((item) => item.copyWith(kotNumber: nextKot)).toList();

    final updatedOrder = order.copyWith(
      items: [...order.items, ...itemsWithKot],
      currentKotNumber: nextKot,
    );

    await _ordersRef.doc(orderId).update(updatedOrder.toFirestore());
    debugPrint('✅ Added ${newItems.length} items to order #${order.orderNumber} (KOT #$nextKot)');
    return updatedOrder;
  }

  /// Update order status
  static Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    await _ordersRef.doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update a specific item's status within an order
  static Future<void> updateItemStatus(
    String orderId,
    int itemIndex,
    OrderItemStatus status,
  ) async {
    final order = await getOrder(orderId);
    if (order == null) return;

    final updatedItems = List<OrderItem>.from(order.items);
    if (itemIndex < 0 || itemIndex >= updatedItems.length) return;

    updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(status: status);

    // Auto-advance order status based on items
    OrderStatus? newOrderStatus;
    final allPreparing = updatedItems.any(
      (i) => i.status == OrderItemStatus.preparing,
    );
    final allReady = updatedItems.every(
      (i) =>
          i.status == OrderItemStatus.ready ||
          i.status == OrderItemStatus.served,
    );
    final allServed = updatedItems.every(
      (i) => i.status == OrderItemStatus.served,
    );

    if (allServed) {
      newOrderStatus = OrderStatus.served;
    } else if (allReady) {
      newOrderStatus = OrderStatus.ready;
    } else if (allPreparing) {
      newOrderStatus = OrderStatus.preparing;
    }

    final updates = <String, dynamic>{
      'items': updatedItems.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (newOrderStatus != null) {
      updates['status'] = newOrderStatus.name;
    }

    await _ordersRef.doc(orderId).update(updates);
  }

  /// Mark all items in an order as ready (kitchen marks entire order done)
  static Future<void> markAllItemsReady(String orderId) async {
    final order = await getOrder(orderId);
    if (order == null) return;

    final updatedItems = order.items
        .map((item) => item.copyWith(status: OrderItemStatus.ready))
        .toList();

    await _ordersRef.doc(orderId).update({
      'items': updatedItems.map((e) => e.toMap()).toList(),
      'status': OrderStatus.ready.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark all items in an order as served and set order status to served
  static Future<void> markAllItemsServed(String orderId) async {
    final order = await getOrder(orderId);
    if (order == null) return;

    final updatedItems = order.items
        .map((item) => item.copyWith(status: OrderItemStatus.served))
        .toList();

    await _ordersRef.doc(orderId).update({
      'items': updatedItems.map((e) => e.toMap()).toList(),
      'status': OrderStatus.served.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Complete an order (transition to billed) and free the table
  static Future<void> completeOrder(String orderId) async {
    final order = await getOrder(orderId);
    if (order == null) return;

    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.billed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Free the table
    if (order.tableId != null) {
      await TableService.updateTableStatus(
        order.tableId!,
        TableStatus.available,
      );
    }

    debugPrint('✅ Order #${order.orderNumber} billed, table freed');
  }

  /// Cancel an order and free the table
  static Future<void> cancelOrder(String orderId) async {
    final order = await getOrder(orderId);
    if (order == null) return;

    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (order.tableId != null) {
      await TableService.updateTableStatus(
        order.tableId!,
        TableStatus.available,
      );
    }

    debugPrint('❌ Order #${order.orderNumber} cancelled');
  }

  /// Merge two orders — move items from source into target, cancel source
  static Future<OrderModel> mergeOrders({
    required String targetOrderId,
    required String sourceOrderId,
  }) async {
    final target = await getOrder(targetOrderId);
    final source = await getOrder(sourceOrderId);
    if (target == null) throw Exception('Target order not found');
    if (source == null) throw Exception('Source order not found');

    final nextKot = target.currentKotNumber + 1;
    final sourceItems =
        source.items.map((item) => item.copyWith(kotNumber: nextKot)).toList();

    final merged = target.copyWith(
      items: [...target.items, ...sourceItems],
      currentKotNumber: nextKot,
    );

    await _ordersRef.doc(targetOrderId).update(merged.toFirestore());
    await cancelOrder(sourceOrderId);

    debugPrint(
        '🔀 Merged order #${source.orderNumber} into #${target.orderNumber}');
    return merged;
  }
}
