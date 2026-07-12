/// Order detail screen — view/manage a single order
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/orders/services/order_service.dart';
import 'package:tulasihotels/features/tables/services/table_service.dart';
import 'package:tulasihotels/models/order_model.dart';
import 'package:tulasihotels/models/table_model.dart';

/// Provider that streams a single order by ID.
/// Uses a direct document stream so it works offline and shows closed orders.
final orderDetailProvider = StreamProvider.autoDispose
    .family<OrderModel?, String>((ref, orderId) {
      return OrderService.streamOrderById(orderId);
    });

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  /// When opened from the tables screen, this lets the "not found" state
  /// offer to reset the stale table status.
  final String? tableId;

  const OrderDetailScreen({super.key, required this.orderId, this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final theme = Theme.of(context);

    return orderAsync.when(
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/orders');
                  }
                },
              ),
              title: const Text('Order'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 56, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Order not found or already closed',
                      textAlign: TextAlign.center,
                    ),
                    if (tableId != null) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Start New Order for Table'),
                        onPressed: () {
                          // Reset stale occupied status then open new order
                          TableService.updateTableStatus(
                            tableId!,
                            TableStatus.available,
                          );
                          context.replace(
                            '/orders/new?tableId=$tableId',
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          TableService.updateTableStatus(
                            tableId!,
                            TableStatus.available,
                          );
                          if (context.canPop()) context.pop();
                        },
                        child: const Text('Mark Table as Available'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/orders');
                }
              },
            ),
            title: Text('Order #${order.orderNumber}'),
            actions: [
              if (order.isActive)
                PopupMenuButton<String>(
                  onSelected: (action) => _handleAction(context, action, order),
                  itemBuilder: (context) => [
                    if (order.status != OrderStatus.served)
                      const PopupMenuItem(
                        value: 'add_items',
                        child: Text('Add Items'),
                      ),
                    if (order.allItemsServed)
                      const PopupMenuItem(
                        value: 'generate_bill',
                        child: Text('Generate Bill'),
                      ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Text(
                        'Cancel Order',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow('Table', order.tableName ?? 'N/A'),
                        _InfoRow('Type', order.orderType.displayName),
                        _InfoRow('Status', order.status.displayName),
                        if (order.waiterName != null)
                          _InfoRow('Waiter', order.waiterName!),
                        _InfoRow('Placed', _formatTime(order.createdAt)),
                        if (order.notes != null && order.notes!.isNotEmpty)
                          _InfoRow('Notes', order.notes!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Items list
                Text(
                  'Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                ...List.generate(order.items.length, (index) {
                  final item = order.items[index];
                  return _OrderItemCard(
                    item: item,
                    index: index,
                    orderId: orderId,
                    isActive: order.isActive,
                  );
                }),

                const SizedBox(height: 16),

                // Total
                Card(
                  color: theme.primaryColor.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '?${order.total.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                if (order.isActive) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (order.status != OrderStatus.served &&
                          (order.status == OrderStatus.ready ||
                              order.allItemsReady))
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              OrderService.markAllItemsServed(orderId);
                            },
                            icon: const Icon(Icons.room_service),
                            label: const Text('Mark Served'),
                          ),
                        ),
                      if (order.allItemsServed ||
                          order.status == OrderStatus.served) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                _handleAction(context, 'generate_bill', order),
                            icon: const Icon(Icons.receipt),
                            label: const Text('Generate Bill'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _handleAction(BuildContext context, String action, OrderModel order) {
    switch (action) {
      case 'add_items':
        // TODO: Navigate to add items screen
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Add items coming soon')));
        break;
      case 'generate_bill':
        context.push('/orders/${order.id}/bill');
        break;
      case 'cancel':
        _confirmCancel(context, order);
        break;
    }
  }

  void _confirmCancel(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: Text(
          'Cancel order #${order.orderNumber}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              OrderService.cancelOrder(orderId);
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel Order',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Info row in the order detail card
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Individual order item card with status controls
class _OrderItemCard extends ConsumerWidget {
  final OrderItem item;
  final int index;
  final String orderId;
  final bool isActive;

  const _OrderItemCard({
    required this.item,
    required this.index,
    required this.orderId,
    required this.isActive,
  });

  Color _itemStatusColor(OrderItemStatus status) {
    return switch (status) {
      OrderItemStatus.pending => Colors.blue,
      OrderItemStatus.preparing => Colors.orange,
      OrderItemStatus.ready => Colors.green,
      OrderItemStatus.served => Colors.teal,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _itemStatusColor(item.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          '${item.quantity}× ${item.name}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('?${item.total.toStringAsFixed(0)} • KOT #${item.kotNumber}'),
            if (item.itemNotes != null)
              Text(
                item.itemNotes!,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.orange[700],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: isActive
            ? _StatusDropdown(
                status: item.status,
                onChanged: (newStatus) {
                  OrderService.updateItemStatus(orderId, index, newStatus);
                },
              )
            : Chip(
                label: Text(item.status.displayName),
                backgroundColor: color.withValues(alpha: 0.15),
                labelStyle: TextStyle(color: color, fontSize: 11),
                visualDensity: VisualDensity.compact,
              ),
      ),
    );
  }
}

/// Dropdown for changing item status
class _StatusDropdown extends StatelessWidget {
  final OrderItemStatus status;
  final ValueChanged<OrderItemStatus> onChanged;

  const _StatusDropdown({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<OrderItemStatus>(
      value: status,
      underline: const SizedBox(),
      isDense: true,
      items: OrderItemStatus.values
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s.displayName, style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
