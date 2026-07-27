/// Per-member permission editor — VCUD matrix for all modules
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/permissions/models/permission_mode.dart';
import 'package:tulasihotels/features/permissions/permission_panel.dart';
import 'package:tulasihotels/features/permissions/permission_policy.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/models/store_role.dart';
import 'package:tulasihotels/features/admin/services/member_service.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/router/app_router.dart';

class MemberPermissionsScreen extends ConsumerStatefulWidget {
  final StoreMember member;

  const MemberPermissionsScreen({super.key, required this.member});

  @override
  ConsumerState<MemberPermissionsScreen> createState() =>
      _MemberPermissionsScreenState();
}

class _MemberPermissionsScreenState
    extends ConsumerState<MemberPermissionsScreen> {
  late Map<String, List<String>> _customPermissions;
  late Map<String, List<String>> _revokedPermissions;
  late Map<String, List<String>> _effectivePermissions;
  late PermissionMode _permissionMode;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _permissionMode = widget.member.permissionMode;
    _customPermissions = PermissionPanels.normalizeToPanelPermissions(
      (widget.member.customPermissions ??
              widget.member.permissions ??
              widget.member.effectivePermissions)
          .map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
    );
    _revokedPermissions = PermissionPanels.normalizeToPanelPermissions(
      (widget.member.revokedPermissions ?? const <String, List<String>>{})
          .map((k, v) => MapEntry(k, List<String>.from(v))),
    );
    _effectivePermissions = _computeEffectivePermissions();
  }

  String _modeLabel(PermissionMode mode) {
    switch (mode) {
      case PermissionMode.roleOnly:
        return 'Role Only';
      case PermissionMode.customOnly:
        return 'Custom Only';
      case PermissionMode.rolePlusCustom:
        return 'Role + Custom';
    }
  }

  String _modeHint(PermissionMode mode) {
    switch (mode) {
      case PermissionMode.roleOnly:
        return 'Uses ${widget.member.roleLabel} template only';
      case PermissionMode.customOnly:
        return 'Uses only the custom panel permissions below';
      case PermissionMode.rolePlusCustom:
        return 'Starts with role template, then applies custom overrides';
    }
  }

  Map<String, List<String>> _roleBaselinePermissions() {
    return PermissionPanels.normalizeToPanelPermissions(
      PermissionPolicy.memberRoleDefaults(widget.member.role)
          .map((k, v) => MapEntry(k, List<String>.from(v))),
    );
  }

  Map<String, List<String>> _computeEffectivePermissions() {
    final roleBaseline = _roleBaselinePermissions();
    final merged = <String, Set<String>>{};

    if (_permissionMode == PermissionMode.roleOnly) {
      return roleBaseline;
    }

    if (_permissionMode == PermissionMode.customOnly) {
      return PermissionPanels.normalizeToPanelPermissions(_customPermissions);
    }

    for (final entry in roleBaseline.entries) {
      merged.putIfAbsent(entry.key, () => <String>{}).addAll(entry.value);
    }
    for (final entry in _customPermissions.entries) {
      merged.putIfAbsent(entry.key, () => <String>{}).addAll(entry.value);
    }
    for (final entry in _revokedPermissions.entries) {
      merged[entry.key]?.removeAll(entry.value);
    }

    return PermissionConfig.normalizePermissions({
      for (final entry in merged.entries) entry.key: entry.value.toList(),
    });
  }

  void _recomputeEffective() {
    _effectivePermissions = _computeEffectivePermissions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = widget.member.isOwner;
    final memberPermissions = ref.watch(routePermissionProvider(AppRoutes.members));

    return Scaffold(
      appBar: AppBar(
        title: Text('Permissions: ${widget.member.displayName}'),
        actions: [
          if (!isOwner) ...[
            // Apply template from role
            PopupMenuButton<StoreRole>(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Apply Role Template',
              onSelected: _applyTemplate,
              itemBuilder: (_) => StoreRole.values
                  .where((r) => r != StoreRole.owner)
                  .map(
                    (r) => PopupMenuItem(
                      value: r,
                      child: Text('Apply ${r.displayName} template'),
                    ),
                  )
                  .toList(),
            ),
            // Save button
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Permissions',
              onPressed: _hasChanges && memberPermissions.canUpdate
                  ? _save
                  : null,
            ),
          ],
        ],
      ),
      body: isOwner
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield,
                    size: 64,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Owner has full access',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Owner permissions cannot be modified.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : _buildPermissionMatrix(theme),
    );
  }

  Widget _buildPermissionMatrix(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModeCard(theme),
        const SizedBox(height: 12),

        // Quick actions
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.select_all, size: 18),
              label: const Text('Grant All'),
              onPressed: _grantAll,
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.deselect, size: 18),
              label: const Text('Revoke All'),
              onPressed: _revokeAll,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Permission matrix grouped by category
        for (final category in PermissionConfig.categories) ...[
          _buildCategorySection(category, theme),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildCategorySection(String category, ThemeData theme) {
    final panels = PermissionPanels.all
      .where((panel) => PermissionPanels.panelCategoryForRoute(panel.route) == category)
        .toList();
    if (panels.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Text(
              category,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),

            // Header row with action labels
            Row(
              children: [
                const Expanded(flex: 3, child: Text('Panel')),
                ...PermissionAction.values.map(
                  (a) => SizedBox(
                    width: 50,
                    child: Center(
                      child: Text(
                        a.label[0], // V, C, U, D
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Panel rows
            for (final panel in panels) _buildPanelRow(panel, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelRow(PermissionPanelDef panel, ThemeData theme) {
    final currentActions = _effectivePermissions[panel.route] ?? [];
    final supportedActions = PermissionConfig.supportedActionsForRoute(panel.route);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              panel.label,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...PermissionAction.values.map(
            (action) => SizedBox(
              width: 50,
              child: supportedActions.contains(action)
                  ? Checkbox(
                      value: currentActions.contains(action.key),
                      onChanged: (checked) {
                        setState(() {
                          if (_permissionMode == PermissionMode.rolePlusCustom) {
                            final roleBaseline = _roleBaselinePermissions();
                            final baselineHas =
                                roleBaseline[panel.route]?.contains(action.key) ?? false;
                            final effectiveHas = currentActions.contains(action.key);

                            if (effectiveHas) {
                              if (baselineHas) {
                                final revoked = List<String>.from(
                                  _revokedPermissions[panel.route] ?? const <String>[],
                                );
                                if (!revoked.contains(action.key)) {
                                  revoked.add(action.key);
                                }
                                if (revoked.isEmpty) {
                                  _revokedPermissions.remove(panel.route);
                                } else {
                                  _revokedPermissions[panel.route] = revoked;
                                }
                              } else {
                                final custom = List<String>.from(
                                  _customPermissions[panel.route] ?? const <String>[],
                                );
                                custom.remove(action.key);
                                if (custom.isEmpty) {
                                  _customPermissions.remove(panel.route);
                                } else {
                                  _customPermissions[panel.route] = custom;
                                }
                              }
                            } else {
                              if (baselineHas) {
                                final revoked = List<String>.from(
                                  _revokedPermissions[panel.route] ?? const <String>[],
                                );
                                revoked.remove(action.key);
                                if (revoked.isEmpty) {
                                  _revokedPermissions.remove(panel.route);
                                } else {
                                  _revokedPermissions[panel.route] = revoked;
                                }
                              } else {
                                final custom = List<String>.from(
                                  _customPermissions[panel.route] ?? const <String>[],
                                );
                                if (!custom.contains(action.key)) {
                                  custom.add(action.key);
                                }
                                _customPermissions[panel.route] = custom;
                              }
                            }
                          } else {
                            final actions = List<String>.from(
                              _customPermissions[panel.route] ?? const <String>[],
                            );
                            if (checked == true) {
                              if (!actions.contains(action.key)) {
                                actions.add(action.key);
                              }
                            } else {
                              actions.remove(action.key);
                            }
                            final normalized = PermissionPanels
                                .normalizeToPanelPermissions({panel.route: actions});
                            if (normalized.isEmpty) {
                              _customPermissions.remove(panel.route);
                            } else {
                              _customPermissions[panel.route] =
                                  normalized[panel.route]!;
                            }
                          }
                          _recomputeEffective();
                          _hasChanges = true;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )
                  : Center(
                      child: Text(
                        '—',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyTemplate(StoreRole role) {
    setState(() {
      _permissionMode = PermissionMode.customOnly;
      _customPermissions = PermissionPanels.normalizeToPanelPermissions(
        PermissionPolicy.memberRoleDefaults(role).map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
      _revokedPermissions = {};
      _recomputeEffective();
      _hasChanges = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied ${role.displayName} template')),
    );
  }

  void _grantAll() {
    setState(() {
      _permissionMode = PermissionMode.customOnly;
      for (final panel in PermissionPanels.all) {
        _customPermissions[panel.route] = PermissionConfig
            .supportedActionsForRoute(panel.route)
            .map((action) => action.key)
            .toList();
      }
      _revokedPermissions = {};
      _recomputeEffective();
      _hasChanges = true;
    });
  }

  void _revokeAll() {
    setState(() {
      _permissionMode = PermissionMode.customOnly;
      _customPermissions.clear();
      _revokedPermissions.clear();
      _recomputeEffective();
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    final permissions = ref.read(routePermissionProvider(AppRoutes.members));
    if (!permissions.canUpdate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              PermissionCenter.deniedActionMessage(
                AppRoutes.members,
                PermissionAction.update,
              ),
            ),
          ),
        );
      }
      return;
    }

    try {
      await MemberService.updatePermissionConfig(
        widget.member.uid,
        mode: _permissionMode,
        customPermissions: _customPermissions,
        revokedPermissions: _revokedPermissions,
      );
      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Widget _buildModeCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.tune, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permission Mode',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _modeHint(_permissionMode),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            DropdownButton<PermissionMode>(
              value: _permissionMode,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _hasChanges = true;
                  _permissionMode = value;
                  if (value == PermissionMode.roleOnly) {
                    _revokedPermissions = {};
                    _recomputeEffective();
                  } else if (value == PermissionMode.customOnly) {
                    _revokedPermissions = {};
                    _recomputeEffective();
                  } else {
                    _recomputeEffective();
                  }
                });
              },
              items: PermissionMode.values
                  .map(
                    (mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(_modeLabel(mode)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}
