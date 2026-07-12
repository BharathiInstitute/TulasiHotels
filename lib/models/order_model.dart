/// Order and OrderItem models for hotel order lifecycle
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/bill_model.dart';

/// Order status lifecycle: placed ? preparing ? ready ? served ? billed ? cancelled
enum OrderStatus {
  placed('Placed', '??'),
  preparing('Preparing', '??'),
  ready('Ready', '?'),
  served('Served', '???'),
  billed('Billed', '??'),
  cancelled('Cancelled', '?');

  final String displayName;
  final String emoji;

  const OrderStatus(this.displayName, this.emoji);

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.placed,
    );
  }
}

/// Per-item status within an order
enum OrderItemStatus {
  pending('Pending'),
  preparing('Preparing'),
  ready('Ready'),
  served('Served');

  final String displayName;

  const OrderItemStatus(this.displayName);

  static OrderItemStatus fromString(String value) {
    return OrderItemStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderItemStatus.pending,
    );
  }
}

/// Order type
enum OrderType {
  dineIn('Dine-in', '\u{1F374}'),
  takeaway('Takeaway', '\u{1F4E6}'),
  delivery('Delivery', '\u{1F6F5}');

  final String displayName;
  final String emoji;

  const OrderType(this.displayName, this.emoji);

  static OrderType fromString(String value) {
    return OrderType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderType.dineIn,
    );
  }
}

/// Individual item within an order (extends CartItem concept)
class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String unit;
  final String? itemNotes;
  final OrderItemStatus status;
  final int kotNumber;
  final DateTime? preparationStartedAt;
  final String? kitchenStation;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
    this.itemNotes,
    this.status = OrderItemStatus.pending,
    this.kotNumber = 1,
    this.preparationStartedAt,
    this.kitchenStation,
  });

  double get total => price * quantity;

  /// Convert to CartItem for billing
  CartItem toCartItem() => CartItem(
    productId: productId,
    name: name,
    price: price,
    quantity: quantity,
    unit: unit,
  );

  OrderItem copyWith({
    int? quantity,
    String? itemNotes,
    OrderItemStatus? status,
    int? kotNumber,
    DateTime? preparationStartedAt,
    String? kitchenStation,
  }) {
    return OrderItem(
      productId: productId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      unit: unit,
      itemNotes: itemNotes ?? this.itemNotes,
      status: status ?? this.status,
      kotNumber: kotNumber ?? this.kotNumber,
      preparationStartedAt: preparationStartedAt ?? this.preparationStartedAt,
      kitchenStation: kitchenStation ?? this.kitchenStation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'itemNotes': itemNotes,
      'status': status.name,
      'kotNumber': kotNumber,
      'preparationStartedAt': preparationStartedAt?.millisecondsSinceEpoch,
      'kitchenStation': kitchenStation,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: (map['productId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as int?) ?? 1,
      unit: (map['unit'] as String?) ?? 'pcs',
      itemNotes: map['itemNotes'] as String?,
      status: OrderItemStatus.fromString(
        (map['status'] as String?) ?? 'pending',
      ),
      kotNumber: (map['kotNumber'] as int?) ?? 1,
      preparationStartedAt: map['preparationStartedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['preparationStartedAt'] as int)
          : null,
      kitchenStation: map['kitchenStation'] as String?,
    );
  }
}

/// Order model — the core hotel workflow entity
class OrderModel {
  final String id;
  final int orderNumber;
  final String? tableId;
  final String? tableName;
  final List<OrderItem> items;
  final OrderStatus status;
  final OrderType orderType;
  final String? waiterId;
  final String? waiterName;
  final String? notes;
  final int currentKotNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Phase 1 & 4 enhancements
  final bool isRush;
  final String? customerName;
  final String? customerPhone;
  final bool isCustomerOrder;
  final bool isVip;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    this.tableId,
    this.tableName,
    required this.items,
    this.status = OrderStatus.placed,
    this.orderType = OrderType.dineIn,
    this.waiterId,
    this.waiterName,
    this.notes,
    this.currentKotNumber = 1,
    required this.createdAt,
    required this.updatedAt,
    this.isRush = false,
    this.customerName,
    this.customerPhone,
    this.isCustomerOrder = false,
    this.isVip = false,
  });

  /// Total order amount
  double get total => items.fold(0.0, (acc, item) => acc + item.total);

  /// Total number of items (sum of quantities)
  int get itemCount => items.fold(0, (acc, item) => acc + item.quantity);

  /// Whether this order is still active (not billed or cancelled)
  bool get isActive =>
      status != OrderStatus.billed && status != OrderStatus.cancelled;

  /// Whether all items are served
  bool get allItemsServed =>
      items.isNotEmpty &&
      items.every((item) => item.status == OrderItemStatus.served);

  /// Whether all items are ready or served
  bool get allItemsReady =>
      items.isNotEmpty &&
      items.every(
        (item) =>
            item.status == OrderItemStatus.ready ||
            item.status == OrderItemStatus.served,
      );

  /// Time elapsed since order was placed
  Duration get elapsed => DateTime.now().difference(createdAt);

  /// Items that are still being prepared (for kitchen)
  List<OrderItem> get pendingItems =>
      items.where((i) => i.status == OrderItemStatus.pending).toList();

  /// Items currently being prepared
  List<OrderItem> get preparingItems =>
      items.where((i) => i.status == OrderItemStatus.preparing).toList();

  /// Items ready to serve
  List<OrderItem> get readyItems =>
      items.where((i) => i.status == OrderItemStatus.ready).toList();

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      orderNumber: (data['orderNumber'] as int?) ?? 0,
      tableId: data['tableId'] as String?,
      tableName: data['tableName'] as String?,
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: OrderStatus.fromString(
        (data['status'] as String?) ?? 'placed',
      ),
      orderType: OrderType.fromString(
        (data['orderType'] as String?) ?? 'dineIn',
      ),
      waiterId: data['waiterId'] as String?,
      waiterName: data['waiterName'] as String?,
      notes: data['notes'] as String?,
      currentKotNumber: (data['currentKotNumber'] as int?) ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRush: (data['isRush'] as bool?) ?? false,
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      isCustomerOrder: (data['isCustomerOrder'] as bool?) ?? false,
      isVip: (data['isVip'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'tableId': tableId,
      'tableName': tableName,
      'items': items.map((e) => e.toMap()).toList(),
      'status': status.name,
      'orderType': orderType.name,
      'waiterId': waiterId,
      'waiterName': waiterName,
      'notes': notes,
      'currentKotNumber': currentKotNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isRush': isRush,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'isCustomerOrder': isCustomerOrder,
      'isVip': isVip,
    };
  }

  OrderModel copyWith({
    List<OrderItem>? items,
    OrderStatus? status,
    OrderType? orderType,
    String? waiterId,
    String? waiterName,
    String? notes,
    int? currentKotNumber,
    String? tableId,
    String? tableName,
    bool? isRush,
    String? customerName,
    String? customerPhone,
    bool? isCustomerOrder,
    bool? isVip,
  }) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      items: items ?? this.items,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      notes: notes ?? this.notes,
      currentKotNumber: currentKotNumber ?? this.currentKotNumber,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isRush: isRush ?? this.isRush,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      isCustomerOrder: isCustomerOrder ?? this.isCustomerOrder,
      isVip: isVip ?? this.isVip,
    );
  }
}
