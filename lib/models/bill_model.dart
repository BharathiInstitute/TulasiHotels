/// Bill and Cart Item models
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment method types
enum PaymentMethod {
  cash('Cash', '💵'),
  upi('UPI', '📱'),
  udhar('Credit', '📒'),
  unknown('Unknown', '❓');

  final String displayName;
  final String emoji;

  const PaymentMethod(this.displayName, this.emoji);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.unknown,
    );
  }
}

/// Split payment entry
class PaymentSplit {
  final PaymentMethod method;
  final double amount;
  final String? reference;

  const PaymentSplit({
    required this.method,
    required this.amount,
    this.reference,
  });

  Map<String, dynamic> toMap() {
    return {
      'method': method.name,
      'amount': amount,
      'reference': reference,
    };
  }

  factory PaymentSplit.fromMap(Map<String, dynamic> map) {
    return PaymentSplit(
      method: PaymentMethod.fromString((map['method'] as String?) ?? 'cash'),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      reference: map['reference'] as String?,
    );
  }
}

/// GST line item breakdown
class GstLineItem {
  final String hsnCode;
  final double taxableAmount;
  final double gstRate;
  final double cgst;
  final double sgst;

  const GstLineItem({
    required this.hsnCode,
    required this.taxableAmount,
    required this.gstRate,
    required this.cgst,
    required this.sgst,
  });

  Map<String, dynamic> toMap() {
    return {
      'hsnCode': hsnCode,
      'taxableAmount': taxableAmount,
      'gstRate': gstRate,
      'cgst': cgst,
      'sgst': sgst,
    };
  }

  factory GstLineItem.fromMap(Map<String, dynamic> map) {
    return GstLineItem(
      hsnCode: (map['hsnCode'] as String?) ?? '',
      taxableAmount: (map['taxableAmount'] as num?)?.toDouble() ?? 0,
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 0,
      cgst: (map['cgst'] as num?)?.toDouble() ?? 0,
      sgst: (map['sgst'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Cart item model (used during billing)
class CartItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String unit;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
  });

  double get total => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      unit: unit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: (map['productId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as int?) ?? 1,
      unit: (map['unit'] as String?) ?? 'pcs',
    );
  }
}

/// Bill model
class BillModel {
  final String id;
  final int billNumber;
  final List<CartItem> items;
  final double total;
  final PaymentMethod paymentMethod;
  final String? customerId;
  final String? customerName;
  final double? receivedAmount;
  final DateTime createdAt;
  final String date; // YYYY-MM-DD for querying

  // Hotel-specific fields (null for legacy/store bills)
  final String? orderId;
  final String? tableId;
  final String? tableName;
  final String? waiterId;
  final String? waiterName;
  final String? orderType; // dineIn, takeaway, delivery
  final double subtotal; // pre-discount/charge amount
  final double discount; // discount amount
  final double serviceCharge; // service charge amount

  // Split bill fields
  final String? parentBillId;
  final int? splitIndex;
  final List<PaymentSplit>? paymentSplits;

  // GST fields
  final double cgst;
  final double sgst;
  final double totalTax;
  final List<GstLineItem>? gstBreakdown;

  const BillModel({
    required this.id,
    required this.billNumber,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.customerId,
    this.customerName,
    this.receivedAmount,
    required this.createdAt,
    required this.date,
    this.orderId,
    this.tableId,
    this.tableName,
    this.waiterId,
    this.waiterName,
    this.orderType,
    this.subtotal = 0,
    this.discount = 0,
    this.serviceCharge = 0,
    this.parentBillId,
    this.splitIndex,
    this.paymentSplits,
    this.cgst = 0,
    this.sgst = 0,
    this.totalTax = 0,
    this.gstBreakdown,
  });

  /// Calculate change to return
  double? get changeAmount {
    if (receivedAmount == null) return null;
    return receivedAmount! - total;
  }

  /// Number of total items
  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  factory BillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BillModel(
      id: doc.id,
      billNumber: (data['billNumber'] as int?) ?? 0,
      items:
          (data['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.fromString(
        (data['paymentMethod'] as String?) ?? 'cash',
      ),
      customerId: data['customerId'] as String?,
      customerName: data['customerName'] as String?,
      receivedAmount: (data['receivedAmount'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: (data['date'] as String?) ?? '',
      orderId: data['orderId'] as String?,
      tableId: data['tableId'] as String?,
      tableName: data['tableName'] as String?,
      waiterId: data['waiterId'] as String?,
      waiterName: data['waiterName'] as String?,
      orderType: data['orderType'] as String?,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0,
      serviceCharge: (data['serviceCharge'] as num?)?.toDouble() ?? 0,
      parentBillId: data['parentBillId'] as String?,
      splitIndex: data['splitIndex'] as int?,
      paymentSplits: (data['paymentSplits'] as List<dynamic>?)
          ?.map((e) => PaymentSplit.fromMap(e as Map<String, dynamic>))
          .toList(),
      cgst: (data['cgst'] as num?)?.toDouble() ?? 0,
      sgst: (data['sgst'] as num?)?.toDouble() ?? 0,
      totalTax: (data['totalTax'] as num?)?.toDouble() ?? 0,
      gstBreakdown: (data['gstBreakdown'] as List<dynamic>?)
          ?.map((e) => GstLineItem.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billNumber': billNumber,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'paymentMethod': paymentMethod.name,
      'customerId': customerId,
      'customerName': customerName,
      'receivedAmount': receivedAmount,
      'createdAt': createdAt.toIso8601String(),
      'date': date,
      if (orderId != null) 'orderId': orderId,
      if (tableId != null) 'tableId': tableId,
      if (tableName != null) 'tableName': tableName,
      if (waiterId != null) 'waiterId': waiterId,
      if (waiterName != null) 'waiterName': waiterName,
      if (orderType != null) 'orderType': orderType,
      if (subtotal > 0) 'subtotal': subtotal,
      if (discount > 0) 'discount': discount,
      if (serviceCharge > 0) 'serviceCharge': serviceCharge,
      if (parentBillId != null) 'parentBillId': parentBillId,
      if (splitIndex != null) 'splitIndex': splitIndex,
      if (paymentSplits != null)
        'paymentSplits': paymentSplits!.map((e) => e.toMap()).toList(),
      if (cgst > 0) 'cgst': cgst,
      if (sgst > 0) 'sgst': sgst,
      if (totalTax > 0) 'totalTax': totalTax,
      if (gstBreakdown != null)
        'gstBreakdown': gstBreakdown!.map((e) => e.toMap()).toList(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'billNumber': billNumber,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'paymentMethod': paymentMethod.name,
      'customerId': customerId,
      'customerName': customerName,
      'receivedAmount': receivedAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'date': date,
      if (orderId != null) 'orderId': orderId,
      if (tableId != null) 'tableId': tableId,
      if (tableName != null) 'tableName': tableName,
      if (waiterId != null) 'waiterId': waiterId,
      if (waiterName != null) 'waiterName': waiterName,
      if (orderType != null) 'orderType': orderType,
      if (subtotal > 0) 'subtotal': subtotal,
      if (discount > 0) 'discount': discount,
      if (serviceCharge > 0) 'serviceCharge': serviceCharge,
      if (parentBillId != null) 'parentBillId': parentBillId,
      if (splitIndex != null) 'splitIndex': splitIndex,
      if (paymentSplits != null)
        'paymentSplits': paymentSplits!.map((e) => e.toMap()).toList(),
      if (cgst > 0) 'cgst': cgst,
      if (sgst > 0) 'sgst': sgst,
      if (totalTax > 0) 'totalTax': totalTax,
      if (gstBreakdown != null)
        'gstBreakdown': gstBreakdown!.map((e) => e.toMap()).toList(),
    };
  }

  BillModel copyWith({
    String? id,
    int? billNumber,
    List<CartItem>? items,
    double? total,
    PaymentMethod? paymentMethod,
    String? customerId,
    String? customerName,
    double? receivedAmount,
    DateTime? createdAt,
    String? date,
    String? orderId,
    String? tableId,
    String? tableName,
    String? waiterId,
    String? waiterName,
    String? orderType,
    double? subtotal,
    double? discount,
    double? serviceCharge,
    String? parentBillId,
    int? splitIndex,
    List<PaymentSplit>? paymentSplits,
    double? cgst,
    double? sgst,
    double? totalTax,
    List<GstLineItem>? gstBreakdown,
  }) {
    return BillModel(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      items: items ?? this.items,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      createdAt: createdAt ?? this.createdAt,
      date: date ?? this.date,
      orderId: orderId ?? this.orderId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      orderType: orderType ?? this.orderType,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      parentBillId: parentBillId ?? this.parentBillId,
      splitIndex: splitIndex ?? this.splitIndex,
      paymentSplits: paymentSplits ?? this.paymentSplits,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      totalTax: totalTax ?? this.totalTax,
      gstBreakdown: gstBreakdown ?? this.gstBreakdown,
    );
  }
}
