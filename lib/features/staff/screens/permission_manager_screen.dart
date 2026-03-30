/// Permission manager — owner assigns per-screen CRUD permissions to a staff member
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/features/staff/services/staff_service.dart';
import 'package:tulasihotels/models/staff_model.dart';

class PermissionManagerScreen extends ConsumerStatefulWidget {
  final StaffModel staff;
  const PermissionManagerScreen({super.key, required this.staff});

  @override
  ConsumerState<PermissionManagerScreen> createState() =>
      _PermissionManagerScreenState();
}

class _PermissionManagerScreenState
    extends ConsumerState<PermissionManagerScreen> {
  /// Working copy of permissions: route → list of action keys
  late Map<String, List<String>> _permissions;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Initialize from existing custom permissions or the role default template
    _permissions = Map<String, List<String>>.from(
      (widget.staff.permissions ??
              PermissionConfig.defaultTemplate(widget.staff.role))
          .map((k, v) => MapEntry(k, List<String>.from(v))),
    );
  }

  bool _hasPermission(String route, String action) {
    return _permissions[route]?.contains(action) ?? false;
  }

  void _togglePermission(String route, String action) {
    setState(() {
      _hasChanges = true;
      final actions = _permissions[route] ?? <String>[];
      if (actions.contains(action)) {
        actions.remove(action);
        if (actions.isEmpty) {
          _permissions.remove(route);
        } else {
          _permissions[route] = actions;
        }
      } else {
        _permissions[route] = [...actions, action];
      }
    });
  }

  void _toggleScreenAll(String route, bool grantAll) {
    setState(() {
      _hasChanges = true;
      if (grantAll) {
        _permissions[route] =
            PermissionAction.values.map((a) => a.key).toList();
      } else {
        _permissions.remove(route);
      }
    });
  }

  void _applyRoleTemplate(StaffRole role) {
    setState(() {
      _hasChanges = true;
      _permissions = Map<String, List<String>>.from(
        PermissionConfig.defaultTemplate(role)
            .map((k, v) => MapEntry(k, List<String>.from(v))),
      );
    });
  }

  void _grantAll() {
    setState(() {
      _hasChanges = true;
      _permissions = {
        for (final s in PermissionConfig.allScreens)
          s.route: PermissionAction.values.map((a) => a.key).toList(),
      };
    });
  }

  void _revokeAll() {
    setState(() {
      _hasChanges = true;
      _permissions = {};
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await StaffService.updatePermissions(widget.staff.id, _permissions);
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
                onPressed: _isSaving ? null : _save,
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
              onPressed: _isSaving ? null : _save,
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

  Widget _buildCategorySection(String category, ThemeData theme) {
    final screens = PermissionConfig.screensForCategory(category);
    if (screens.isEmpty) return const SizedBox.shrink();

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

          // Screen rows
          for (int i = 0; i < screens.length; i++) ...[
            _buildScreenRow(screens[i], theme),
            if (i < screens.length - 1)
              Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor.withValues(alpha: 0.3)),
          ],
        ],
      ),
    );
  }

  Widget _buildScreenRow(ScreenDef screen, ThemeData theme) {
    final hasAny = _permissions.containsKey(screen.route) &&
        (_permissions[screen.route]?.isNotEmpty ?? false);
    final hasAll = _permissions[screen.route]?.length == PermissionAction.values.length;

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
              onChanged: (v) => _toggleScreenAll(screen.route, v ?? !hasAny),
            ),
          ),

          // Screen label
          Expanded(
            flex: 2,
            child: Text(
              screen.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: hasAny
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),

          // CRUD toggles
          for (final action in PermissionAction.values)
            _buildActionChip(screen.route, action, theme),
        ],
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
