/// Menu item card for customer-facing menu
library;

import 'package:flutter/material.dart';
import 'package:tulasihotels/models/product_model.dart';

class MenuItemCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const MenuItemCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Veg/Non-veg indicator
              if (product.dietaryTag != DietaryTag.none)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(product.dietaryTag.emoji, style: const TextStyle(fontSize: 18)),
                ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (product.descriptionEn != null)
                      Text(
                        product.descriptionEn!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (product.spiceLevel != SpiceLevel.na)
                          Text(product.spiceLevel.emoji,
                              style: const TextStyle(fontSize: 14)),
                        if (product.isSpecial)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Special',
                                style: TextStyle(fontSize: 10)),
                          ),
                        if (product.allergens.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.warning_amber,
                                size: 14, color: Colors.orange.shade700),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (!product.isAvailable)
                    Text('Unavailable',
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
