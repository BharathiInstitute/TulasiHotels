/// Staff management screen — list, add, edit, toggle active
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/screens/permission_manager_screen.dart';
import 'package:tulasihotels/features/staff/services/staff_service.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(filteredStaffProvider);
    final roleFilter = ref.watch(staffRoleFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          // Role filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<StaffRole?>(
              value: roleFilter,
              hint: const Text('All Roles'),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<StaffRole?>(child: Text('All Roles')),
                ...StaffRole.values.map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text('${r.emoji} ${r.displayName}'),
                  ),
                ),
              ],
              onChanged: (value) {
                ref.read(staffRoleFilterProvider.notifier).state = value;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Staff',
            onPressed: () => _showAddEditDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick-action chips for sub-features
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: const Text('Shifts'),
                  onPressed: () => context.push(AppRoutes.shifts),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.task_alt, size: 18),
                  label: const Text('Tasks'),
                  onPressed: () => context.push(AppRoutes.tasks),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.message, size: 18),
                  label: const Text('Messages'),
                  onPressed: () => context.push(AppRoutes.messages),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.account_balance_wallet, size: 18),
                  label: const Text('Salary'),
                  onPressed: () => context.push(AppRoutes.salary),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.point_of_sale, size: 18),
                  label: const Text('Cash Register'),
                  onPressed: () => context.push(AppRoutes.cashRegister),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search staff by name or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                ref.read(staffSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Staff list
          Expanded(
            child: staffAsync.when(
              data: (staff) {
                if (staff.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No staff members yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _showAddEditDialog(context),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Staff'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: staff.length,
                  itemBuilder: (context, index) {
                    final member = staff[index];
                    return _StaffCard(
                      staff: member,
                      onEdit: () => _showAddEditDialog(context, staff: member),
                      onPermissions: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PermissionManagerScreen(staff: member),
                          ),
                        );
                      },
                      onToggleActive: () async {
                        await StaffService.toggleStaffActive(
                          member.id,
                          !member.isActive,
                        );
                      },
                      onDelete: () => _confirmDelete(context, member),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {StaffModel? staff}) {
    showDialog(
      context: context,
      builder: (ctx) => _AddEditStaffDialog(staff: staff),
    );
  }

  void _confirmDelete(BuildContext context, StaffModel staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${staff.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await StaffService.deleteStaff(staff.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${staff.name} deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Staff Card ────────────────────────────────────────────────

class _StaffCard extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onPermissions;

  const _StaffCard({
    required this.staff,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onPermissions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: staff.isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Text(
            staff.role.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                staff.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: staff.isActive
                      ? null
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            if (!staff.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              '${staff.role.displayName}${staff.email != null ? ' | ${staff.email}' : ''}',
            ),
            if (staff.permissions != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Custom',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prominent permissions button
            IconButton(
              icon: Icon(
                Icons.shield_outlined,
                color: staff.permissions != null
                    ? Colors.blue
                    : theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Manage Permissions',
              onPressed: onPermissions,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'toggle':
                    onToggleActive();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(staff.isActive ? 'Deactivate' : 'Activate'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add / Edit Dialog ─────────────────────────────────────────

class _AddEditStaffDialog extends StatefulWidget {
  final StaffModel? staff;
  const _AddEditStaffDialog({this.staff});

  @override
  State<_AddEditStaffDialog> createState() => _AddEditStaffDialogState();
}

class _AddEditStaffDialogState extends State<_AddEditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _pinCtrl;
  late StaffRole _role;
  bool _isLoading = false;

  bool get isEditing => widget.staff != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.staff?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.staff?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.staff?.phone ?? '');
    _pinCtrl = TextEditingController(text: widget.staff?.pin ?? '');
    _role = widget.staff?.role ?? StaffRole.waiter;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Staff' : 'Add Staff'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                  helperText: 'Staff will use this email to log in',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required for staff login';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StaffRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Role *',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: StaffRole.values
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text('${r.emoji} ${r.displayName}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pinCtrl,
                decoration: const InputDecoration(
                  labelText: '4-Digit PIN *',
                  prefixIcon: Icon(Icons.lock),
                  helperText: 'Used for quick staff login',
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.length != 4) {
                    return 'Enter a 4-digit PIN';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final pin = _pinCtrl.text.trim();

      // Check PIN uniqueness
      final pinTaken = await StaffService.isPinTaken(
        pin,
        excludeStaffId: widget.staff?.id,
      );
      if (pinTaken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This PIN is already assigned to another staff member'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      if (isEditing) {
        final updated = widget.staff!.copyWith(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          role: _role,
          pin: pin,
        );
        await StaffService.updateStaff(updated);
      } else {
        await StaffService.createStaff(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          role: _role,
          pin: pin,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
