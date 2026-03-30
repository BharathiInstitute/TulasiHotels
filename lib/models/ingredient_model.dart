/// Ingredient model for inventory management
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Ingredient measurement units
enum IngredientUnit {
  kg('Kilogram', 'kg'),
  g('Gram', 'g'),
  liter('Liter', 'L'),
  ml('Milliliter', 'ml'),
  pieces('Pieces', 'pcs'),
  dozen('Dozen', 'dz'),
  packet('Packet', 'pkt');

  final String displayName;
  final String shortName;

  const IngredientUnit(this.displayName, this.shortName);

  static IngredientUnit fromString(String value) {
    return IngredientUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IngredientUnit.kg,
    );
  }
}

class IngredientModel {
  final String id;
  final String name;
  final IngredientUnit unit;
  final double currentStock;
  final double minLevel;
  final double? maxLevel;
  final double costPerUnit;
  final String? vendorId;
  final String? vendorName;
  final DateTime? expiryDate;
  final String? batchNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const IngredientModel({
    required this.id,
    required this.name,
    this.unit = IngredientUnit.kg,
    this.currentStock = 0,
    this.minLevel = 0,
    this.maxLevel,
    this.costPerUnit = 0,
    this.vendorId,
    this.vendorName,
    this.expiryDate,
    this.batchNumber,
    required this.createdAt,
    this.updatedAt,
  });

  /// Whether stock is below minimum level
  bool get isLowStock => currentStock <= minLevel;

  /// Whether this ingredient is expiring within the given days
  bool isExpiringSoon(int daysAhead) {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(
      DateTime.now().add(Duration(days: daysAhead)),
    );
  }

  factory IngredientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IngredientModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      unit: IngredientUnit.fromString((data['unit'] as String?) ?? 'kg'),
      currentStock: (data['currentStock'] as num?)?.toDouble() ?? 0,
      minLevel: (data['minLevel'] as num?)?.toDouble() ?? 0,
      maxLevel: (data['maxLevel'] as num?)?.toDouble(),
      costPerUnit: (data['costPerUnit'] as num?)?.toDouble() ?? 0,
      vendorId: data['vendorId'] as String?,
      vendorName: data['vendorName'] as String?,
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      batchNumber: data['batchNumber'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'unit': unit.name,
      'currentStock': currentStock,
      'minLevel': minLevel,
      'maxLevel': maxLevel,
      'costPerUnit': costPerUnit,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'expiryDate':
          expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'batchNumber': batchNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  IngredientModel copyWith({
    String? name,
    IngredientUnit? unit,
    double? currentStock,
    double? minLevel,
    double? maxLevel,
    double? costPerUnit,
    String? vendorId,
    String? vendorName,
    DateTime? expiryDate,
    String? batchNumber,
  }) {
    return IngredientModel(
      id: id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minLevel: minLevel ?? this.minLevel,
      maxLevel: maxLevel ?? this.maxLevel,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
