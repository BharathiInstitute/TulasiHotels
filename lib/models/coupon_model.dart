/// Coupon and discount model
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Coupon type: percentage off or flat amount off
enum CouponType {
  percentage('Percentage', '%'),
  flat('Flat', '₹');

  final String displayName;
  final String symbol;

  const CouponType(this.displayName, this.symbol);

  static CouponType fromString(String value) {
    return CouponType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CouponType.percentage,
    );
  }
}

class CouponModel {
  final String id;
  final String code;
  final CouponType type;
  final double value;
  final double? minOrderAmount;
  final double? maxDiscount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? maxUses;
  final int usedCount;
  final bool isActive;
  final bool isHappyHour;
  final int? happyHourStart;
  final int? happyHourEnd;
  final DateTime createdAt;

  const CouponModel({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.maxDiscount,
    this.validFrom,
    this.validUntil,
    this.maxUses,
    this.usedCount = 0,
    this.isActive = true,
    this.isHappyHour = false,
    this.happyHourStart,
    this.happyHourEnd,
    required this.createdAt,
  });

  /// Check if this coupon is currently valid
  bool get isValid {
    if (!isActive) return false;
    if (maxUses != null && usedCount >= maxUses!) return false;
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    return true;
  }

  /// Check if happy hour is active right now
  bool get isHappyHourActive {
    if (!isHappyHour || happyHourStart == null || happyHourEnd == null) {
      return false;
    }
    final hour = DateTime.now().hour;
    return hour >= happyHourStart! && hour < happyHourEnd!;
  }

  /// Calculate discount for a given order amount
  double calculateDiscount(double orderAmount) {
    if (minOrderAmount != null && orderAmount < minOrderAmount!) return 0;
    double discount;
    if (type == CouponType.percentage) {
      discount = orderAmount * value / 100;
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      discount = value;
    }
    return discount.clamp(0, orderAmount);
  }

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      code: (data['code'] as String?) ?? '',
      type: CouponType.fromString((data['type'] as String?) ?? 'percentage'),
      value: (data['value'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (data['minOrderAmount'] as num?)?.toDouble(),
      maxDiscount: (data['maxDiscount'] as num?)?.toDouble(),
      validFrom: (data['validFrom'] as Timestamp?)?.toDate(),
      validUntil: (data['validUntil'] as Timestamp?)?.toDate(),
      maxUses: data['maxUses'] as int?,
      usedCount: (data['usedCount'] as int?) ?? 0,
      isActive: (data['isActive'] as bool?) ?? true,
      isHappyHour: (data['isHappyHour'] as bool?) ?? false,
      happyHourStart: data['happyHourStart'] as int?,
      happyHourEnd: data['happyHourEnd'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'type': type.name,
      'value': value,
      'minOrderAmount': minOrderAmount,
      'maxDiscount': maxDiscount,
      'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
      'validUntil':
          validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'maxUses': maxUses,
      'usedCount': usedCount,
      'isActive': isActive,
      'isHappyHour': isHappyHour,
      'happyHourStart': happyHourStart,
      'happyHourEnd': happyHourEnd,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CouponModel copyWith({
    String? code,
    CouponType? type,
    double? value,
    double? minOrderAmount,
    double? maxDiscount,
    DateTime? validFrom,
    DateTime? validUntil,
    int? maxUses,
    int? usedCount,
    bool? isActive,
    bool? isHappyHour,
    int? happyHourStart,
    int? happyHourEnd,
  }) {
    return CouponModel(
      id: id,
      code: code ?? this.code,
      type: type ?? this.type,
      value: value ?? this.value,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      isHappyHour: isHappyHour ?? this.isHappyHour,
      happyHourStart: happyHourStart ?? this.happyHourStart,
      happyHourEnd: happyHourEnd ?? this.happyHourEnd,
      createdAt: createdAt,
    );
  }
}
