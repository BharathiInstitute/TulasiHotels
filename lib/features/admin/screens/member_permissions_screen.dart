/// Per-member permission editor — VCUD matrix for all modules
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/models/store_role.dart';
import 'package:tulasihotels/features/admin/services/member_service.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';

class MemberPermissionsScreen extends ConsumerStatefulWidget {
  final StoreMember member;

  const MemberPermissionsScreen({super.key, required this.member});

  @override
  ConsumerState<MemberPermissionsScreen> createState() =>
      _MemberPermissionsScreenState();
}

class _MemberPermissionsScreenState
    extends ConsumerState<MemberPermissionsScreen> {
  late Map<String, List<String>> _permissions;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _permissions = Map<String, List<String>>.from(
      widget.member.effectivePermissions.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = widget.member.isOwner;

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
              onPressed: _hasChanges ? _save : null,
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
    final screens = PermissionConfig.allScreens
        .where((s) => s.category == category)
        .toList();
    if (screens.isEmpty) return const SizedBox.shrink();

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
                const Expanded(flex: 3, child: Text('Module')),
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

            // Screen rows
            for (final screen in screens) _buildScreenRow(screen, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenRow(ScreenDef screen, ThemeData theme) {
    final currentActions = _permissions[screen.route] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              screen.label,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...PermissionAction.values.map(
            (action) => SizedBox(
              width: 50,
              child: Checkbox(
                value: currentActions.contains(action.key),
                onChanged: (checked) {
                  setState(() {
                    final actions = List<String>.from(
                      _permissions[screen.route] ?? [],
                    );
                    if (checked == true) {
                      if (!actions.contains(action.key)) {
                        actions.add(action.key);
                      }
                    } else {
                      actions.remove(action.key);
                    }
                    if (actions.isEmpty) {
                      _permissions.remove(screen.route);
                    } else {
                      _permissions[screen.route] = actions;
                    }
                    _hasChanges = true;
                  });
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyTemplate(StoreRole role) {
    setState(() {
      _permissions = Map<String, List<String>>.from(
        role.defaultPermissions.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
      _hasChanges = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied ${role.displayName} template')),
    );
  }

  void _grantAll() {
    final allActions = PermissionAction.values.map((a) => a.key).toList();
    setState(() {
      for (final screen in PermissionConfig.allScreens) {
        _permissions[screen.route] = List<String>.from(allActions);
      }
      _hasChanges = true;
    });
  }

  void _revokeAll() {
    setState(() {
      _permissions.clear();
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    try {
      await MemberService.updatePermissions(widget.member.uid, _permissions);
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
}
