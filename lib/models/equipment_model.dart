/// Equipment maintenance tracking model
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Service history record for equipment
class ServiceRecord {
  final DateTime date;
  final String description;
  final double cost;
  final String? vendorName;

  const ServiceRecord({
    required this.date,
    required this.description,
    this.cost = 0,
    this.vendorName,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'description': description,
      'cost': cost,
      'vendorName': vendorName,
    };
  }

  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: (map['description'] as String?) ?? '',
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      vendorName: map['vendorName'] as String?,
    );
  }
}

class EquipmentModel {
  final String id;
  final String name;
  final String? brand;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? purchaseCost;
  final DateTime? warrantyUntil;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDue;
  final String? amcVendor;
  final String? amcPhone;
  final List<ServiceRecord> serviceHistory;
  final DateTime createdAt;

  const EquipmentModel({
    required this.id,
    required this.name,
    this.brand,
    this.serialNumber,
    this.purchaseDate,
    this.purchaseCost,
    this.warrantyUntil,
    this.lastServiceDate,
    this.nextServiceDue,
    this.amcVendor,
    this.amcPhone,
    this.serviceHistory = const [],
    required this.createdAt,
  });

  /// Whether service is overdue
  bool get isServiceOverdue =>
      nextServiceDue != null && DateTime.now().isAfter(nextServiceDue!);

  /// Whether equipment is under warranty
  bool get isUnderWarranty =>
      warrantyUntil != null && DateTime.now().isBefore(warrantyUntil!);

  factory EquipmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EquipmentModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      brand: data['brand'] as String?,
      serialNumber: data['serialNumber'] as String?,
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate(),
      purchaseCost: (data['purchaseCost'] as num?)?.toDouble(),
      warrantyUntil: (data['warrantyUntil'] as Timestamp?)?.toDate(),
      lastServiceDate: (data['lastServiceDate'] as Timestamp?)?.toDate(),
      nextServiceDue: (data['nextServiceDue'] as Timestamp?)?.toDate(),
      amcVendor: data['amcVendor'] as String?,
      amcPhone: data['amcPhone'] as String?,
      serviceHistory: (data['serviceHistory'] as List<dynamic>?)
              ?.map((e) => ServiceRecord.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'serialNumber': serialNumber,
      'purchaseDate':
          purchaseDate != null ? Timestamp.fromDate(purchaseDate!) : null,
      'purchaseCost': purchaseCost,
      'warrantyUntil':
          warrantyUntil != null ? Timestamp.fromDate(warrantyUntil!) : null,
      'lastServiceDate': lastServiceDate != null
          ? Timestamp.fromDate(lastServiceDate!)
          : null,
      'nextServiceDue':
          nextServiceDue != null ? Timestamp.fromDate(nextServiceDue!) : null,
      'amcVendor': amcVendor,
      'amcPhone': amcPhone,
      'serviceHistory': serviceHistory.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  EquipmentModel copyWith({
    String? name,
    String? brand,
    String? serialNumber,
    DateTime? purchaseDate,
    double? purchaseCost,
    DateTime? warrantyUntil,
    DateTime? lastServiceDate,
    DateTime? nextServiceDue,
    String? amcVendor,
    String? amcPhone,
    List<ServiceRecord>? serviceHistory,
  }) {
    return EquipmentModel(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      warrantyUntil: warrantyUntil ?? this.warrantyUntil,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDue: nextServiceDue ?? this.nextServiceDue,
      amcVendor: amcVendor ?? this.amcVendor,
      amcPhone: amcPhone ?? this.amcPhone,
      serviceHistory: serviceHistory ?? this.serviceHistory,
      createdAt: createdAt,
    );
  }
}
