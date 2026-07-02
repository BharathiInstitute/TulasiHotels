/// Permissions overview — shows all members and their permission levels
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/models/store_role.dart';
import 'package:tulasihotels/features/admin/providers/members_provider.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/router/app_router.dart';

class PermissionsOverviewScreen extends ConsumerWidget {
  const PermissionsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Permissions Overview')),
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
                    Icons.security_outlined,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No members to manage',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Legend
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap a member to edit their permissions. '
                          'V=View, C=Create, U=Update, D=Delete',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Members with permission summary
              for (final member in members)
                _MemberPermissionCard(
                  member: member,
                  onTap: () =>
                      context.push(AppRoutes.memberPermissions, extra: member),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberPermissionCard extends StatelessWidget {
  final StoreMember member;
  final VoidCallback onTap;

  const _MemberPermissionCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perms = member.effectivePermissions;
    final totalScreens = PermissionConfig.allScreens.length;
    final accessibleScreens = perms.entries
        .where((e) => e.value.contains(PermissionAction.view.key))
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: member.isOwner ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: _roleColor(
                  member.role,
                ).withValues(alpha: 0.15),
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
              const SizedBox(width: 12),

              // Name + role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.displayName, style: theme.textTheme.titleSmall),
                    if (member.email.isNotEmpty)
                      Text(
                        member.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _roleColor(
                              member.role,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            member.roleLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: _roleColor(member.role),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.isOwner
                              ? 'Full access'
                              : '$accessibleScreens / $totalScreens modules',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Access indicator
              if (member.isOwner)
                Icon(Icons.shield, color: Colors.amber.shade700, size: 20)
              else
                Icon(Icons.chevron_right, color: theme.disabledColor),
            ],
          ),
        ),
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
