/// Daily specials management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/products/providers/products_provider.dart';
import 'package:tulasihotels/models/product_model.dart';

class DailySpecialsScreen extends ConsumerWidget {
  const DailySpecialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Specials ⭐'),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      product.dietaryTag.emoji.isNotEmpty
                          ? product.dietaryTag.emoji
                          : '🍽️',
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '₹${product.price.toStringAsFixed(0)} • ${product.category ?? "No category"}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: product.isSpecial,
                        onChanged: (val) {
                          _toggleSpecial(ref, product, val);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteProduct(context, ref, product),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleSpecial(WidgetRef ref, ProductModel product, bool isSpecial) {
    final updated = product.copyWith(isSpecial: isSpecial);
    ref.read(productsServiceProvider).updateProduct(updated);
  }

  void _deleteProduct(BuildContext context, WidgetRef ref, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(productsServiceProvider).deleteProduct(product.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
