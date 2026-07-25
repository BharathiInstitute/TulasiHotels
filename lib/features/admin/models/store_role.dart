/// Store-level roles for multi-user access
library;

import 'package:tulasihotels/features/permissions/permission_policy.dart';

/// Roles that a store member (Firebase Auth user) can hold
enum StoreRole {
  owner('Owner', 'Full access — cannot be removed'),
  manager('Manager', 'All features except user management'),
  accountant('Accountant', 'Finance, reports, and billing access'),
  cashier('Cashier', 'POS, billing, and order access'),
  staff('Staff', 'View-only on assigned modules'),
  custom('Custom', 'Manually assigned permissions');

  final String displayName;
  final String description;

  const StoreRole(this.displayName, this.description);

  static StoreRole fromString(String value) {
    return StoreRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StoreRole.staff,
    );
  }

  /// Default permission template for this role
  Map<String, List<String>> get defaultPermissions {
    return PermissionPolicy.memberRoleDefaults(this);
  }
}
