/// Equipment maintenance tracking screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/compliance/providers/compliance_provider.dart';
import 'package:tulasihotels/features/compliance/services/equipment_service.dart';
import 'package:tulasihotels/models/equipment_model.dart';

class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  final _nameCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serialCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(equipmentProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Equipment')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEquipmentForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Equipment'),
      ),
      body: equipmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No equipment tracked'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final eq = items[index];

              return Card(
                child: ExpansionTile(
                  leading: Icon(
                    Icons.build,
                    color: eq.isServiceOverdue ? Colors.orange : null,
                  ),
                  title: Text(eq.name),
                  subtitle: Text(
                    '${eq.brand ?? "No brand"} • ${eq.serialNumber ?? "No serial"}',
                  ),
                  trailing: eq.isServiceOverdue
                      ? const Chip(
                          label: Text('SERVICE DUE', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.orange,
                        )
                      : null,
                  children: [
                    if (eq.nextServiceDue != null)
                      ListTile(
                        dense: true,
                        title: Text(
                          'Next service: ${eq.nextServiceDue!.day}/${eq.nextServiceDue!.month}/${eq.nextServiceDue!.year}',
                        ),
                      ),
                    if (eq.amcVendor != null)
                      ListTile(
                        dense: true,
                        title: Text('AMC Vendor: ${eq.amcVendor}'),
                        subtitle: eq.amcPhone != null ? Text(eq.amcPhone!) : null,
                      ),
                    if (eq.serviceHistory.isNotEmpty) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text('Service History', style: theme.textTheme.titleSmall),
                      ),
                      ...eq.serviceHistory.take(5).map(
                            (record) => ListTile(
                              dense: true,
                              title: Text(record.description),
                              subtitle: Text(
                                '${record.date.day}/${record.date.month}/${record.date.year} • ₹${record.cost.toStringAsFixed(0)}',
                              ),
                              trailing: record.vendorName != null
                                  ? Text(record.vendorName!)
                                  : null,
                            ),
                          ),
                    ],
                    OverflowBar(
                      children: [
                        TextButton.icon(
                          onPressed: () => _showServiceForm(eq),
                          icon: const Icon(Icons.add_task),
                          label: const Text('Log Service'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEquipmentForm() {
    _nameCtrl.clear();
    _serialCtrl.clear();
    _brandCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Equipment', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Equipment Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brandCtrl,
              decoration: const InputDecoration(
                labelText: 'Brand (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serialCtrl,
              decoration: const InputDecoration(
                labelText: 'Serial Number (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _submitEquipment(ctx),
                child: const Text('Add Equipment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitEquipment(BuildContext ctx) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final eq = EquipmentModel(
      id: generateSafeId('equip'),
      name: name,
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      serialNumber: _serialCtrl.text.trim().isEmpty ? null : _serialCtrl.text.trim(),
      purchaseDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await EquipmentService.createEquipment(eq);
    if (ctx.mounted) Navigator.pop(ctx);
  }

  void _showServiceForm(EquipmentModel equipment) {
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cost (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: vendorCtrl,
              decoration: const InputDecoration(
                labelText: 'Vendor Name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final desc = descCtrl.text.trim();
              if (desc.isEmpty) return;

              final record = ServiceRecord(
                date: DateTime.now(),
                description: desc,
                cost: double.tryParse(costCtrl.text.trim()) ?? 0,
                vendorName: vendorCtrl.text.trim().isEmpty ? null : vendorCtrl.text.trim(),
              );

              await EquipmentService.addServiceRecord(equipment.id, record);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }
}
