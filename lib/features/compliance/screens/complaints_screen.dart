/// Complaint management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/compliance/providers/compliance_provider.dart';
import 'package:tulasihotels/features/compliance/services/complaint_service.dart';
import 'package:tulasihotels/models/complaint_model.dart';

class ComplaintsScreen extends ConsumerStatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen> {
  final _descCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  ComplaintCategory _category = ComplaintCategory.food;
  bool _showAll = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _customerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complaintsAsync = _showAll
        ? ref.watch(allComplaintsProvider)
        : ref.watch(activeComplaintsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        actions: [
          FilterChip(
            label: Text(_showAll ? 'All' : 'Active'),
            selected: _showAll,
            onSelected: (v) => setState(() => _showAll = v),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showComplaintForm,
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
      ),
      body: complaintsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (complaints) {
          if (complaints.isEmpty) {
            return const Center(child: Text('No complaints'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final c = complaints[index];
              final statusColor = switch (c.status) {
                ComplaintStatus.open => Colors.red,
                ComplaintStatus.investigating => Colors.orange,
                ComplaintStatus.resolved => Colors.green,
                ComplaintStatus.closed => Colors.grey,
              };

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(c.category.emoji),
                  ),
                  title: Text(c.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${c.category.displayName} • ${c.customerName ?? "Anonymous"}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: false,
                  trailing: PopupMenuButton<ComplaintStatus>(
                    initialValue: c.status,
                    child: Chip(
                      label: Text(
                        c.status.displayName,
                        style: TextStyle(color: statusColor, fontSize: 10),
                      ),
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                    onSelected: (newStatus) async {
                      await ComplaintService.updateStatus(c.id, newStatus);
                    },
                    itemBuilder: (ctx) => ComplaintStatus.values
                        .map((s) => PopupMenuItem(
                              value: s,
                              child: Text(s.displayName),
                            ))
                        .toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showComplaintForm() {
    _descCtrl.clear();
    _customerCtrl.clear();
    _category = ComplaintCategory.food;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('New Complaint', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<ComplaintCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ComplaintCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.emoji} ${c.displayName}'),
                        ))
                    .toList(),
                onChanged: (v) => setSheetState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Customer Name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _submitComplaint(ctx),
                  child: const Text('Submit Complaint'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitComplaint(BuildContext ctx) async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return;

    final complaint = ComplaintModel(
      id: generateSafeId('complaint'),
      description: desc,
      category: _category,
      customerName: _customerCtrl.text.trim().isEmpty ? null : _customerCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    await ComplaintService.createComplaint(complaint);
    if (ctx.mounted) Navigator.pop(ctx);
  }
}
