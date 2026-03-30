/// Ingredients management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/inventory/providers/inventory_provider.dart';
import 'package:tulasihotels/features/inventory/services/ingredient_service.dart';
import 'package:tulasihotels/models/ingredient_model.dart';

class IngredientsScreen extends ConsumerWidget {
  const IngredientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsAsync = ref.watch(ingredientsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ingredients')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIngredientForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Ingredient'),
      ),
      body: ingredientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ingredients) {
          if (ingredients.isEmpty) {
            return const Center(child: Text('No ingredients yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final ing = ingredients[index];
              return Card(
                color: ing.isLowStock
                    ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(ing.unit.shortName),
                  ),
                  title: Text(ing.name),
                  subtitle: Text(
                    'Stock: ${ing.currentStock.toStringAsFixed(1)} ${ing.unit.shortName}'
                    '${ing.isLowStock ? " ⚠️ LOW" : ""}',
                  ),
                  trailing: Text(
                    '₹${ing.costPerUnit.toStringAsFixed(1)}/${ing.unit.shortName}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showIngredientForm(BuildContext context) {
    final nameCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    var unit = IngredientUnit.kg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add Ingredient',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Current Stock',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<IngredientUnit>(
                          initialValue: unit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                          ),
                          items: IngredientUnit.values.map((u) {
                            return DropdownMenuItem(
                              value: u,
                              child: Text(u.displayName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => unit = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (nameCtrl.text.isEmpty) return;
                      final ingredient = IngredientModel(
                        id: generateSafeId('ing'),
                        name: nameCtrl.text.trim(),
                        unit: unit,
                        currentStock:
                            double.tryParse(stockCtrl.text) ?? 0,
                        createdAt: DateTime.now(),
                      );
                      IngredientService.createIngredient(ingredient);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Add'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
