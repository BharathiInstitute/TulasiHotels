/// Hotel info model — lightweight metadata for the hotel selector
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a hotel
enum HotelStatus {
  active('Active'),
  suspended('Suspended'),
  archived('Archived');

  final String displayName;
  const HotelStatus(this.displayName);

  static HotelStatus fromString(String value) {
    return HotelStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HotelStatus.active,
    );
  }
}

/// Lightweight hotel reference stored in user_hotels/{userId}/hotels/{hotelId}
class HotelInfo {
  final String id;
  final String name;
  final String slug;
  final String role; // owner, manager, cashier, etc.
  final String? customRoleName; // free-text label when role == 'custom'
  final HotelStatus status;
  final DateTime createdAt;

  const HotelInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    this.customRoleName,
    this.status = HotelStatus.active,
    required this.createdAt,
  });

  bool get isOwner => role == 'owner';

  /// Display-friendly role label — shows customRoleName when role is 'custom'
  String get roleLabel {
    if (role == 'custom' && (customRoleName?.isNotEmpty ?? false)) {
      return customRoleName!;
    }
    if (role.isEmpty) return 'Member';
    return role[0].toUpperCase() + role.substring(1);
  }

  factory HotelInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HotelInfo(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      slug: (data['slug'] as String?) ?? '',
      role: (data['role'] as String?) ?? 'owner',
      customRoleName: data['customRoleName'] as String?,
      status: HotelStatus.fromString((data['status'] as String?) ?? 'active'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'slug': slug,
      'role': role,
      if (customRoleName != null) 'customRoleName': customRoleName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
