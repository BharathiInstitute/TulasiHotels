/// Customer-facing order status tracking screen (no auth required)
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tulasihotels/models/order_model.dart';

class OrderStatusScreen extends StatelessWidget {
  final String hotelId;
  final String orderId;

  const OrderStatusScreen({
    super.key,
    required this.hotelId,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Status'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .doc('users/$hotelId/orders/$orderId')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found'));
          }

          final order = OrderModel.fromFirestore(snapshot.data!);
          final steps = _statusSteps(order.status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Order number
                Text(
                  'Order #${order.orderNumber}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (order.tableName != null)
                  Text('Table: ${order.tableName}',
                      style: theme.textTheme.bodyLarge),
                const SizedBox(height: 32),

                // Status pipeline
                ...steps.map((step) {
                  return _StatusStep(
                    label: step['label'] as String,
                    icon: step['icon'] as IconData,
                    isCompleted: step['completed'] as bool,
                    isActive: step['active'] as bool,
                  );
                }),

                const SizedBox(height: 32),

                // Order items
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Items', style: theme.textTheme.titleMedium),
                        const Divider(),
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item.quantity}x ${item.name}'),
                                  Text(
                                      '₹${(item.price * item.quantity).toStringAsFixed(0)}'),
                                ],
                              ),
                            )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '₹${order.total.toStringAsFixed(0)}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }

  List<Map<String, Object>> _statusSteps(OrderStatus status) {
    final statusIndex = status.index;
    return [
      {
        'label': 'Received',
        'icon': Icons.receipt_long,
        'completed': statusIndex >= OrderStatus.placed.index,
        'active': status == OrderStatus.placed,
      },
      {
        'label': 'Preparing',
        'icon': Icons.restaurant,
        'completed': statusIndex >= OrderStatus.preparing.index,
        'active': status == OrderStatus.preparing,
      },
      {
        'label': 'Ready',
        'icon': Icons.check_circle,
        'completed': statusIndex >= OrderStatus.ready.index,
        'active': status == OrderStatus.ready,
      },
      {
        'label': 'Served',
        'icon': Icons.dining,
        'completed': statusIndex >= OrderStatus.served.index,
        'active': status == OrderStatus.served,
      },
    ];
  }
}

class _StatusStep extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;

  const _StatusStep({
    required this.label,
    required this.icon,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCompleted
        ? Colors.green
        : isActive
            ? theme.colorScheme.primary
            : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isCompleted || isActive ? null : Colors.grey,
              ),
            ),
          ),
          if (isCompleted) const Icon(Icons.check, color: Colors.green),
        ],
      ),
    );
  }
}
