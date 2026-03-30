/// Combo builder screen — create and manage combo meals
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/menu/providers/combo_provider.dart';
import 'package:tulasihotels/features/menu/services/combo_service.dart';
import 'package:tulasihotels/models/combo_model.dart';

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
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
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (nameController.text.isEmpty) return;
                  final combo = ComboModel(
                    id: generateSafeId('combo'),
                    name: nameController.text,
                    price:
                        double.tryParse(priceController.text) ?? 0,
                    items: const [],
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
  }
}
