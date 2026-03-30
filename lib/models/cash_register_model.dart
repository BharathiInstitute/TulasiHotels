/// Cash register model for shift opening/closing
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Individual cash movement entry
class CashMovement {
  final double amount;
  final String reason;
  final bool isInflow;
  final DateTime timestamp;

  const CashMovement({
    required this.amount,
    required this.reason,
    required this.isInflow,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'reason': reason,
      'isInflow': isInflow,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory CashMovement.fromMap(Map<String, dynamic> map) {
    return CashMovement(
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      reason: (map['reason'] as String?) ?? '',
      isInflow: (map['isInflow'] as bool?) ?? true,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CashRegisterModel {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingBalance;
  final double closingBalance;
  final double expectedBalance;
  final double variance;
  final List<CashMovement> movements;

  const CashRegisterModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.openedAt,
    this.closedAt,
    required this.openingBalance,
    this.closingBalance = 0,
    this.expectedBalance = 0,
    this.variance = 0,
    this.movements = const [],
  });

  /// Whether this register session is still open
  bool get isOpen => closedAt == null;

  factory CashRegisterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CashRegisterModel(
      id: doc.id,
      staffId: (data['staffId'] as String?) ?? '',
      staffName: (data['staffName'] as String?) ?? '',
      openedAt: (data['openedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      openingBalance: (data['openingBalance'] as num?)?.toDouble() ?? 0,
      closingBalance: (data['closingBalance'] as num?)?.toDouble() ?? 0,
      expectedBalance: (data['expectedBalance'] as num?)?.toDouble() ?? 0,
      variance: (data['variance'] as num?)?.toDouble() ?? 0,
      movements: (data['movements'] as List<dynamic>?)
              ?.map((e) => CashMovement.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'staffId': staffId,
      'staffName': staffName,
      'openedAt': Timestamp.fromDate(openedAt),
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
      'expectedBalance': expectedBalance,
      'variance': variance,
      'movements': movements.map((e) => e.toMap()).toList(),
    };
  }

  CashRegisterModel copyWith({
    DateTime? closedAt,
    double? closingBalance,
    double? expectedBalance,
    double? variance,
    List<CashMovement>? movements,
  }) {
    return CashRegisterModel(
      id: id,
      staffId: staffId,
      staffName: staffName,
      openedAt: openedAt,
      closedAt: closedAt ?? this.closedAt,
      openingBalance: openingBalance,
      closingBalance: closingBalance ?? this.closingBalance,
      expectedBalance: expectedBalance ?? this.expectedBalance,
      variance: variance ?? this.variance,
      movements: movements ?? this.movements,
    );
  }
}
