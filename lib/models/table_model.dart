/// Table model for restaurant floor management
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Table status types
enum TableStatus {
  available('Available', '??'),
  occupied('Occupied', '??'),
  reserved('Reserved', '??'),
  billing('Billing', '??');

  final String displayName;
  final String emoji;

  const TableStatus(this.displayName, this.emoji);

  static TableStatus fromString(String value) {
    return TableStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TableStatus.available,
    );
  }
}

class TableModel {
  final String id;
  final int number;
  final String? label;
  final int capacity;
  final int floor;
  final TableStatus status;
  final String? currentOrderId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Floor plan layout
  final double? posX;
  final double? posY;
  final String? shape; // 'round', 'square', 'rectangle'

  // Server assignment
  final String? assignedServerId;
  final String? assignedServerName;

  const TableModel({
    required this.id,
    required this.number,
    this.label,
    this.capacity = 4,
    this.floor = 0,
    this.status = TableStatus.available,
    this.currentOrderId,
    required this.createdAt,
    this.updatedAt,
    this.posX,
    this.posY,
    this.shape,
    this.assignedServerId,
    this.assignedServerName,
  });

  /// Display name: label if set, otherwise "Table {number}"
  String get displayName => label ?? 'Table $number';

  /// Whether the table is free to seat new guests
  bool get isFree => status == TableStatus.available;

  /// Whether the table has an active order
  bool get hasActiveOrder => currentOrderId != null;

  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableModel(
      id: doc.id,
      number: (data['number'] as int?) ?? 0,
      label: data['label'] as String?,
      capacity: (data['capacity'] as int?) ?? 4,
      floor: (data['floor'] as int?) ?? 0,
      status: TableStatus.fromString((data['status'] as String?) ?? 'available'),
      currentOrderId: data['currentOrderId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      posX: (data['posX'] as num?)?.toDouble(),
      posY: (data['posY'] as num?)?.toDouble(),
      shape: data['shape'] as String?,
      assignedServerId: data['assignedServerId'] as String?,
      assignedServerName: data['assignedServerName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'number': number,
      'label': label,
      'capacity': capacity,
      'floor': floor,
      'status': status.name,
      'currentOrderId': currentOrderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      if (posX != null) 'posX': posX,
      if (posY != null) 'posY': posY,
      if (shape != null) 'shape': shape,
      if (assignedServerId != null) 'assignedServerId': assignedServerId,
      if (assignedServerName != null) 'assignedServerName': assignedServerName,
    };
  }

  TableModel copyWith({
    String? label,
    int? number,
    int? capacity,
    int? floor,
    TableStatus? status,
    String? currentOrderId,
    bool clearCurrentOrderId = false,
    double? posX,
    double? posY,
    String? shape,
    String? assignedServerId,
    String? assignedServerName,
    bool clearAssignedServer = false,
  }) {
    return TableModel(
      id: id,
      number: number ?? this.number,
      label: label ?? this.label,
      capacity: capacity ?? this.capacity,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      currentOrderId: clearCurrentOrderId
          ? null
          : (currentOrderId ?? this.currentOrderId),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      shape: shape ?? this.shape,
      assignedServerId: clearAssignedServer
          ? null
          : (assignedServerId ?? this.assignedServerId),
      assignedServerName: clearAssignedServer
          ? null
          : (assignedServerName ?? this.assignedServerName),
    );
  }
}
