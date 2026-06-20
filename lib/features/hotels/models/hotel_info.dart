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
  final HotelStatus status;
  final DateTime createdAt;

  const HotelInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    this.status = HotelStatus.active,
    required this.createdAt,
  });

  bool get isOwner => role == 'owner';

  factory HotelInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HotelInfo(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      slug: (data['slug'] as String?) ?? '',
      role: (data['role'] as String?) ?? 'owner',
      status: HotelStatus.fromString((data['status'] as String?) ?? 'active'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'slug': slug,
      'role': role,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
