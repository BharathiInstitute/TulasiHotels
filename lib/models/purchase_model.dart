/// Purchase entry model for inventory procurement
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/bill_model.dart';

/// Individual item in a purchase order
class PurchaseItem {
  final String ingredientId;
  final String ingredientName;
  final double quantity;
  final double unitCost;
  final String? batchNumber;
  final DateTime? expiryDate;

  const PurchaseItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unitCost,
    this.batchNumber,
    this.expiryDate,
  });

  double get total => quantity * unitCost;

  Map<String, dynamic> toMap() {
    return {
      'ingredientId': ingredientId,
      'ingredientName': ingredientName,
      'quantity': quantity,
      'unitCost': unitCost,
      'batchNumber': batchNumber,
      'expiryDate':
          expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      ingredientId: (map['ingredientId'] as String?) ?? '',
      ingredientName: (map['ingredientName'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0,
      batchNumber: map['batchNumber'] as String?,
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
    );
  }
}

class PurchaseModel {
  final String id;
  final String? vendorId;
  final String? vendorName;
  final List<PurchaseItem> items;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final String? invoiceNumber;
  final DateTime purchaseDate;
  final DateTime createdAt;

  const PurchaseModel({
    required this.id,
    this.vendorId,
    this.vendorName,
    required this.items,
    required this.totalAmount,
    this.paymentMethod = PaymentMethod.cash,
    this.invoiceNumber,
    required this.purchaseDate,
    required this.createdAt,
  });

  factory PurchaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseModel(
      id: doc.id,
      vendorId: data['vendorId'] as String?,
      vendorName: data['vendorName'] as String?,
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => PurchaseItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: PaymentMethod.fromString(
        (data['paymentMethod'] as String?) ?? 'cash',
      ),
      invoiceNumber: data['invoiceNumber'] as String?,
      purchaseDate:
          (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod.name,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PurchaseModel copyWith({
    String? vendorId,
    String? vendorName,
    List<PurchaseItem>? items,
    double? totalAmount,
    PaymentMethod? paymentMethod,
    String? invoiceNumber,
    DateTime? purchaseDate,
  }) {
    return PurchaseModel(
      id: id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdAt: createdAt,
    );
  }
}
