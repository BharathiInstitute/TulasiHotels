/// Store members management screen — invite, manage roles, remove members
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/models/store_role.dart';
import 'package:tulasihotels/features/admin/providers/members_provider.dart';
import 'package:tulasihotels/features/admin/services/member_service.dart';
import 'package:tulasihotels/features/subscription/services/plan_enforcement_service.dart';
import 'package:tulasihotels/router/app_router.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure owner is registered as a member on first visit
    MemberService.ensureOwnerMember();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(filteredMembersProvider);
    final roleFilter = ref.watch(memberRoleFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Members'),
        actions: [
          // Role filter dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<StoreRole?>(
              value: roleFilter,
              hint: const Text('All Roles'),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<StoreRole?>(child: Text('All Roles')),
                ...StoreRole.values.map(
                  (r) => DropdownMenuItem(value: r, child: Text(r.displayName)),
                ),
              ],
              onChanged: (value) {
                ref.read(memberRoleFilterProvider.notifier).state = value;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add User',
            onPressed: () => _showInviteDialog(context),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text('No members yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Invite people to manage your restaurant',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add User'),
                    onPressed: () => _showInviteDialog(context),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = members[index];
              return _MemberTile(
                member: member,
                onChangeRole: () => _showChangeRoleDialog(context, member),
                onPermissions: () =>
                    context.push(AppRoutes.memberPermissions, extra: member),
                onRemove: member.isOwner
                    ? null
                    : () => _confirmRemove(context, member),
                onToggleStatus: member.isOwner
                    ? null
                    : () => _toggleStatus(member),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context) async {
    // ── Check plan BEFORE opening the dialog ──
    final planCheck = await PlanEnforcementService.checkLimit(LimitType.staff);
    if (!planCheck.allowed) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.removeCurrentSnackBar();
      final ctrl = messenger.showSnackBar(
        SnackBar(
          content: Text(planCheck.message ?? 'Upgrade your plan to add staff.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Upgrade',
            textColor: Colors.white,
            onPressed: () {
              if (context.mounted) context.push(AppRoutes.subscription);
            },
          ),
        ),
      );
      return;
    }

    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final roleController = TextEditingController();
    var showPassword = false;
    var showConfirm = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              CircleAvatar(radius: 18, child: Icon(Icons.person_add, size: 18)),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New User',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Create a new team member account',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: Icon(Icons.person_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: passwordController,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setDialogState(
                              () => showPassword = !showPassword,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: confirmController,
                        obscureText: !showConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setDialogState(
                              () => showConfirm = !showConfirm,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    hintText: 'e.g. Chef, Receptionist, Cashier…',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => Navigator.pop(ctx, true),
              label: const Text('Create User'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      final email = emailController.text.trim();
      final name = nameController.text.trim();
      final password = passwordController.text;
      final confirm = confirmController.text;
      final roleText = roleController.text.trim();
      final sm = ScaffoldMessenger.of(context);
      if (email.isEmpty) {
        sm.clearSnackBars();
        sm.showSnackBar(const SnackBar(content: Text('Email is required'), duration: Duration(seconds: 3)));
        return;
      }
      if (password.isNotEmpty && password.length < 6) {
        sm.clearSnackBars();
        sm.showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters'), duration: Duration(seconds: 3)));
        return;
      }
      if (password.isNotEmpty && password != confirm) {
        sm.clearSnackBars();
        sm.showSnackBar(const SnackBar(content: Text('Passwords do not match'), duration: Duration(seconds: 3)));
        return;
      }

      try {
        await MemberService.inviteMember(
          email: email,
          displayName: name.isNotEmpty ? name : email.split('@').first,
          customRoleName: roleText.isNotEmpty ? roleText : null,
          password: password.isNotEmpty ? password : null,
        );
        if (context.mounted) {
          sm.clearSnackBars();
          sm.showSnackBar(SnackBar(
            content: Text('Added $email as ${roleText.isNotEmpty ? roleText : 'Team Member'}'),
            duration: const Duration(seconds: 3),
          ));
        }
      } on FirebaseAuthException catch (e) {
        if (context.mounted) {
          final msg = switch (e.code) {
            'weak-password' => 'Password must be at least 6 characters',
            'email-already-in-use' => 'An account already exists for $email',
            'invalid-email' => 'Invalid email address',
            _ => e.message ?? e.code,
          };
          sm.clearSnackBars();
          sm.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
        }
      } catch (e) {
        if (context.mounted) {
          sm.clearSnackBars();
          sm.showSnackBar(SnackBar(content: Text('Error: $e'), duration: const Duration(seconds: 3)));
        }
      }
    }
    emailController.dispose();
    nameController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    roleController.dispose();
  }

  Future<void> _showChangeRoleDialog(
    BuildContext context,
    StoreMember member,
  ) async {
    if (member.isOwner) return; // Can't change owner role

    var selectedRole = member.role;
    final result = await showDialog<StoreRole>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Change Role: ${member.displayName}'),
          content: RadioGroup<StoreRole>(
            groupValue: selectedRole,
            onChanged: (v) {
              if (v != null) setDialogState(() => selectedRole = v);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: StoreRole.values
                  .where((r) => r != StoreRole.owner)
                  .map(
                    (r) => RadioListTile<StoreRole>(
                      title: Text(r.displayName),
                      subtitle: Text(r.description),
                      value: r,
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selectedRole),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != member.role && context.mounted) {
      await MemberService.updateRole(member.uid, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.displayName} is now ${result.displayName}'),
          ),
        );
      }
    }
  }

  Future<void> _confirmRemove(BuildContext context, StoreMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text(
          'Remove ${member.displayName} (${member.email}) from this restaurant? '
          'They will lose all access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await MemberService.removeMember(member.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.displayName} removed')),
        );
      }
    }
  }

  Future<void> _toggleStatus(StoreMember member) async {
    if (member.status == MemberStatus.active) {
      await MemberService.disableMember(member.uid);
    } else {
      await MemberService.enableMember(member.uid);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member list tile
// ─────────────────────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final StoreMember member;
  final VoidCallback onChangeRole;
  final VoidCallback onPermissions;
  final VoidCallback? onRemove;
  final VoidCallback? onToggleStatus;

  const _MemberTile({
    required this.member,
    required this.onChangeRole,
    required this.onPermissions,
    this.onRemove,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = member.status == MemberStatus.disabled;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _roleColor(member.role).withValues(alpha: 0.15),
        child: Text(
          member.displayName.isNotEmpty
              ? member.displayName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: _roleColor(member.role),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.displayName,
              overflow: TextOverflow.ellipsis,
              style: isDisabled
                  ? TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: theme.disabledColor,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          _RoleBadge(role: member.role, customName: member.customRoleName),
          if (member.status == MemberStatus.invited) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'INVITED',
                style: TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        member.email,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: member.isOwner
          ? Chip(
              label: const Text('Owner'),
              backgroundColor: Colors.amber.withValues(alpha: 0.2),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              labelStyle: const TextStyle(fontSize: 11),
            )
          : PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'role':
                    onChangeRole();
                  case 'permissions':
                    onPermissions();
                  case 'toggle':
                    onToggleStatus?.call();
                  case 'remove':
                    onRemove?.call();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'role',
                  child: ListTile(
                    leading: Icon(Icons.badge_outlined),
                    title: Text('Change Role'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'permissions',
                  child: ListTile(
                    leading: Icon(Icons.security_outlined),
                    title: Text('Permissions'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    leading: Icon(
                      isDisabled ? Icons.check_circle_outline : Icons.block,
                    ),
                    title: Text(isDisabled ? 'Enable' : 'Disable'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Remove', style: TextStyle(color: Colors.red)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
    );
  }

  Color _roleColor(StoreRole role) {
    switch (role) {
      case StoreRole.owner:
        return Colors.amber.shade700;
      case StoreRole.manager:
        return Colors.blue;
      case StoreRole.accountant:
        return Colors.teal;
      case StoreRole.cashier:
        return Colors.green;
      case StoreRole.staff:
        return Colors.grey;
      case StoreRole.custom:
        return Colors.purple;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role badge chip
// ─────────────────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final StoreRole role;
  final String? customName;
  const _RoleBadge({required this.role, this.customName});

  @override
  Widget build(BuildContext context) {
    final label = role == StoreRole.custom && (customName?.isNotEmpty ?? false)
        ? customName!
        : role.displayName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }

  Color get _color {
    switch (role) {
      case StoreRole.owner:
        return Colors.amber.shade700;
      case StoreRole.manager:
        return Colors.blue;
      case StoreRole.accountant:
        return Colors.teal;
      case StoreRole.cashier:
        return Colors.green;
      case StoreRole.staff:
        return Colors.grey.shade700;
      case StoreRole.custom:
        return Colors.purple;
    }
  }
}
