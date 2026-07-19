/// Active orders screen — shows all current orders
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/orders/providers/order_provider.dart';
import 'package:tulasihotels/models/order_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(filteredActiveOrdersProvider);
    final orderPermissions = ref.watch(routePermissionProvider(AppRoutes.orders));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Orders'),
        actions: [
          PopupMenuButton<OrderType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by type',
            onSelected: (type) {
              ref.read(orderTypeFilterProvider.notifier).state = type;
            },
            itemBuilder: (context) => [
              const PopupMenuItem<OrderType?>(
                child: Text('All Orders'),
              ),
              ...OrderType.values.map(
                (type) => PopupMenuItem(
                  value: type,
                  child: Text('${type.emoji} ${type.displayName}'),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Order',
            onPressed: orderPermissions.canCreate
                ? () => context.push('${AppRoutes.orders}/new')
                : null,
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No active orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Orders will appear here when placed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) =>
                _OrderCard(order: orders[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

/// Order card in the list
class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  Color _statusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.placed => Colors.blue,
      OrderStatus.preparing => Colors.orange,
      OrderStatus.ready => Colors.green,
      OrderStatus.served => Colors.teal,
      OrderStatus.billed => Colors.grey,
      OrderStatus.cancelled => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(order.status);
    final elapsed = order.elapsed;
    final elapsedStr = elapsed.inMinutes < 60
        ? '${elapsed.inMinutes}m ago'
        : '${elapsed.inHours}h ${elapsed.inMinutes % 60}m ago';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('${AppRoutes.orders}/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Order number
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${order.orderNumber}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Table / order type
                  Text(
                    order.tableName ?? order.orderType.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Time elapsed
                  Text(elapsedStr, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Items summary
              Text(
                order.items.map((i) => '${i.quantity}× ${i.name}').join(', '),
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Footer
              Row(
                children: [
                  Text(
                    '${order.itemCount} items',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '?${order.total.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
