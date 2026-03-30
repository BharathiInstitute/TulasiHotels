/// Wastage tracking model for inventory loss
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/ingredient_model.dart';

/// Reasons for wastage
enum WastageReason {
  expired('Expired', '📅'),
  spoiled('Spoiled', '🤢'),
  kitchenError('Kitchen Error', '👨‍🍳'),
  overProduction('Over Production', '📈'),
  other('Other', '📝');

  final String displayName;
  final String emoji;

  const WastageReason(this.displayName, this.emoji);

  static WastageReason fromString(String value) {
    return WastageReason.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WastageReason.other,
    );
  }
}

class WastageModel {
  final String id;
  final String ingredientId;
  final String ingredientName;
  final double quantity;
  final IngredientUnit unit;
  final WastageReason reason;
  final String? notes;
  final double estimatedCost;
  final DateTime date;
  final String? loggedBy;
  final DateTime createdAt;

  const WastageModel({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    this.unit = IngredientUnit.kg,
    this.reason = WastageReason.other,
    this.notes,
    this.estimatedCost = 0,
    required this.date,
    this.loggedBy,
    required this.createdAt,
  });

  factory WastageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WastageModel(
      id: doc.id,
      ingredientId: (data['ingredientId'] as String?) ?? '',
      ingredientName: (data['ingredientName'] as String?) ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0,
      unit: IngredientUnit.fromString((data['unit'] as String?) ?? 'kg'),
      reason: WastageReason.fromString(
        (data['reason'] as String?) ?? 'other',
      ),
      notes: data['notes'] as String?,
      estimatedCost: (data['estimatedCost'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      loggedBy: data['loggedBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ingredientId': ingredientId,
      'ingredientName': ingredientName,
      'quantity': quantity,
      'unit': unit.name,
      'reason': reason.name,
      'notes': notes,
      'estimatedCost': estimatedCost,
      'date': Timestamp.fromDate(date),
      'loggedBy': loggedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  WastageModel copyWith({
    String? ingredientId,
    String? ingredientName,
    double? quantity,
    IngredientUnit? unit,
    WastageReason? reason,
    String? notes,
    double? estimatedCost,
    DateTime? date,
    String? loggedBy,
  }) {
    return WastageModel(
      id: id,
      ingredientId: ingredientId ?? this.ingredientId,
      ingredientName: ingredientName ?? this.ingredientName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      date: date ?? this.date,
      loggedBy: loggedBy ?? this.loggedBy,
      createdAt: createdAt,
    );
  }
}
