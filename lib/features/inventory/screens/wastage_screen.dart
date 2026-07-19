/// Wastage logging screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/inventory/providers/inventory_provider.dart';
import 'package:tulasihotels/models/wastage_model.dart';
import 'package:tulasihotels/features/inventory/services/wastage_service.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/router/app_router.dart';

class WastageScreen extends ConsumerStatefulWidget {
  const WastageScreen({super.key});

  @override
  ConsumerState<WastageScreen> createState() => _WastageScreenState();
}

class _WastageScreenState extends ConsumerState<WastageScreen> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  WastageReason _reason = WastageReason.expired;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wastageAsync = ref.watch(wastageProvider);
    final wastagePermissions = ref.watch(routePermissionProvider(AppRoutes.wastage));

    return Scaffold(
      appBar: AppBar(title: const Text('Wastage Log')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: wastagePermissions.canCreate ? _showWastageForm : null,
        icon: const Icon(Icons.add),
        label: const Text('Log Wastage'),
      ),
      body: wastageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (wastages) {
          if (wastages.isEmpty) {
            return const Center(child: Text('No wastage recorded'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: wastages.length,
            itemBuilder: (context, index) {
              final w = wastages[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: Text(w.reason.emoji),
                  ),
                  title: Text(w.ingredientName),
                  subtitle: Text(
                    '${w.reason.displayName} • ${w.quantity} ${w.unit.name} • ${w.date.day}/${w.date.month}/${w.date.year}',
                  ),
                  trailing: Text(
                    '₹${w.estimatedCost.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showWastageForm() {
    final permissions = ref.read(routePermissionProvider(AppRoutes.wastage));
    if (!permissions.canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to log wastage.'),
        ),
      );
      return;
    }

    _nameCtrl.clear();
    _qtyCtrl.clear();
    _costCtrl.clear();
    _notesCtrl.clear();
    _reason = WastageReason.expired;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Log Wastage', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ingredient Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Est. Cost (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WastageReason>(
                initialValue: _reason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                items: WastageReason.values
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text('${r.emoji} ${r.displayName}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSheetState(() => _reason = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _submitWastage(ctx),
                  child: const Text('Log Wastage'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitWastage(BuildContext ctx) async {
    final permissions = ref.read(routePermissionProvider(AppRoutes.wastage));
    if (!permissions.canCreate) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to log wastage.'),
        ),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final cost = double.tryParse(_costCtrl.text.trim()) ?? 0;
    if (name.isEmpty || qty <= 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Name and quantity are required')),
      );
      return;
    }

    final wastage = WastageModel(
      id: generateSafeId('wastage'),
      ingredientId: '',
      ingredientName: name,
      quantity: qty,
      estimatedCost: cost,
      reason: _reason,
      date: DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await WastageService.logWastage(wastage);
      if (ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('Wastage logged ✓')));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text('Failed to log wastage: $e')));
      }
    }
  }
}
