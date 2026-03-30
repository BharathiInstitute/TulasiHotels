/// Vendor model for supplier management
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class VendorModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final double balance;
  final List<String> supplyItems;
  final DateTime createdAt;

  const VendorModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.balance = 0,
    this.supplyItems = const [],
    required this.createdAt,
  });

  factory VendorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VendorModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      address: data['address'] as String?,
      gstNumber: data['gstNumber'] as String?,
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      supplyItems: (data['supplyItems'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
      'balance': balance,
      'supplyItems': supplyItems,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  VendorModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    double? balance,
    List<String>? supplyItems,
  }) {
    return VendorModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      balance: balance ?? this.balance,
      supplyItems: supplyItems ?? this.supplyItems,
      createdAt: createdAt,
    );
  }
}
