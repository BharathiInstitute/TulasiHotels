/// Staff model for waiter/chef/manager management
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Staff roles
enum StaffRole {
  waiter('Waiter', '?????'),
  chef('Chef', '?????'),
  manager('Manager', '??'),
  cashier('Cashier', '??');

  final String displayName;
  final String emoji;

  const StaffRole(this.displayName, this.emoji);

  static StaffRole fromString(String value) {
    return StaffRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StaffRole.waiter,
    );
  }
}

class StaffModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final StaffRole role;
  final String pin; // 4-digit quick login PIN
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Per-user screen permissions: route → list of CRUD actions
  /// e.g. {'/billing': ['view','create','update','delete'], '/orders': ['view']}
  /// null means use default role-based template
  final Map<String, List<String>>? permissions;

  const StaffModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.role = StaffRole.waiter,
    required this.pin,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.permissions,
  });

  factory StaffModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse permissions map: {route: [actions]} stored as Map<String, dynamic>
    Map<String, List<String>>? permissions;
    if (data['permissions'] is Map) {
      final raw = data['permissions'] as Map<String, dynamic>;
      permissions = {
        for (final entry in raw.entries)
          entry.key: (entry.value as List<dynamic>).cast<String>(),
      };
    }

    return StaffModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      role: StaffRole.fromString((data['role'] as String?) ?? 'waiter'),
      pin: (data['pin'] as String?) ?? '0000',
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      permissions: permissions,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'pin': pin,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      if (permissions != null) 'permissions': permissions,
    };
  }

  /// Serialize to plain JSON (for SharedPreferences persistence)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name,
    'pin': pin,
    'isActive': isActive,
    'createdAt': createdAt.millisecondsSinceEpoch,
    if (permissions != null) 'permissions': permissions,
  };

  /// Deserialize from plain JSON (inverse of toJson)
  factory StaffModel.fromJson(Map<String, dynamic> data) {
    Map<String, List<String>>? permissions;
    if (data['permissions'] is Map) {
      final raw = data['permissions'] as Map<String, dynamic>;
      permissions = {
        for (final entry in raw.entries)
          entry.key: (entry.value as List<dynamic>).cast<String>(),
      };
    }
    return StaffModel(
      id: (data['id'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      role: StaffRole.fromString((data['role'] as String?) ?? 'waiter'),
      pin: (data['pin'] as String?) ?? '0000',
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as int?) ?? 0,
      ),
      permissions: permissions,
    );
  }

  StaffModel copyWith({
    String? name,
    String? email,
    String? phone,
    StaffRole? role,
    String? pin,
    bool? isActive,
    Map<String, List<String>>? permissions,
  }) {
    return StaffModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      permissions: permissions ?? this.permissions,
    );
  }
}
