/// Combo card widget for displaying combo deals in order screen
library;

import 'package:flutter/material.dart';
import 'package:tulasihotels/models/product_model.dart';

class ComboCard extends StatelessWidget {
  final ProductModel combo;
  final List<ProductModel> comboItems;
  final VoidCallback? onAdd;

  const ComboCard({
    super.key,
    required this.combo,
    required this.comboItems,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savings = comboItems.fold(0.0, (sum, p) => sum + p.price) - combo.price;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  combo.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (savings > 0)
                  Text(
                    'Save ₹${savings.toStringAsFixed(0)}!',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // Items list
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...comboItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.name)),
                          Text('₹${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey)),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${combo.price.toStringAsFixed(0)}',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (onAdd != null)
                      FilledButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
