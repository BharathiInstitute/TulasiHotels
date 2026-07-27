/// Permission manager — owner assigns per-screen CRUD permissions to a staff member
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/models/permission_mode.dart';
import 'package:tulasihotels/features/permissions/permission_panel.dart';
import 'package:tulasihotels/features/permissions/permission_policy.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/services/staff_service.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class PermissionManagerScreen extends ConsumerStatefulWidget {
  final StaffModel staff;
  const PermissionManagerScreen({super.key, required this.staff});

  @override
  ConsumerState<PermissionManagerScreen> createState() =>
      _PermissionManagerScreenState();
}

class _PermissionManagerScreenState
    extends ConsumerState<PermissionManagerScreen> {
  /// Working copy of custom allow overrides: route → list of action keys
  late Map<String, List<String>> _customPermissions;

  /// Working copy of custom remove overrides: route → list of action keys
  late Map<String, List<String>> _revokedPermissions;

  /// Effective permissions shown in the matrix.
  late Map<String, List<String>> _effectivePermissions;

  late PermissionMode _permissionMode;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _permissionMode = widget.staff.permissionMode;
    _customPermissions = PermissionPanels.normalizeToPanelPermissions(
      (widget.staff.customPermissions ??
              widget.staff.permissions ??
              PermissionConfig.minimalAssignedPermissions())
          .map((k, v) => MapEntry(k, List<String>.from(v))),
    );
    _revokedPermissions = PermissionPanels.normalizeToPanelPermissions(
      (widget.staff.revokedPermissions ?? const <String, List<String>>{})
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
        return 'Uses ${widget.staff.role.displayName} template only';
      case PermissionMode.customOnly:
        return 'Uses only the custom panel permissions below';
      case PermissionMode.rolePlusCustom:
        return 'Starts with role template, then applies custom overrides';
    }
  }

  Map<String, List<String>> _roleBaselinePermissions() {
    return PermissionPanels.normalizeToPanelPermissions(
      PermissionPolicy.staffRoleDefaults(widget.staff.role)
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

  bool _hasPermission(String route, String action) {
    return _effectivePermissions[route]?.contains(action) ?? false;
  }

  void _recomputeEffective() {
    _effectivePermissions = _computeEffectivePermissions();
  }

  void _togglePermission(String route, String action) {
    if (!PermissionConfig.supportedActionsForRoute(route)
        .any((item) => item.key == action)) {
      return;
    }

    setState(() {
      _hasChanges = true;
      if (_permissionMode == PermissionMode.rolePlusCustom) {
        final roleBaseline = _roleBaselinePermissions();
        final baselineHas = roleBaseline[route]?.contains(action) ?? false;
        final effectiveHas = _hasPermission(route, action);

        if (effectiveHas) {
          if (baselineHas) {
            final revoked = List<String>.from(_revokedPermissions[route] ?? const <String>[]);
            if (!revoked.contains(action)) revoked.add(action);
            if (revoked.isEmpty) {
              _revokedPermissions.remove(route);
            } else {
              _revokedPermissions[route] = revoked;
            }
          } else {
            final custom = List<String>.from(_customPermissions[route] ?? const <String>[]);
            custom.remove(action);
            if (custom.isEmpty) {
              _customPermissions.remove(route);
            } else {
              _customPermissions[route] = custom;
            }
          }
        } else {
          if (baselineHas) {
            final revoked = List<String>.from(_revokedPermissions[route] ?? const <String>[]);
            revoked.remove(action);
            if (revoked.isEmpty) {
              _revokedPermissions.remove(route);
            } else {
              _revokedPermissions[route] = revoked;
            }
          } else {
            final custom = List<String>.from(_customPermissions[route] ?? const <String>[]);
            if (!custom.contains(action)) custom.add(action);
            _customPermissions[route] = custom;
          }
        }
      } else {
        final actions = List<String>.from(_customPermissions[route] ?? const <String>[]);
        if (actions.contains(action)) {
          actions.remove(action);
          if (actions.isEmpty) {
            _customPermissions.remove(route);
          } else {
            _customPermissions[route] = actions;
          }
        } else {
          _customPermissions[route] = [...actions, action];
        }
      }

      _recomputeEffective();
    });
  }

  void _toggleScreenAll(String route, bool grantAll) {
    final supportedActions = PermissionConfig.supportedActionsForRoute(route);

    setState(() {
      _hasChanges = true;
      if (_permissionMode == PermissionMode.rolePlusCustom) {
        final roleBaseline = _roleBaselinePermissions();
        final baseline = roleBaseline[route] ?? const <String>[];
        if (grantAll) {
          _revokedPermissions.remove(route);
          final custom = <String>{...(_customPermissions[route] ?? const <String>[])};
          for (final action in supportedActions) {
            if (!baseline.contains(action.key)) {
              custom.add(action.key);
            }
          }
          if (custom.isEmpty) {
            _customPermissions.remove(route);
          } else {
            _customPermissions[route] = custom.toList();
          }
        } else {
          final revoked = <String>{...baseline};
          _revokedPermissions[route] = revoked.toList();
          _customPermissions.remove(route);
        }
      } else {
        if (grantAll) {
          _customPermissions[route] = supportedActions.map((a) => a.key).toList();
        } else {
          _customPermissions.remove(route);
        }
      }

      _recomputeEffective();
    });
  }

  void _applyRoleTemplate(StaffRole role) {
    setState(() {
      _hasChanges = true;
      _permissionMode = PermissionMode.customOnly;
      _customPermissions = PermissionPanels.normalizeToPanelPermissions(
        PermissionConfig.defaultTemplate(role)
            .map((k, v) => MapEntry(k, List<String>.from(v))),
      );
      _revokedPermissions = {};
      _recomputeEffective();
    });
  }

  void _grantAll() {
    setState(() {
      _hasChanges = true;
      _permissionMode = PermissionMode.customOnly;
      _customPermissions = {
        for (final panel in PermissionPanels.all)
          panel.route: PermissionConfig.supportedActionsForRoute(
            panel.route,
          ).map((a) => a.key).toList(),
      };
      _revokedPermissions = {};
      _recomputeEffective();
    });
  }

  void _revokeAll() {
    setState(() {
      _hasChanges = true;
      _permissionMode = PermissionMode.customOnly;
      _customPermissions = {};
      _revokedPermissions = {};
      _recomputeEffective();
    });
  }

  Future<void> _save() async {
    final permissions = ref.read(routePermissionProvider(AppRoutes.staff));
    if (!permissions.canUpdate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              PermissionCenter.deniedActionMessage(
                AppRoutes.staff,
                PermissionAction.update,
              ),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      await StaffService.updatePermissionConfig(
        widget.staff.id,
        mode: _permissionMode,
        customPermissions: _customPermissions,
        revokedPermissions: _revokedPermissions,
      );

      final loggedInStaff = ref.read(loggedInStaffProvider);
      if (loggedInStaff != null && loggedInStaff.id == widget.staff.id) {
        ref
            .read(loggedInStaffProvider.notifier)
            .login(
              loggedInStaff.copyWith(
                permissions: _customPermissions,
                permissionMode: _permissionMode,
                customPermissions: _customPermissions,
                revokedPermissions: _revokedPermissions,
              ),
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissions updated for ${widget.staff.name}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _hasChanges = false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final permissions = ref.watch(routePermissionProvider(AppRoutes.staff));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Permissions'),
            Text(
              '${widget.staff.role.emoji} ${widget.staff.name} — ${widget.staff.role.displayName}',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          // Quick-fill dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Quick Templates',
            onSelected: (value) {
              if (value == 'all') {
                _grantAll();
              } else if (value == 'none') {
                _revokeAll();
              } else {
                final role = StaffRole.fromString(value);
                _applyRoleTemplate(role);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: ListTile(
                  leading: Icon(Icons.check_box, color: Colors.green),
                  title: Text('Grant All'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'none',
                child: ListTile(
                  leading: Icon(Icons.indeterminate_check_box, color: Colors.red),
                  title: Text('Revoke All'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              ...StaffRole.values.map(
                (role) => PopupMenuItem(
                  value: role.name,
                  child: ListTile(
                    leading: Text(role.emoji, style: const TextStyle(fontSize: 20)),
                    title: Text('${role.displayName} Template'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),

          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _isSaving || !permissions.canUpdate ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 18),
                label: const Text('Save'),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildModeCard(theme),
          const SizedBox(height: 12),

          // Legend
          _buildLegend(theme),
          const SizedBox(height: 16),

          // Permission grid by category
          for (final category in PermissionConfig.categories) ...[
            _buildCategorySection(category, theme),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 80),
        ],
      ),
      // Floating save button for mobile accessibility
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
            onPressed: _isSaving || !permissions.canUpdate ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Permissions'),
            )
          : null,
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: PermissionAction.values.map((a) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionIcon(a),
                      const SizedBox(width: 4),
                      Text(a.label, style: const TextStyle(fontSize: 12)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildCategorySection(String category, ThemeData theme) {
    final panels = PermissionPanels.all
        .where((panel) => PermissionPanels.panelCategoryForRoute(panel.route) == category)
        .toList(growable: false);
    if (panels.isEmpty) return const SizedBox.shrink();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          // Panel rows
          for (int i = 0; i < panels.length; i++) ...[
            _buildScreenRow(panels[i], theme),
            if (i < panels.length - 1)
              Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor.withValues(alpha: 0.3)),
          ],
        ],
      ),
    );
  }

  Widget _buildScreenRow(PermissionPanelDef panel, ThemeData theme) {
    final supportedActions = PermissionConfig.supportedActionsForRoute(panel.route);
    final effectiveActions = _effectivePermissions[panel.route] ?? const <String>[];
    final hasAny = effectiveActions.isNotEmpty;
    final hasAll = effectiveActions.length == supportedActions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Select-all checkbox for this screen
          SizedBox(
            width: 32,
            child: Checkbox(
              value: hasAll ? true : (hasAny ? null : false),
              tristate: true,
              onChanged: (v) => _toggleScreenAll(panel.route, v ?? !hasAny),
            ),
          ),

          // Panel label
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  panel.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: hasAny
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  panel.collections.join(', '),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // CRUD toggles
          for (final action in PermissionAction.values)
            supportedActions.contains(action)
                ? _buildActionChip(panel.route, action, theme)
                : _buildUnsupportedActionChip(theme),
        ],
      ),
    );
  }

  Widget _buildUnsupportedActionChip(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: Text(
          '—',
          style: TextStyle(
            color: theme.colorScheme.outline.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip(String route, PermissionAction action, ThemeData theme) {
    final isOn = _hasPermission(route, action.key);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _togglePermission(route, action.key),
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isOn
                ? _actionColor(action).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isOn
                  ? _actionColor(action).withValues(alpha: 0.4)
                  : theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _actionIconData(action),
                size: 16,
                color: isOn ? _actionColor(action) : theme.colorScheme.outline,
              ),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isOn ? FontWeight.w600 : FontWeight.normal,
                  color: isOn ? _actionColor(action) : theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(PermissionAction action) {
    return Icon(_actionIconData(action), size: 16, color: _actionColor(action));
  }

  static IconData _actionIconData(PermissionAction action) {
    switch (action) {
      case PermissionAction.view:
        return Icons.visibility;
      case PermissionAction.create:
        return Icons.add_circle;
      case PermissionAction.update:
        return Icons.edit;
      case PermissionAction.delete:
        return Icons.delete;
    }
  }

  static Color _actionColor(PermissionAction action) {
    switch (action) {
      case PermissionAction.view:
        return Colors.blue;
      case PermissionAction.create:
        return Colors.green;
      case PermissionAction.update:
        return Colors.orange;
      case PermissionAction.delete:
        return Colors.red;
    }
  }
}
