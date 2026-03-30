/// License tracking screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/compliance/providers/compliance_provider.dart';
import 'package:tulasihotels/features/compliance/services/license_service.dart';
import 'package:tulasihotels/models/license_model.dart';

class LicensesScreen extends ConsumerStatefulWidget {
  const LicensesScreen({super.key});

  @override
  ConsumerState<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends ConsumerState<LicensesScreen> {
  final _numberCtrl = TextEditingController();
  final _authorityCtrl = TextEditingController();
  LicenseType _type = LicenseType.fssai;
  DateTime _issueDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _numberCtrl.dispose();
    _authorityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final licensesAsync = ref.watch(licensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Licenses & Permits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLicenseForm,
        icon: const Icon(Icons.add),
        label: const Text('Add License'),
      ),
      body: licensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (licenses) {
          if (licenses.isEmpty) {
            return const Center(child: Text('No licenses tracked'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: licenses.length,
            itemBuilder: (context, index) {
              final lic = licenses[index];
              final urgencyVal = lic.urgency;
              final urgencyColor = switch (urgencyVal) {
                'expired' => Colors.red,
                'critical' => Colors.deepOrange,
                'warning' => Colors.orange,
                _ => Colors.green,
              };

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: urgencyColor.withValues(alpha: 0.2),
                    child: Icon(Icons.verified, color: urgencyColor),
                  ),
                  title: Text(lic.type.displayName),
                  subtitle: Text(
                    '${lic.licenseNumber ?? "No number"}\nExpires: ${lic.expiryDate.day}/${lic.expiryDate.month}/${lic.expiryDate.year}',
                  ),
                  isThreeLine: true,
                  trailing: urgencyVal != 'ok'
                      ? Chip(
                          label: Text(
                            urgencyVal.toUpperCase(),
                            style: TextStyle(color: urgencyColor, fontSize: 10),
                          ),
                          backgroundColor: urgencyColor.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        )
                      : null,
                  onTap: () => _showRenewDialog(lic),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showLicenseForm() {
    _numberCtrl.clear();
    _authorityCtrl.clear();
    _type = LicenseType.fssai;
    _issueDate = DateTime.now();
    _expiryDate = DateTime.now().add(const Duration(days: 365));

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
              Text('Add License', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<LicenseType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: LicenseType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ))
                    .toList(),
                onChanged: (v) => setSheetState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _numberCtrl,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _authorityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Issuing Authority (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: _issueDate,
                          firstDate: DateTime(2010),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setSheetState(() => _issueDate = picked);
                      },
                      child: Text('Issue: ${_issueDate.day}/${_issueDate.month}/${_issueDate.year}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: _expiryDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setSheetState(() => _expiryDate = picked);
                      },
                      child: Text('Expiry: ${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _submitLicense(ctx),
                  child: const Text('Add License'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitLicense(BuildContext ctx) async {
    final number = _numberCtrl.text.trim();

    final license = LicenseModel(
      id: generateSafeId('license'),
      type: _type,
      licenseNumber: number.isEmpty ? null : number,
      issuingAuthority: _authorityCtrl.text.trim().isEmpty ? null : _authorityCtrl.text.trim(),
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      createdAt: DateTime.now(),
    );

    await LicenseService.createLicense(license);
    if (ctx.mounted) Navigator.pop(ctx);
  }

  void _showRenewDialog(LicenseModel license) {
    final DateTime newIssue = DateTime.now();
    DateTime newExpiry = license.expiryDate.add(const Duration(days: 365));
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Renew ${license.type.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current expiry: ${license.expiryDate.day}/${license.expiryDate.month}/${license.expiryDate.year}'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: newExpiry,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setDialogState(() => newExpiry = picked);
                },
                child: Text('New expiry: ${newExpiry.day}/${newExpiry.month}/${newExpiry.year}'),
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
                await LicenseService.renewLicense(
                  license.id,
                  newIssueDate: newIssue,
                  newExpiryDate: newExpiry,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Renew'),
            ),
          ],
        ),
      ),
    );
  }
}
