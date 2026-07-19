/// Table management screen — floor-plan grid view
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/core/design/design_system.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/subscription/providers/usage_limits_provider.dart';
import 'package:tulasihotels/features/subscription/providers/subscription_provider.dart';
import 'package:tulasihotels/features/subscription/widgets/plan_usage_bar.dart';
import 'package:tulasihotels/features/tables/providers/table_provider.dart';
import 'package:tulasihotels/features/tables/services/table_service.dart';
import 'package:tulasihotels/features/tables/widgets/add_table_dialog.dart';
import 'package:tulasihotels/models/table_model.dart';
import 'package:tulasihotels/router/app_router.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(filteredTablesProvider);
    final floors = ref.watch(availableFloorsProvider);
    final selectedFloor = ref.watch(selectedFloorProvider);
    final statusSummary = ref.watch(tableStatusSummaryProvider);
    final limits = ref.watch(currentLimitsProvider);
    final config = ref.watch(planConfigProvider);
    final tablePermissions = ref.watch(routePermissionProvider(AppRoutes.tables));
    final canCreateTables = tablePermissions.canCreate;
    final tableMax = config.maxTables ?? 999999;
    final atTableLimit = tableMax < 999999 && limits.tablesCount >= tableMax;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables'),
        actions: [
          if (floors.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<int?>(
                value: selectedFloor,
                hint: const Text('All Floors'),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<int?>(child: Text('All Floors')),
                  ...floors.map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f == 0 ? 'Ground Floor' : 'Floor $f'),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    ref.read(selectedFloorProvider.notifier).state = value,
              ),
            ),
          IconButton(
            icon: Icon(atTableLimit ? Icons.lock_outline : Icons.add),
            tooltip: atTableLimit ? 'Table limit reached — upgrade to add more' : 'Add Table',
            onPressed: atTableLimit || !canCreateTables ? null : _showAddTableDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          PlanUsageBar(
            label: 'Tables',
            getCurrent: (l) => l.tablesCount,
            getLimit: (c) => c.tablesLimitFirestore,
          ),
          _StatusBar(summary: statusSummary),
          Expanded(
            child: tablesAsync.when(
              data: (tables) {
                if (tables.isEmpty) {
                  return _EmptyState(
                    onAddTables: atTableLimit || !canCreateTables
                        ? null
                        : _showAddTableDialog,
                  );
                }
                return _TableGrid(tables: tables);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTableDialog() async {
    final permissions = ref.read(routePermissionProvider(AppRoutes.tables));
    if (!permissions.canCreate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to create tables.'),
          ),
        );
      }
      return;
    }

    // Button is already disabled when atTableLimit — no server call needed here
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => const AddTableDialog(),
    );
  }
}

/// Status summary bar showing table counts by status
class _StatusBar extends StatelessWidget {
  final Map<TableStatus, int> summary;

  const _StatusBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          _StatusChip(
            label: 'Available',
            count: summary[TableStatus.available] ?? 0,
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          _StatusChip(
            label: 'Occupied',
            count: summary[TableStatus.occupied] ?? 0,
            color: Colors.red,
          ),
          const SizedBox(width: 12),
          _StatusChip(
            label: 'Reserved',
            count: summary[TableStatus.reserved] ?? 0,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          _StatusChip(
            label: 'Billing',
            count: summary[TableStatus.billing] ?? 0,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Grid of table cards with color-coded status
class _TableGrid extends StatelessWidget {
  final List<TableModel> tables;

  const _TableGrid({required this.tables});

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final crossAxisCount = switch (deviceType) {
      DeviceType.mobile => 2,
      DeviceType.tablet => 3,
      DeviceType.desktop => 4,
      DeviceType.desktopLarge => 6,
    };

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) => _TableCard(table: tables[index]),
    );
  }
}

/// Individual table card
class _TableCard extends ConsumerWidget {
  final TableModel table;

  const _TableCard({required this.table});

  Color _statusColor(TableStatus status) {
    return switch (status) {
      TableStatus.available => Colors.green,
      TableStatus.occupied => Colors.red,
      TableStatus.reserved => Colors.orange,
      TableStatus.billing => Colors.blue,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _statusColor(table.status);
    final tablePermissions = ref.watch(routePermissionProvider(AppRoutes.tables));
    final canUpdateTables = tablePermissions.canUpdate;
    final canDeleteTables = tablePermissions.canDelete;
    final canOpenOptions = canUpdateTables || canDeleteTables;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onTableTap(context),
        onLongPress: canOpenOptions ? () => _showTableOptions(context, ref) : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.08),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Table number
              Text(
                table.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Capacity
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people, size: 14, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(
                    '${table.capacity}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  table.status.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTableTap(BuildContext context) {
    if (table.isFree) {
      // Open new order for this table
      context.push('${AppRoutes.orders}/new?tableId=${table.id}&tableName=${Uri.encodeComponent(table.displayName)}');
    } else if (table.hasActiveOrder) {
      // View existing order — pass tableId so "not found" state can recover
      context.push(
        '${AppRoutes.orders}/${table.currentOrderId}?tableId=${table.id}',
      );
    } else {
      // Table marked occupied/reserved but has no linked order (stale state) —
      // let the user fix it directly from the grid
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${table.displayName} has no active order'),
          content: const Text(
            'This table is marked as occupied but has no linked order.\n'
            'Would you like to start a new order or mark it as available?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                TableService.updateTableStatus(
                  table.id,
                  TableStatus.available,
                );
              },
              child: const Text('Mark Available'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push(
                  '${AppRoutes.orders}/new?tableId=${table.id}'
                  '&tableName=${Uri.encodeComponent(table.displayName)}',
                );
              },
              child: const Text('New Order'),
            ),
          ],
        ),
      );
    }
  }

  void _showTableOptions(BuildContext context, WidgetRef ref) {
    final tablePermissions = ref.read(routePermissionProvider(AppRoutes.tables));
    final canUpdateTables = tablePermissions.canUpdate;
    final canDeleteTables = tablePermissions.canDelete;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canUpdateTables)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Table'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, ref);
                },
              ),
            if (canUpdateTables && table.status == TableStatus.available)
              ListTile(
                leading: const Icon(Icons.event_seat),
                title: const Text('Mark Reserved'),
                onTap: () {
                  Navigator.pop(context);
                  TableService.updateTableStatus(
                    table.id,
                    TableStatus.reserved,
                  );
                },
              ),
            if (canUpdateTables && table.status == TableStatus.reserved)
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Mark Available'),
                onTap: () {
                  Navigator.pop(context);
                  TableService.updateTableStatus(
                    table.id,
                    TableStatus.available,
                  );
                },
              ),
            if (canUpdateTables)
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Assign Server'),
                onTap: () {
                  Navigator.pop(context);
                  _showAssignServerDialog(context);
                },
              ),
            if (canDeleteTables && table.status == TableStatus.available)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Table',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final permissions = ref.read(routePermissionProvider(AppRoutes.tables));
    if (!permissions.canUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to update tables.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddTableDialog(editTable: table),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final permissions = ref.read(routePermissionProvider(AppRoutes.tables));
    if (!permissions.canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to delete tables.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Table?'),
        content: Text('Delete ${table.displayName}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              TableService.deleteTable(table.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAssignServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final staffAsync = ref.watch(activeStaffStreamProvider);
          return AlertDialog(
            title: Text('Assign Server to ${table.displayName}'),
            content: SizedBox(
              width: 300,
              child: staffAsync.when(
                data: (staffList) {
                  if (staffList.isEmpty) {
                    return const Text('No active staff available');
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: staffList.map((staff) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(staff.name),
                      subtitle: Text(staff.role.name),
                      selected: table.assignedServerId == staff.id,
                      onTap: () {
                        Navigator.pop(ctx);
                        TableService.assignServer(
                          table.id,
                          staff.id,
                          staff.name,
                        );
                      },
                    )).toList(),
                  );
                },
                loading: () => const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const Text('Could not load staff'),
              ),
            ),
            actions: [
              if (table.assignedServerId != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    TableService.assignServer(table.id, '', '');
                  },
                  child: const Text('Unassign'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Empty state when no tables exist
class _EmptyState extends StatelessWidget {
  final VoidCallback? onAddTables;

  const _EmptyState({required this.onAddTables});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tables yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add tables to start managing your restaurant floor',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddTables,
            icon: const Icon(Icons.add),
            label: const Text('Add Tables'),
          ),
        ],
      ),
    );
  }
}
