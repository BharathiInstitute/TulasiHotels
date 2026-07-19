/// Staff management screen — team list with per-staff action icons
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/models/store_role.dart';
import 'package:tulasihotels/features/admin/providers/current_member_provider.dart';
import 'package:tulasihotels/features/admin/providers/members_provider.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/screens/permission_manager_screen.dart';
import 'package:tulasihotels/features/staff/services/salary_service.dart';
import 'package:tulasihotels/features/staff/services/staff_service.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only the store owner may view staff data.
    // Block both PIN-logged staff and Firebase Team Members who are not the owner.
    final loggedInStaff = ref.watch(loggedInStaffProvider);
    final currentHotel = ref.watch(currentHotelProvider);
    final isOwner = currentHotel?.isOwner ?? false;

    if (loggedInStaff != null) {
      return _StaffProfileView(staff: loggedInStaff);
    }

    if (!isOwner) {
      // Non-owner Firebase team member → show their own profile
      final memberAsync = ref.watch(currentMemberProvider);
      final member = memberAsync.valueOrNull;
      if (member != null) {
        return _MemberProfileView(member: member);
      }
      // Loading or no member doc → show restricted
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Access Restricted',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Staff data is only visible to the owner.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final staffAsync = ref.watch(filteredStaffProvider);
    final roleFilter = ref.watch(staffRoleFilterProvider);
    final membersAsync = ref.watch(membersStreamProvider);
    final staffPermissions = ref.watch(routePermissionProvider(AppRoutes.staff));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Staff Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Manage your team, attendance, and payouts',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search + role filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search staff...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        ref.read(staffSearchQueryProvider.notifier).state = v,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<StaffRole?>(
                  value: roleFilter,
                  hint: const Text('All'),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem<StaffRole?>(child: Text('All')),
                    ...StaffRole.values.map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text('${r.emoji} ${r.displayName}'),
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      ref.read(staffRoleFilterProvider.notifier).state = v,
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: staffAsync.when(
              data: (staff) {
                final members =
                    membersAsync.valueOrNull
                        ?.where((m) => !m.isOwner)
                        .toList() ??
                    [];

                if (staff.isEmpty && members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: cs.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No staff members yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  children: [
                    if (members.isNotEmpty) ...[
                      const _SectionHeader(
                        icon: Icons.manage_accounts,
                        title: 'Team Members',
                        subtitle: 'App users with assigned roles',
                      ),
                      ...members.map((m) => _MemberCard(member: m)),
                      const SizedBox(height: 12),
                    ],
                    if (staff.isNotEmpty) ...[
                      const _SectionHeader(
                        icon: Icons.badge,
                        title: 'Staff',
                        subtitle: 'POS staff managed locally',
                      ),
                      ...staff.map(
                        (member) => _StaffCard(
                          staff: member,
                          onAttendance: () => context.push(
                            AppRoutes.staffAttendanceDetail,
                            extra: {
                              'staffId': member.id,
                              'staffName': member.name,
                              'staffEmail': member.email,
                              'staffRole': member.role.displayName,
                            },
                          ),
                          onShiftTiming: () => context.push(AppRoutes.shifts),
                          onPayroll: () => context.push(
                            AppRoutes.staffPayrollDetail,
                            extra: {
                              'staffId': member.id,
                              'staffName': member.name,
                            },
                          ),
                          onCashRegister: () =>
                              context.push(AppRoutes.cashRegister),
                          onPermissions: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PermissionManagerScreen(staff: member),
                            ),
                          ),
                          onToggleActive: () async {
                            await StaffService.toggleStaffActive(
                              member.id,
                              !member.isActive,
                            );
                          },
                          onDelete: () => _confirmDelete(context, ref, member),
                          canUpdate: staffPermissions.canUpdate,
                          canDelete: staffPermissions.canDelete,
                        ),
                      ),
                    ],
                  ],
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

  void _confirmDelete(BuildContext context, WidgetRef ref, StaffModel staff) {
    final permissions = ref.read(routePermissionProvider(AppRoutes.staff));
    if (!permissions.canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to delete staff.'),
        ),
      );
      return;
    }

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
                  SnackBar(
                    content: Text('${staff.name} deleted'),
                    duration: const Duration(seconds: 2),
                  ),
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
  final VoidCallback onAttendance;
  final VoidCallback onShiftTiming;
  final VoidCallback onPayroll;
  final VoidCallback onCashRegister;
  final VoidCallback onPermissions;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final bool canUpdate;
  final bool canDelete;

  const _StaffCard({
    required this.staff,
    required this.onAttendance,
    required this.onShiftTiming,
    required this.onPayroll,
    required this.onCashRegister,
    required this.onPermissions,
    required this.onToggleActive,
    required this.onDelete,
    required this.canUpdate,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: staff.isActive
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
                  child: Text(
                    staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: staff.isActive
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              staff.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: staff.isActive
                                    ? cs.onSurface
                                    : cs.onSurface.withValues(alpha: 0.45),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!staff.isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Inactive',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        staff.role.displayName +
                            (staff.email != null ? '  ·  ${staff.email}' : ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // ⋮ menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'permissions':
                        onPermissions();
                        break;
                      case 'toggle':
                        onToggleActive();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    if (canUpdate)
                      const PopupMenuItem(
                        value: 'permissions',
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Permissions'),
                          ],
                        ),
                      ),
                    if (canUpdate)
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              staff.isActive
                                  ? Icons.person_off_outlined
                                  : Icons.person_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(staff.isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                    if (canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 4),

            // ── 4 Action icons ──────────────────────────────────
            Row(
              children: [
                _ActionBtn(
                  icon: Icons.fact_check_outlined,
                  label: 'Attendance',
                  color: Colors.blue,
                  onTap: onAttendance,
                ),
                _ActionBtn(
                  icon: Icons.schedule_outlined,
                  label: 'Shift',
                  color: Colors.orange,
                  onTap: onShiftTiming,
                ),
                _ActionBtn(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payroll',
                  color: Colors.green,
                  onTap: onPayroll,
                ),
                _ActionBtn(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Cash Reg',
                  color: Colors.purple,
                  onTap: onCashRegister,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Button ─────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section header ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Member card (team members from Users panel) ───────────────

class _MemberCard extends StatelessWidget {
  final StoreMember member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roleLabel = member.roleLabel;
    final roleColor = _roleColor(member.role);
    final isDisabled = member.status == MemberStatus.disabled;
    final isInvited = member.status == MemberStatus.invited;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: roleColor.withValues(alpha: 0.15),
                  child: Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDisabled
                                    ? cs.onSurface.withValues(alpha: 0.4)
                                    : cs.onSurface,
                                decoration: isDisabled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              roleLabel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ),
                          if (isInvited) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PENDING',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        member.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 4),

            // ── 4 Action icons ──────────────────────────────────
            Row(
              children: [
                _ActionBtn(
                  icon: Icons.fact_check_outlined,
                  label: 'Attendance',
                  color: Colors.blue,
                  onTap: () => context.push(
                    AppRoutes.staffAttendanceDetail,
                    extra: {
                      'staffId': member.uid,
                      'staffName': member.displayName,
                      'staffEmail': member.email,
                      'staffRole': roleLabel,
                    },
                  ),
                ),
                _ActionBtn(
                  icon: Icons.schedule_outlined,
                  label: 'Shift',
                  color: Colors.orange,
                  onTap: () => context.push(AppRoutes.shifts),
                ),
                _ActionBtn(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payroll',
                  color: Colors.green,
                  onTap: () => context.push(
                    AppRoutes.staffPayrollDetail,
                    extra: {
                      'staffId': member.uid,
                      'staffName': member.displayName,
                    },
                  ),
                ),
                _ActionBtn(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Cash Reg',
                  color: Colors.purple,
                  onTap: () => context.push(AppRoutes.cashRegister),
                ),
              ],
            ),
          ],
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
        return Colors.grey.shade700;
      case StoreRole.custom:
        return Colors.purple;
    }
  }
}

// ─── My Profile view for PIN-logged staff ─────────────────────────────────────

class _StaffProfileView extends StatefulWidget {
  final StaffModel staff;

  const _StaffProfileView({required this.staff});

  @override
  State<_StaffProfileView> createState() => _StaffProfileViewState();
}

class _StaffProfileViewState extends State<_StaffProfileView> {
  Future<SalarySlip>? _salaryFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _salaryFuture = SalaryService.calculateSalary(
      staffId: widget.staff.id,
      staffName: widget.staff.name,
      month: DateTime(now.year, now.month),
      baseSalary: 15000,
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.staff;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              staff.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                staff.role.displayName,
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Active / Inactive badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: staff.isActive
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                staff.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: staff.isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Info card ──────────────────────────────────────────
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.work_outline,
                      label: 'Staff Role',
                      value: staff.role.displayName,
                    ),
                    if (staff.email != null && staff.email!.isNotEmpty)
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: staff.email!,
                      ),
                    if (staff.phone != null && staff.phone!.isNotEmpty)
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: staff.phone!,
                      ),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Joined On',
                      value:
                          '${staff.createdAt.day}/${staff.createdAt.month}/${staff.createdAt.year}',
                    ),
                    _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Staff ID',
                      value: staff.id,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Payroll card (current month) ───────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Payroll — This Month',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<SalarySlip>(
              future: _salaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Could not load payroll data.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }
                final slip = snapshot.data!;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _PayrollRow(
                          label: 'Days Present',
                          value: '${slip.presentDays} / ${slip.totalDays}',
                          icon: Icons.event_available_outlined,
                          color: Colors.blue,
                        ),
                        const Divider(height: 12),
                        _PayrollRow(
                          label: 'Total Hours',
                          value: '${slip.totalHours.toStringAsFixed(1)} hrs',
                          icon: Icons.access_time_outlined,
                          color: Colors.orange,
                        ),
                        _PayrollRow(
                          label: 'Overtime',
                          value: '${slip.overtimeHours.toStringAsFixed(1)} hrs',
                          icon: Icons.more_time_outlined,
                          color: Colors.purple,
                        ),
                        const Divider(height: 12),
                        _PayrollRow(
                          label: 'Base Salary',
                          value: '\u20B9${slip.baseSalary.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_outlined,
                          color: Colors.green,
                        ),
                        _PayrollRow(
                          label: 'Overtime Pay',
                          value: '\u20B9${slip.overtimePay.toStringAsFixed(0)}',
                          icon: Icons.add_circle_outline,
                          color: Colors.teal,
                        ),
                        if (slip.deductions > 0)
                          _PayrollRow(
                            label: 'Deductions',
                            value:
                                '-\u20B9${slip.deductions.toStringAsFixed(0)}',
                            icon: Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                        if (slip.advances > 0)
                          _PayrollRow(
                            label: 'Advances',
                            value: '-\u20B9${slip.advances.toStringAsFixed(0)}',
                            icon: Icons.money_off_outlined,
                            color: Colors.red,
                          ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Net Salary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '\u20B9${slip.netSalary.toStringAsFixed(0)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MemberProfileView extends StatefulWidget {
  final StoreMember member;

  const _MemberProfileView({required this.member});

  @override
  State<_MemberProfileView> createState() => _MemberProfileViewState();
}

class _MemberProfileViewState extends State<_MemberProfileView> {
  Future<SalarySlip>? _salaryFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _salaryFuture = SalaryService.calculateSalary(
      staffId: widget.member.uid,
      staffName: widget.member.displayName,
      month: DateTime(now.year, now.month),
      baseSalary: 15000,
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                member.displayName.isNotEmpty
                    ? member.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              member.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.roleLabel,
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: member.status == MemberStatus.active
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.status.displayName,
                style: TextStyle(
                  color: member.status == MemberStatus.active
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Info card ──────────────────────────────────────────────────
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.work_outline,
                      label: 'Staff Role',
                      value: member.roleLabel,
                    ),
                    if (member.email.isNotEmpty)
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: member.email,
                      ),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member Since',
                      value: _formatDate(member.joinedAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Payroll card (current month) ───────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Payroll — This Month',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<SalarySlip>(
              future: _salaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Could not load payroll data.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }
                final slip = snapshot.data!;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _PayrollRow(
                          label: 'Days Present',
                          value: '${slip.presentDays} / ${slip.totalDays}',
                          icon: Icons.event_available_outlined,
                          color: Colors.blue,
                        ),
                        const Divider(height: 12),
                        _PayrollRow(
                          label: 'Total Hours',
                          value: '${slip.totalHours.toStringAsFixed(1)} hrs',
                          icon: Icons.access_time_outlined,
                          color: Colors.orange,
                        ),
                        _PayrollRow(
                          label: 'Overtime',
                          value: '${slip.overtimeHours.toStringAsFixed(1)} hrs',
                          icon: Icons.more_time_outlined,
                          color: Colors.purple,
                        ),
                        const Divider(height: 12),
                        _PayrollRow(
                          label: 'Base Salary',
                          value: '\u20B9${slip.baseSalary.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_outlined,
                          color: Colors.green,
                        ),
                        _PayrollRow(
                          label: 'Overtime Pay',
                          value: '\u20B9${slip.overtimePay.toStringAsFixed(0)}',
                          icon: Icons.add_circle_outline,
                          color: Colors.teal,
                        ),
                        if (slip.deductions > 0)
                          _PayrollRow(
                            label: 'Deductions',
                            value:
                                '-\u20B9${slip.deductions.toStringAsFixed(0)}',
                            icon: Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                        if (slip.advances > 0)
                          _PayrollRow(
                            label: 'Advances',
                            value: '-\u20B9${slip.advances.toStringAsFixed(0)}',
                            icon: Icons.money_off_outlined,
                            color: Colors.red,
                          ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Net Salary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '\u20B9${slip.netSalary.toStringAsFixed(0)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─── Per-Staff Payroll Screen ─────────────────────────────────────────────────

class StaffPayrollScreen extends StatefulWidget {
  final String staffId;
  final String staffName;

  const StaffPayrollScreen({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  State<StaffPayrollScreen> createState() => _StaffPayrollScreenState();
}

class _StaffPayrollScreenState extends State<StaffPayrollScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Future<SalarySlip>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = SalaryService.calculateSalary(
        staffId: widget.staffId,
        staffName: widget.staffName,
        month: _month,
        baseSalary: 15000,
      );
    });
  }

  void _prevMonth() {
    _month = DateTime(_month.year, _month.month - 1);
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    _month = DateTime(_month.year, _month.month + 1);
    _load();
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.staffName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Payroll',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: isCurrentMonth
                        ? cs.onSurface.withValues(alpha: 0.3)
                        : null,
                  ),
                  onPressed: isCurrentMonth ? null : _nextMonth,
                ),
              ],
            ),
          ),

          // Payroll content
          Expanded(
            child: FutureBuilder<SalarySlip>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: cs.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No payroll data available',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                final slip = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Net salary hero
                      Card(
                        elevation: 0,
                        color: Colors.green.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Colors.green,
                            width: 0.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 24,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Net Salary',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '\u20B9${slip.netSalary.toStringAsFixed(0)}',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.green,
                                        ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${slip.presentDays} / ${slip.totalDays} days',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '${slip.totalHours.toStringAsFixed(1)} hrs worked',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Breakdown card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: cs.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PayrollRow(
                                label: 'Working Days',
                                value: '${slip.totalDays}',
                                icon: Icons.calendar_month_outlined,
                                color: Colors.blueGrey,
                              ),
                              _PayrollRow(
                                label: 'Days Present',
                                value: '${slip.presentDays}',
                                icon: Icons.event_available_outlined,
                                color: Colors.blue,
                              ),
                              _PayrollRow(
                                label: 'Total Hours',
                                value:
                                    '${slip.totalHours.toStringAsFixed(1)} hrs',
                                icon: Icons.access_time_outlined,
                                color: Colors.orange,
                              ),
                              _PayrollRow(
                                label: 'Overtime Hours',
                                value:
                                    '${slip.overtimeHours.toStringAsFixed(1)} hrs',
                                icon: Icons.more_time_outlined,
                                color: Colors.purple,
                              ),
                              const Divider(height: 20),
                              Text(
                                'Earnings & Deductions',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PayrollRow(
                                label: 'Base Salary',
                                value:
                                    '\u20B9${slip.baseSalary.toStringAsFixed(0)}',
                                icon: Icons.account_balance_wallet_outlined,
                                color: Colors.green,
                              ),
                              _PayrollRow(
                                label: 'Overtime Pay',
                                value:
                                    '\u20B9${slip.overtimePay.toStringAsFixed(0)}',
                                icon: Icons.add_circle_outline,
                                color: Colors.teal,
                              ),
                              if (slip.deductions > 0)
                                _PayrollRow(
                                  label: 'Deductions',
                                  value:
                                      '-\u20B9${slip.deductions.toStringAsFixed(0)}',
                                  icon: Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                              if (slip.advances > 0)
                                _PayrollRow(
                                  label: 'Advances',
                                  value:
                                      '-\u20B9${slip.advances.toStringAsFixed(0)}',
                                  icon: Icons.money_off_outlined,
                                  color: Colors.red,
                                ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Net Salary',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '\u20B9${slip.netSalary.toStringAsFixed(0)}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.green,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PayrollRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: colorScheme.primary),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}
