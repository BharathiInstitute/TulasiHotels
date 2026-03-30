/// Customer feedback model
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String? orderId;
  final String? billId;
  final String? customerName;
  final String? customerPhone;
  final int foodRating;
  final int serviceRating;
  final int ambianceRating;
  final String? comments;
  final DateTime createdAt;

  const FeedbackModel({
    required this.id,
    this.orderId,
    this.billId,
    this.customerName,
    this.customerPhone,
    this.foodRating = 0,
    this.serviceRating = 0,
    this.ambianceRating = 0,
    this.comments,
    required this.createdAt,
  });

  /// Average rating across all categories
  double get averageRating => (foodRating + serviceRating + ambianceRating) / 3;

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      orderId: data['orderId'] as String?,
      billId: data['billId'] as String?,
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      foodRating: (data['foodRating'] as int?) ?? 0,
      serviceRating: (data['serviceRating'] as int?) ?? 0,
      ambianceRating: (data['ambianceRating'] as int?) ?? 0,
      comments: data['comments'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'billId': billId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'foodRating': foodRating,
      'serviceRating': serviceRating,
      'ambianceRating': ambianceRating,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FeedbackModel copyWith({
    String? orderId,
    String? billId,
    String? customerName,
    String? customerPhone,
    int? foodRating,
    int? serviceRating,
    int? ambianceRating,
    String? comments,
  }) {
    return FeedbackModel(
      id: id,
      orderId: orderId ?? this.orderId,
      billId: billId ?? this.billId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      foodRating: foodRating ?? this.foodRating,
      serviceRating: serviceRating ?? this.serviceRating,
      ambianceRating: ambianceRating ?? this.ambianceRating,
      comments: comments ?? this.comments,
      createdAt: createdAt,
    );
  }
}
