/// Kitchen Display System (KDS) — theme-aware kitchen view
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/orders/providers/order_provider.dart';
import 'package:tulasihotels/features/orders/services/order_service.dart';
import 'package:tulasihotels/models/order_model.dart';

/// Configurable threshold for overdue orders (minutes)
const _overdueMinutes = 15;

class KitchenDisplayScreen extends ConsumerStatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  ConsumerState<KitchenDisplayScreen> createState() =>
      _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends ConsumerState<KitchenDisplayScreen> {
  /// Timer to refresh elapsed times every 30 seconds
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(kitchenOrdersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.kitchen, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Kitchen Display'),
          ],
        ),
        actions: [
          // Order count
          ordersAsync.whenOrNull(
                data: (orders) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${orders.length} orders',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green[400]),
                  const SizedBox(height: 16),
                  Text(
                    'All caught up!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pending kitchen orders',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: orders.length,
            itemBuilder: (context, index) => _KitchenOrderCard(
              order: orders[index],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ),
    );
  }
}

/// Kitchen order card — one per order
class _KitchenOrderCard extends StatelessWidget {
  final OrderModel order;

  const _KitchenOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final elapsed = order.elapsed;
    final isOverdue = elapsed.inMinutes >= _overdueMinutes;
    final headerColor = _headerColor(order.status, isOverdue);
    final elapsedStr = elapsed.inMinutes < 60
        ? '${elapsed.inMinutes}m'
        : '${elapsed.inHours}h ${elapsed.inMinutes % 60}m';

    final cardBorderColor = order.isRush
        ? Colors.red
        : (order.isVip ? Colors.amber[700]! : (isOverdue ? Colors.red : headerColor));
    final cardBorderWidth = (order.isRush || order.isVip || isOverdue) ? 2.5 : 1.0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: cardBorderColor,
          width: cardBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                if (order.isRush)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('🔥', style: TextStyle(fontSize: 16)),
                  ),
                if (order.isVip)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('👑', style: TextStyle(fontSize: 16)),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.tableName ?? '#${order.orderNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '#${order.orderNumber}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    elapsedStr,
                    style: TextStyle(
                      color: isOverdue ? Colors.red[200] : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return _KitchenItemRow(
                  item: item,
                  onTap: () {
                    final nextStatus = switch (item.status) {
                      OrderItemStatus.pending => OrderItemStatus.preparing,
                      OrderItemStatus.preparing => OrderItemStatus.ready,
                      _ => item.status,
                    };
                    if (nextStatus != item.status) {
                      OrderService.updateItemStatus(
                        order.id,
                        index,
                        nextStatus,
                      );
                    }
                  },
                );
              },
            ),
          ),

          // Footer actions
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                if (order.notes != null && order.notes!.isNotEmpty)
                  Expanded(
                    child: Text(
                      order.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.tertiary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  height: 30,
                  child: FilledButton(
                    onPressed: () => OrderService.markAllItemsReady(order.id),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: Colors.green[700],
                    ),
                    child: const Text('All Ready', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _headerColor(OrderStatus status, bool isOverdue) {
    if (isOverdue) return Colors.red[800]!;
    return switch (status) {
      OrderStatus.placed => Colors.green[700]!,
      OrderStatus.preparing => Colors.orange[800]!,
      _ => Colors.grey[700]!,
    };
  }
}

/// Individual item row in the kitchen card
class _KitchenItemRow extends StatelessWidget {
  final OrderItem item;
  final VoidCallback onTap;

  const _KitchenItemRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = switch (item.status) {
      OrderItemStatus.pending => colorScheme.onSurface,
      OrderItemStatus.preparing => Colors.orange[700]!,
      OrderItemStatus.ready => Colors.green[600]!,
      OrderItemStatus.served => colorScheme.onSurfaceVariant,
    };

    final isComplete =
        item.status == OrderItemStatus.ready ||
        item.status == OrderItemStatus.served;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            // Quantity
            Container(
              width: 24,
              alignment: Alignment.center,
              child: Text(
                '${item.quantity}×',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Item name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      decoration:
                          isComplete ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.itemNotes != null)
                    Text(
                      item.itemNotes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.tertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            // Status icon
            Icon(
              isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
