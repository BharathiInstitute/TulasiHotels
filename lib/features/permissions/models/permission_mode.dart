library;

/// Defines how effective permissions are computed for a user.
enum PermissionMode {
  /// Use role template only.
  roleOnly('role_only'),

  /// Use custom permissions only (legacy-compatible behavior).
  customOnly('custom_only'),

  /// Start from role template, then apply custom add/remove overrides.
  rolePlusCustom('role_plus_custom');

  final String key;
  const PermissionMode(this.key);

  static PermissionMode fromKey(String? value) {
    for (final mode in PermissionMode.values) {
      if (mode.key == value) return mode;
    }
    return PermissionMode.customOnly;
  }
}
