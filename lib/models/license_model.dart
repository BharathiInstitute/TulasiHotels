/// License and compliance tracking model
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of business licenses
enum LicenseType {
  fssai('FSSAI', '🍽️'),
  liquor('Liquor License', '🍺'),
  fireNoc('Fire NOC', '🧯'),
  healthCert('Health Certificate', '🏥'),
  shopAct('Shop & Establishment', '🏪'),
  gst('GST Registration', '📋'),
  other('Other', '📄');

  final String displayName;
  final String emoji;

  const LicenseType(this.displayName, this.emoji);

  static LicenseType fromString(String value) {
    return LicenseType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LicenseType.other,
    );
  }
}

class LicenseModel {
  final String id;
  final LicenseType type;
  final String? licenseNumber;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? issuingAuthority;
  final String? documentUrl;
  final bool isActive;
  final DateTime createdAt;

  const LicenseModel({
    required this.id,
    required this.type,
    this.licenseNumber,
    required this.issueDate,
    required this.expiryDate,
    this.issuingAuthority,
    this.documentUrl,
    this.isActive = true,
    required this.createdAt,
  });

  /// Days until expiry
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  /// Whether this license is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// Status color category: green (>90d), yellow (30-90d), red (<30d)
  String get urgency {
    if (isExpired) return 'expired';
    if (daysUntilExpiry < 30) return 'critical';
    if (daysUntilExpiry < 90) return 'warning';
    return 'ok';
  }

  factory LicenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LicenseModel(
      id: doc.id,
      type: LicenseType.fromString((data['type'] as String?) ?? 'other'),
      licenseNumber: data['licenseNumber'] as String?,
      issueDate:
          (data['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate:
          (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      issuingAuthority: data['issuingAuthority'] as String?,
      documentUrl: data['documentUrl'] as String?,
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'licenseNumber': licenseNumber,
      'issueDate': Timestamp.fromDate(issueDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'issuingAuthority': issuingAuthority,
      'documentUrl': documentUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  LicenseModel copyWith({
    LicenseType? type,
    String? licenseNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? issuingAuthority,
    String? documentUrl,
    bool? isActive,
  }) {
    return LicenseModel(
      id: id,
      type: type ?? this.type,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      documentUrl: documentUrl ?? this.documentUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
