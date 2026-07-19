/// Vendors management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/inventory/providers/inventory_provider.dart';
import 'package:tulasihotels/features/inventory/services/vendor_service.dart';
import 'package:tulasihotels/features/inventory/services/vendor_settlement_service.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/models/vendor_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(vendorsProvider);
    final vendorPermissions = ref.watch(routePermissionProvider(AppRoutes.vendors));

    return Scaffold(
      appBar: AppBar(title: const Text('Vendors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: vendorPermissions.canCreate
            ? () => _showAddVendorSheet(context, ref)
            : null,
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
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              final balanceColor = vendor.balance > 0
                  ? Colors.orange
                  : vendor.balance < 0
                      ? Colors.green
                      : null;
              return Card(
                child: ListTile(
                  onTap: () => _showVendorDetail(
                    context,
                    vendor,
                    canUpdate: vendorPermissions.canUpdate,
                  ),
                  leading: CircleAvatar(
                    child: Text(
                      vendor.name.isNotEmpty
                          ? vendor.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(
                    vendor.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${vendor.phone ?? "No phone"} â€¢ ${vendor.supplyItems.isNotEmpty ? vendor.supplyItems.join(", ") : "General"}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${vendor.balance.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: balanceColor,
                        ),
                      ),
                      if (vendor.balance != 0)
                        Text(
                          vendor.balance > 0 ? 'you owe' : 'they owe',
                          style: TextStyle(
                            fontSize: 10,
                            color: balanceColor,
                          ),
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

  // â”€â”€â”€ Add Vendor Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showAddVendorSheet(BuildContext context, WidgetRef ref) {
    final permissions = ref.read(routePermissionProvider(AppRoutes.vendors));
    if (!permissions.canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to add vendors.'),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final supplyCtrl = TextEditingController();
    final supplyItems = <String>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          void addSupplyItem() {
            final item = supplyCtrl.text.trim();
            if (item.isEmpty) return;
            setState(() => supplyItems.add(item));
            supplyCtrl.clear();
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add Vendor',
                      style: Theme.of(ctx).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Vendor Name *',
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
                  const SizedBox(height: 12),
                  // Supply items input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: supplyCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Supply Item (e.g. Rice, Oil)',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => addSupplyItem(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: addSupplyItem,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (supplyItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: supplyItems
                          .map(
                            (item) => Chip(
                              label: Text(item),
                              onDeleted: () =>
                                  setState(() => supplyItems.remove(item)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final vendor = VendorModel(
                        id: generateSafeId('vendor'),
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim().isEmpty
                            ? null
                            : phoneCtrl.text.trim(),
                        supplyItems: List.from(supplyItems),
                        createdAt: DateTime.now(),
                      );
                      await VendorService.createVendor(vendor);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text('Add Vendor'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // â”€â”€â”€ Vendor Detail Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showVendorDetail(
    BuildContext context,
    VendorModel vendor, {
    required bool canUpdate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _VendorDetailSheet(
        vendor: vendor,
        canUpdate: canUpdate,
      ),
    );
  }
}

// â”€â”€â”€ Vendor Detail Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VendorDetailSheet extends StatefulWidget {
  final VendorModel vendor;
  final bool canUpdate;

  const _VendorDetailSheet({required this.vendor, required this.canUpdate});

  @override
  State<_VendorDetailSheet> createState() => _VendorDetailSheetState();
}

class _VendorDetailSheetState extends State<_VendorDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    vendor.name.isNotEmpty
                        ? vendor.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (vendor.phone != null)
                        Text(
                          vendor.phone!,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${vendor.balance.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: vendor.balance > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                    Text(
                      vendor.balance > 0
                          ? 'you owe'
                          : vendor.balance < 0
                              ? 'they owe'
                              : 'settled',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.canUpdate
                        ? () => _showRecordPurchase(context, vendor)
                        : null,
                    icon: const Icon(Icons.shopping_cart, size: 16),
                    label: const Text('Record Purchase'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.canUpdate
                        ? () => _showRecordPayment(context, vendor)
                        : null,
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text('Record Payment'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Tabs
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'History'),
              Tab(text: 'Purchases'),
              Tab(text: 'Info'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PaymentHistoryTab(vendorId: vendor.id),
                _PurchasesTab(vendorId: vendor.id),
                _VendorInfoTab(vendor: vendor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordPurchase(BuildContext context, VendorModel vendor) {
    if (!widget.canUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to update vendors.'),
        ),
      );
      return;
    }

    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Purchase from ${vendor.name} increases the amount you owe them.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note / Invoice no. (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) return;
              // Purchase increases balance (you owe more)
              await VendorSettlementService.recordPurchase(
                vendorId: vendor.id,
                amount: amount,
                note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              );
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Purchase of ₹${amount.toStringAsFixed(0)} recorded'),
                  ),
                );
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _showRecordPayment(BuildContext context, VendorModel vendor) {
    if (!widget.canUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to update vendors.'),
        ),
      );
      return;
    }

    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Payment to ${vendor.name} reduces the amount you owe them.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) return;
              await VendorSettlementService.recordPayment(
                vendorId: vendor.id,
                amount: amount,
                note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              );
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Payment of ₹${amount.toStringAsFixed(0)} recorded'),
                  ),
                );
              }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Payment History Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PaymentHistoryTab extends StatelessWidget {
  final String vendorId;
  const _PaymentHistoryTab({required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: VendorSettlementService.settlementHistoryStream(vendorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading history:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          );
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return const Center(
            child: Text('No transactions yet.\nRecord a purchase or payment.',
                textAlign: TextAlign.center),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final e = entries[i];
            final type = e['type'] as String? ?? 'payment';
            final amount = (e['amount'] as num?)?.toDouble() ?? 0;
            final note = e['note'] as String?;
            final date = e['createdAt'] as DateTime? ?? DateTime.now();
            final isPurchase = type == 'purchase';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isPurchase
                    ? Colors.orange.withAlpha(30)
                    : Colors.green.withAlpha(30),
                child: Icon(
                  isPurchase ? Icons.shopping_cart : Icons.payments,
                  color: isPurchase ? Colors.orange : Colors.green,
                  size: 20,
                ),
              ),
              title: Text(
                isPurchase ? 'Purchase' : 'Payment',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${_formatDate(date)}${note != null ? ' â€¢ $note' : ''}',
              ),
              trailing: Text(
                '${isPurchase ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPurchase ? Colors.orange : Colors.green,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// â”€â”€â”€ Purchases Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PurchasesTab extends StatelessWidget {
  final String vendorId;
  const _PurchasesTab({required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: VendorSettlementService.settlementHistoryStream(vendorId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          );
        }
        final all = snapshot.data ?? [];
        final purchases = all.where((e) => e['type'] == 'purchase').toList();
        if (purchases.isEmpty) {
          return const Center(child: Text('No purchases recorded yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: purchases.length,
          itemBuilder: (context, i) {
            final e = purchases[i];
            final amount = (e['amount'] as num?)?.toDouble() ?? 0;
            final note = e['note'] as String?;
            final date = e['createdAt'] as DateTime? ?? DateTime.now();
            return ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: Text('₹${amount.toStringAsFixed(0)}'),
              subtitle: Text(
                  '${date.day}/${date.month}/${date.year}${note != null ? ' â€¢ $note' : ''}'),
            );
          },
        );
      },
    );
  }
}

// â”€â”€â”€ Vendor Info Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VendorInfoTab extends StatelessWidget {
  final VendorModel vendor;
  const _VendorInfoTab({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (vendor.phone != null) ...[
          _InfoRow(Icons.phone, 'Phone', vendor.phone!),
          const Divider(),
        ],
        if (vendor.email != null) ...[
          _InfoRow(Icons.email, 'Email', vendor.email!),
          const Divider(),
        ],
        if (vendor.address != null) ...[
          _InfoRow(Icons.location_on, 'Address', vendor.address!),
          const Divider(),
        ],
        if (vendor.gstNumber != null) ...[
          _InfoRow(Icons.receipt, 'GST', vendor.gstNumber!),
          const Divider(),
        ],
        if (vendor.supplyItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Supply Items',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: vendor.supplyItems
                .map((item) => Chip(label: Text(item)))
                .toList(),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Added ${vendor.createdAt.day}/${vendor.createdAt.month}/${vendor.createdAt.year}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}


