/// Store member model — represents a Firebase Auth user with access to a store
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/features/admin/models/store_role.dart';

/// Member status within a store
enum MemberStatus {
  active('Active'),
  invited('Invited'),
  disabled('Disabled');

  final String displayName;
  const MemberStatus(this.displayName);

  static MemberStatus fromString(String value) {
    return MemberStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MemberStatus.invited,
    );
  }
}

/// A user who has access to a store (stored at stores/{storeId}/members/{uid})
class StoreMember {
  final String uid;
  final String email;
  final String displayName;
  final StoreRole role;

  /// Free-text role label used when [role] == [StoreRole.custom]
  final String? customRoleName;
  final MemberStatus status;
  final Map<String, List<String>>? permissions;
  final DateTime joinedAt;
  final String? invitedBy;

  const StoreMember({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.customRoleName,
    this.status = MemberStatus.active,
    this.permissions,
    required this.joinedAt,
    this.invitedBy,
  });

  /// Display-friendly role label (uses customRoleName for custom role)
  String get roleLabel =>
      role == StoreRole.custom && (customRoleName?.isNotEmpty ?? false)
      ? customRoleName!
      : role.displayName;

  /// Effective permissions: custom overrides or role defaults
  Map<String, List<String>> get effectivePermissions {
    return permissions ?? role.defaultPermissions;
  }

  bool get isOwner => role == StoreRole.owner;

  factory StoreMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Map<String, List<String>>? permissions;
    if (data['permissions'] is Map) {
      final raw = data['permissions'] as Map<String, dynamic>;
      permissions = {
        for (final entry in raw.entries)
          entry.key: (entry.value as List<dynamic>).cast<String>(),
      };
    }

    return StoreMember(
      uid: doc.id,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      role: StoreRole.fromString((data['role'] as String?) ?? 'staff'),
      customRoleName: data['customRoleName'] as String?,
      status: MemberStatus.fromString((data['status'] as String?) ?? 'invited'),
      permissions: permissions,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invitedBy: data['invitedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      if (customRoleName != null) 'customRoleName': customRoleName,
      'status': status.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      if (permissions != null) 'permissions': permissions,
      if (invitedBy != null) 'invitedBy': invitedBy,
    };
  }

  StoreMember copyWith({
    String? email,
    String? displayName,
    StoreRole? role,
    String? customRoleName,
    MemberStatus? status,
    Map<String, List<String>>? permissions,
    String? invitedBy,
  }) {
    return StoreMember(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      customRoleName: customRoleName ?? this.customRoleName,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      joinedAt: joinedAt,
      invitedBy: invitedBy ?? this.invitedBy,
    );
  }
}
