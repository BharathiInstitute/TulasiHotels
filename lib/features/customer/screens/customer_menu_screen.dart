/// Customer-facing public menu screen (no auth required)
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tulasihotels/models/product_model.dart';

class CustomerMenuScreen extends StatelessWidget {
  final String hotelId;
  const CustomerMenuScreen({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users/$hotelId/products')
            .where('isAvailable', isEqualTo: true)
            .orderBy('category')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Menu unavailable'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No items available'));
          }

          // Group by category
          final Map<String, List<ProductModel>> grouped = {};
          for (final doc in docs) {
            final product = ProductModel.fromFirestore(doc);
            final cat = (product.category?.isNotEmpty ?? false) ? product.category! : 'Other';
            grouped.putIfAbsent(cat, () => []).add(product);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      entry.key,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...entry.value.map((product) => _MenuItemCard(product: product)),
                  const Divider(),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final ProductModel product;
  const _MenuItemCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Dietary indicator
            if (product.dietaryTag != DietaryTag.none)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: product.dietaryTag == DietaryTag.veg
                        ? Colors.green
                        : Colors.red,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: product.dietaryTag == DietaryTag.veg
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (product.descriptionEn != null && product.descriptionEn!.isNotEmpty)
                    Text(
                      product.descriptionEn!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (product.spiceLevel != SpiceLevel.na)
                    Text(
                      product.spiceLevel.emoji * (product.spiceLevel.index + 1),
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (product.allergens.isNotEmpty)
                    Text(
                      'Allergens: ${product.allergens.join(", ")}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.isSpecial)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '⭐ Special',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
