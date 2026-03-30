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
                child: SwitchListTile(
                  secondary: CircleAvatar(
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
                  value: product.isSpecial,
                  onChanged: (val) {
                    // Update via Firestore
                    _toggleSpecial(ref, product, val);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleSpecial(WidgetRef ref, ProductModel product, bool isSpecial) {
    // Uses product service to update
    // This would call ProductService.updateProduct
    // but for now we just mark the field
  }
}
