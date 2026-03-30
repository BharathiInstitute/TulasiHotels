/// Reorder button — allows quickly re-creating a past order
library;

import 'package:flutter/material.dart';
import 'package:tulasihotels/models/order_model.dart';

class ReorderButton extends StatelessWidget {
  final OrderModel previousOrder;
  final void Function(OrderModel order) onReorder;

  const ReorderButton({
    super.key,
    required this.previousOrder,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => _confirmReorder(context),
      icon: const Icon(Icons.replay),
      label: Text('Reorder #${previousOrder.orderNumber}'),
    );
  }

  void _confirmReorder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reorder?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create a new order with ${previousOrder.items.length} items:'),
            const SizedBox(height: 8),
            ...previousOrder.items.map((item) => Text(
                  '• ${item.quantity}x ${item.name}',
                  style: const TextStyle(fontSize: 13),
                )),
            const SizedBox(height: 8),
            Text(
              'Total: ₹${previousOrder.total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onReorder(previousOrder);
            },
            child: const Text('Reorder'),
          ),
        ],
      ),
    );
  }
}
