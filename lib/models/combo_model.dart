/// Combo/thali bundle model for menu item groups
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/models/product_model.dart';

/// Individual item within a combo
class ComboItem {
  final String productId;
  final String name;
  final int quantity;
  final bool isSwappable;
  final List<String>? swapOptions;

  const ComboItem({
    required this.productId,
    required this.name,
    this.quantity = 1,
    this.isSwappable = false,
    this.swapOptions,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'isSwappable': isSwappable,
      'swapOptions': swapOptions,
    };
  }

  factory ComboItem.fromMap(Map<String, dynamic> map) {
    return ComboItem(
      productId: (map['productId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      quantity: (map['quantity'] as int?) ?? 1,
      isSwappable: (map['isSwappable'] as bool?) ?? false,
      swapOptions: (map['swapOptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

/// Combo model — bundled menu items at a set price
class ComboModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final List<ComboItem> items;
  final bool isAvailable;
  final DietaryTag dietaryTag;
  final DateTime createdAt;

  const ComboModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.items,
    this.isAvailable = true,
    this.dietaryTag = DietaryTag.none,
    required this.createdAt,
  });

  factory ComboModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComboModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => ComboItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isAvailable: (data['isAvailable'] as bool?) ?? true,
      dietaryTag: DietaryTag.fromString(
        (data['dietaryTag'] as String?) ?? 'none',
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'items': items.map((e) => e.toMap()).toList(),
      'isAvailable': isAvailable,
      'dietaryTag': dietaryTag.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ComboModel copyWith({
    String? name,
    String? description,
    double? price,
    List<ComboItem>? items,
    bool? isAvailable,
    DietaryTag? dietaryTag,
  }) {
    return ComboModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      items: items ?? this.items,
      isAvailable: isAvailable ?? this.isAvailable,
      dietaryTag: dietaryTag ?? this.dietaryTag,
      createdAt: createdAt,
    );
  }
}
