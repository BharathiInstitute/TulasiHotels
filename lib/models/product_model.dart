/// Product model for Tulasi Hotels app
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Sentinel value for distinguishing "not provided" from "set to null" in copyWith
const _sentinel = Object();

/// Dietary classification for menu items
enum DietaryTag {
  veg('Veg', '🟢'),
  nonVeg('Non-Veg', '🔴'),
  egg('Egg', '🟡'),
  jain('Jain', '🟢'),
  none('None', '');

  final String displayName;
  final String emoji;

  const DietaryTag(this.displayName, this.emoji);

  static DietaryTag fromString(String value) {
    return DietaryTag.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DietaryTag.none,
    );
  }
}

/// Spice level for menu items
enum SpiceLevel {
  mild('Mild', '🌶️'),
  medium('Medium', '🌶️🌶️'),
  hot('Hot', '🌶️🌶️🌶️'),
  extraHot('Extra Hot', '🔥'),
  na('N/A', '');

  final String displayName;
  final String emoji;

  const SpiceLevel(this.displayName, this.emoji);

  static SpiceLevel fromString(String value) {
    return SpiceLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SpiceLevel.na,
    );
  }
}

/// Product unit types
enum ProductUnit {
  piece('Piece', 'pcs'),
  kg('Kilogram', 'kg'),
  gram('Gram', 'g'),
  liter('Liter', 'L'),
  ml('Milliliter', 'ml'),
  pack('Pack', 'pack'),
  box('Box', 'box'),
  dozen('Dozen', 'dz'),
  unknown('Unknown', '?');

  final String displayName;
  final String shortName;

  const ProductUnit(this.displayName, this.shortName);

  static ProductUnit fromString(String value) {
    return ProductUnit.values.firstWhere(
      (e) => e.name == value || e.shortName == value,
      orElse: () => ProductUnit.unknown,
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final double price;
  final double? purchasePrice;
  final int stock;
  final int? lowStockAlert;
  final String? barcode;
  final String? imageUrl;
  final String? category;
  final ProductUnit unit;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Menu enhancement fields
  final String? descriptionEn;
  final String? descriptionHi;
  final String? descriptionTe;
  final bool isAvailable;
  final bool isSpecial;
  final List<int>? availableDays; // [1=Mon..7=Sun], null=every day
  final DietaryTag dietaryTag;
  final SpiceLevel spiceLevel;
  final List<String> allergens;
  final double? priceTakeaway;
  final double? priceDelivery;
  final String? kitchenStation;
  final String? comboId;

  // GST / compliance fields
  final String? hsnCode;
  final double? gstRate;
  final double? discount;

  // Seasonal fields
  final DateTime? seasonStart;
  final DateTime? seasonEnd;
  final String? seasonTag;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.purchasePrice,
    required this.stock,
    this.lowStockAlert,
    this.barcode,
    this.imageUrl,
    this.category,
    this.unit = ProductUnit.piece,
    required this.createdAt,
    this.updatedAt,
    this.descriptionEn,
    this.descriptionHi,
    this.descriptionTe,
    this.isAvailable = true,
    this.isSpecial = false,
    this.availableDays,
    this.dietaryTag = DietaryTag.none,
    this.spiceLevel = SpiceLevel.na,
    this.allergens = const [],
    this.priceTakeaway,
    this.priceDelivery,
    this.kitchenStation,
    this.comboId,
    this.hsnCode,
    this.gstRate,
    this.discount,
    this.seasonStart,
    this.seasonEnd,
    this.seasonTag,
  });

  /// Check if stock is low
  bool get isLowStock => lowStockAlert != null && stock <= lowStockAlert!;

  /// Check if out of stock
  bool get isOutOfStock => stock <= 0;

  /// Calculate profit per unit
  double? get profit => purchasePrice != null ? price - purchasePrice! : null;

  /// Calculate profit percentage
  double? get profitPercentage => purchasePrice != null && purchasePrice! > 0
      ? ((price - purchasePrice!) / purchasePrice!) * 100
      : null;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble(),
      stock: (data['stock'] as int?) ?? 0,
      lowStockAlert: data['lowStockAlert'] as int?,
      barcode: data['barcode'] as String?,
      imageUrl: data['imageUrl'] as String?,
      category: data['category'] as String?,
      unit: ProductUnit.fromString((data['unit'] as String?) ?? 'piece'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      descriptionEn: data['descriptionEn'] as String?,
      descriptionHi: data['descriptionHi'] as String?,
      descriptionTe: data['descriptionTe'] as String?,
      isAvailable: (data['isAvailable'] as bool?) ?? true,
      isSpecial: (data['isSpecial'] as bool?) ?? false,
      availableDays: (data['availableDays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      dietaryTag: DietaryTag.fromString(
        (data['dietaryTag'] as String?) ?? 'none',
      ),
      spiceLevel: SpiceLevel.fromString(
        (data['spiceLevel'] as String?) ?? 'na',
      ),
      allergens: (data['allergens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      priceTakeaway: (data['priceTakeaway'] as num?)?.toDouble(),
      priceDelivery: (data['priceDelivery'] as num?)?.toDouble(),
      kitchenStation: data['kitchenStation'] as String?,
      comboId: data['comboId'] as String?,
      hsnCode: data['hsnCode'] as String?,
      gstRate: (data['gstRate'] as num?)?.toDouble(),
      discount: (data['discount'] as num?)?.toDouble(),
      seasonStart: (data['seasonStart'] as Timestamp?)?.toDate(),
      seasonEnd: (data['seasonEnd'] as Timestamp?)?.toDate(),
      seasonTag: data['seasonTag'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'purchasePrice': purchasePrice,
      'stock': stock,
      'lowStockAlert': lowStockAlert,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'category': category,
      'unit': unit.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'descriptionEn': descriptionEn,
      'descriptionHi': descriptionHi,
      'descriptionTe': descriptionTe,
      'isAvailable': isAvailable,
      'isSpecial': isSpecial,
      'availableDays': availableDays,
      'dietaryTag': dietaryTag.name,
      'spiceLevel': spiceLevel.name,
      'allergens': allergens,
      'priceTakeaway': priceTakeaway,
      'priceDelivery': priceDelivery,
      'kitchenStation': kitchenStation,
      'comboId': comboId,
      'hsnCode': hsnCode,
      'gstRate': gstRate,
      'discount': discount,
      'seasonStart': seasonStart != null ? Timestamp.fromDate(seasonStart!) : null,
      'seasonEnd': seasonEnd != null ? Timestamp.fromDate(seasonEnd!) : null,
      'seasonTag': seasonTag,
    };
  }

  ProductModel copyWith({
    String? name,
    double? price,
    Object? purchasePrice = _sentinel,
    int? stock,
    Object? lowStockAlert = _sentinel,
    Object? barcode = _sentinel,
    Object? imageUrl = _sentinel,
    Object? category = _sentinel,
    ProductUnit? unit,
    Object? descriptionEn = _sentinel,
    Object? descriptionHi = _sentinel,
    Object? descriptionTe = _sentinel,
    bool? isAvailable,
    bool? isSpecial,
    Object? availableDays = _sentinel,
    DietaryTag? dietaryTag,
    SpiceLevel? spiceLevel,
    List<String>? allergens,
    Object? priceTakeaway = _sentinel,
    Object? priceDelivery = _sentinel,
    Object? kitchenStation = _sentinel,
    Object? comboId = _sentinel,
    Object? hsnCode = _sentinel,
    Object? gstRate = _sentinel,
    Object? discount = _sentinel,
    Object? seasonStart = _sentinel,
    Object? seasonEnd = _sentinel,
    Object? seasonTag = _sentinel,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      purchasePrice: purchasePrice == _sentinel
          ? this.purchasePrice
          : purchasePrice as double?,
      stock: stock ?? this.stock,
      lowStockAlert: lowStockAlert == _sentinel
          ? this.lowStockAlert
          : lowStockAlert as int?,
      barcode: barcode == _sentinel ? this.barcode : barcode as String?,
      imageUrl: imageUrl == _sentinel ? this.imageUrl : imageUrl as String?,
      category: category == _sentinel ? this.category : category as String?,
      unit: unit ?? this.unit,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      descriptionEn: descriptionEn == _sentinel
          ? this.descriptionEn
          : descriptionEn as String?,
      descriptionHi: descriptionHi == _sentinel
          ? this.descriptionHi
          : descriptionHi as String?,
      descriptionTe: descriptionTe == _sentinel
          ? this.descriptionTe
          : descriptionTe as String?,
      isAvailable: isAvailable ?? this.isAvailable,
      isSpecial: isSpecial ?? this.isSpecial,
      availableDays: availableDays == _sentinel
          ? this.availableDays
          : availableDays as List<int>?,
      dietaryTag: dietaryTag ?? this.dietaryTag,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      allergens: allergens ?? this.allergens,
      priceTakeaway: priceTakeaway == _sentinel
          ? this.priceTakeaway
          : priceTakeaway as double?,
      priceDelivery: priceDelivery == _sentinel
          ? this.priceDelivery
          : priceDelivery as double?,
      kitchenStation: kitchenStation == _sentinel
          ? this.kitchenStation
          : kitchenStation as String?,
      comboId:
          comboId == _sentinel ? this.comboId : comboId as String?,
      hsnCode:
          hsnCode == _sentinel ? this.hsnCode : hsnCode as String?,
      gstRate:
          gstRate == _sentinel ? this.gstRate : gstRate as double?,
      discount:
          discount == _sentinel ? this.discount : discount as double?,
      seasonStart: seasonStart == _sentinel
          ? this.seasonStart
          : seasonStart as DateTime?,
      seasonEnd: seasonEnd == _sentinel
          ? this.seasonEnd
          : seasonEnd as DateTime?,
      seasonTag:
          seasonTag == _sentinel ? this.seasonTag : seasonTag as String?,
    );
  }
}
