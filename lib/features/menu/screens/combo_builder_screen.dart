/// Combo builder screen — create and manage combo meals
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/menu/providers/combo_provider.dart';
import 'package:tulasihotels/features/menu/services/combo_service.dart';
import 'package:tulasihotels/features/products/providers/products_provider.dart';
import 'package:tulasihotels/models/combo_model.dart';
import 'package:tulasihotels/models/product_model.dart';

class ComboBuilderScreen extends ConsumerStatefulWidget {
  const ComboBuilderScreen({super.key});

  @override
  ConsumerState<ComboBuilderScreen> createState() => _ComboBuilderScreenState();
}

class _ComboBuilderScreenState extends ConsumerState<ComboBuilderScreen> {
  @override
  Widget build(BuildContext context) {
    final combosAsync = ref.watch(combosStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Combo Meals'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComboForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Combo'),
      ),
      body: combosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (combos) {
          if (combos.isEmpty) {
            return const Center(
              child: Text('No combos yet. Create your first combo meal!'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: combos.length,
            itemBuilder: (context, index) {
              final combo = combos[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(combo.dietaryTag.emoji.isNotEmpty
                        ? combo.dietaryTag.emoji
                        : '🍽️'),
                  ),
                  title: Text(combo.name),
                  subtitle: Text(
                    '${combo.items.length} items • ₹${combo.price.toStringAsFixed(0)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: combo.isAvailable,
                        onChanged: (val) =>
                            ComboService.toggleAvailability(combo.id, val),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ComboService.deleteCombo(combo.id),
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

  void _showComboForm(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final selectedItems = <ProductModel>[];
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final productsAsync = ref.watch(productsProvider);
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('New Combo',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Combo Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Combo Price (₹)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Selected items chips
                      if (selectedItems.isNotEmpty) ...[
                        Text('Selected Items (${selectedItems.length})',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: selectedItems.map((p) {
                            return Chip(
                              label: Text(p.name),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setModalState(() => selectedItems.remove(p));
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Search menu items
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search menu items...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setModalState(() => searchQuery = value.toLowerCase());
                        },
                      ),
                      const SizedBox(height: 8),

                      // Menu items list
                      Expanded(
                        child: productsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                          data: (products) {
                            var filtered = products.where((p) => p.isAvailable).toList();
                            if (searchQuery.isNotEmpty) {
                              filtered = filtered.where((p) =>
                                  p.name.toLowerCase().contains(searchQuery)).toList();
                            }
                            if (filtered.isEmpty) {
                              return const Center(child: Text('No items found'));
                            }
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final product = filtered[index];
                                final isSelected = selectedItems.any((p) => p.id == product.id);
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      product.dietaryTag.emoji.isNotEmpty
                                          ? product.dietaryTag.emoji
                                          : '🍽️',
                                    ),
                                  ),
                                  title: Text(product.name),
                                  subtitle: Text('₹${product.price.toStringAsFixed(0)}'),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : const Icon(Icons.add_circle_outline),
                                  onTap: () {
                                    setModalState(() {
                                      if (isSelected) {
                                        selectedItems.removeWhere((p) => p.id == product.id);
                                      } else {
                                        selectedItems.add(product);
                                      }
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          if (nameController.text.isEmpty) return;
                          final combo = ComboModel(
                            id: generateSafeId('combo'),
                            name: nameController.text,
                            price: double.tryParse(priceController.text) ?? 0,
                            items: selectedItems.map((p) => ComboItem(
                              productId: p.id,
                              name: p.name,
                            )).toList(),
                            createdAt: DateTime.now(),
                          );
                          ComboService.createCombo(combo);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Create Combo'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
