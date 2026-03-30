/// Customer complaint handling model
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Complaint lifecycle status
enum ComplaintStatus {
  open('Open', '🔴'),
  investigating('Investigating', '🔍'),
  resolved('Resolved', '✅'),
  closed('Closed', '📁');

  final String displayName;
  final String emoji;

  const ComplaintStatus(this.displayName, this.emoji);

  static ComplaintStatus fromString(String value) {
    return ComplaintStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComplaintStatus.open,
    );
  }
}

/// Complaint categories
enum ComplaintCategory {
  food('Food', '🍽️'),
  service('Service', '🛎️'),
  hygiene('Hygiene', '🧹'),
  billing('Billing', '💰'),
  other('Other', '📝');

  final String displayName;
  final String emoji;

  const ComplaintCategory(this.displayName, this.emoji);

  static ComplaintCategory fromString(String value) {
    return ComplaintCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComplaintCategory.other,
    );
  }
}

class ComplaintModel {
  final String id;
  final String? orderId;
  final String? customerName;
  final String? customerPhone;
  final ComplaintCategory category;
  final String description;
  final ComplaintStatus status;
  final String? resolution;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const ComplaintModel({
    required this.id,
    this.orderId,
    this.customerName,
    this.customerPhone,
    this.category = ComplaintCategory.other,
    required this.description,
    this.status = ComplaintStatus.open,
    this.resolution,
    this.assignedTo,
    required this.createdAt,
    this.resolvedAt,
  });

  /// Time to resolution
  Duration? get resolutionTime =>
      resolvedAt?.difference(createdAt);

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplaintModel(
      id: doc.id,
      orderId: data['orderId'] as String?,
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      category: ComplaintCategory.fromString(
        (data['category'] as String?) ?? 'other',
      ),
      description: (data['description'] as String?) ?? '',
      status: ComplaintStatus.fromString(
        (data['status'] as String?) ?? 'open',
      ),
      resolution: data['resolution'] as String?,
      assignedTo: data['assignedTo'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'category': category.name,
      'description': description,
      'status': status.name,
      'resolution': resolution,
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  ComplaintModel copyWith({
    String? orderId,
    String? customerName,
    String? customerPhone,
    ComplaintCategory? category,
    String? description,
    ComplaintStatus? status,
    String? resolution,
    String? assignedTo,
    DateTime? resolvedAt,
  }) {
    return ComplaintModel(
      id: id,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
