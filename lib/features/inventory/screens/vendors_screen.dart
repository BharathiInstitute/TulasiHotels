/// Vendors management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/inventory/providers/inventory_provider.dart';
import 'package:tulasihotels/features/inventory/services/vendor_service.dart';
import 'package:tulasihotels/models/vendor_model.dart';

class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(vendorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vendors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVendorForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Vendor'),
      ),
      body: vendorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vendors) {
          if (vendors.isEmpty) {
            return const Center(child: Text('No vendors yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(vendor.name.isNotEmpty
                        ? vendor.name[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(vendor.name),
                  subtitle: Text(
                    '${vendor.phone ?? "No phone"} • ${vendor.supplyItems.isNotEmpty ? vendor.supplyItems.join(", ") : "General"}',
                  ),
                  trailing: Text(
                    '₹${vendor.balance.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showVendorForm(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

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
              Text('Add Vendor',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Vendor Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty) return;
                  final vendor = VendorModel(
                    id: generateSafeId('vendor'),
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty
                        ? null
                        : phoneCtrl.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  VendorService.createVendor(vendor);
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
  }
}
