/// Cash register screen — daily drawer management
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/staff/providers/cash_register_provider.dart';
import 'package:tulasihotels/features/staff/services/cash_register_service.dart';
import 'package:tulasihotels/models/cash_register_model.dart';

class CashRegisterScreen extends ConsumerWidget {
  const CashRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerAsync = ref.watch(todayRegisterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cash Register')),
      body: registerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (register) {
          if (register == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.point_of_sale, size: 64),
                  const SizedBox(height: 16),
                  const Text('No register opened today'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openRegister(context),
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Open Register'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Register Open',
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                            'Opening Balance: ₹${register.openingBalance.toStringAsFixed(2)}'),
                        Text(
                            'Opened by: ${register.staffName}'),
                        if (register.closedAt != null)
                          Text(
                              'Closing Balance: ₹${register.closingBalance.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Cash Movements',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: register.movements.length,
                    itemBuilder: (context, index) {
                      final movement = register.movements[index];
                      return ListTile(
                        leading: Icon(
                          movement.isInflow
                              ? Icons.arrow_circle_down
                              : Icons.arrow_circle_up,
                          color: movement.isInflow ? Colors.green : Colors.red,
                        ),
                        title: Text(movement.reason),
                        trailing: Text(
                          '${movement.isInflow ? "+" : "-"}₹${movement.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: movement.isInflow ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (register.closedAt == null)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _addMovement(context, register.id),
                          icon: const Icon(Icons.swap_vert),
                          label: const Text('Cash In/Out'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _closeRegister(context, register.id),
                          icon: const Icon(Icons.lock),
                          label: const Text('Close Register'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openRegister(BuildContext context) {
    final balanceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open Register'),
        content: TextField(
          controller: balanceCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Opening Balance (₹)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final now = DateTime.now();
              final register = CashRegisterModel(
                id: generateSafeId('register'),
                staffId: '',
                staffName: 'Manager',
                openingBalance:
                    double.tryParse(balanceCtrl.text) ?? 0,
                openedAt: now,
              );
              CashRegisterService.openRegister(register);
              Navigator.of(ctx).pop();
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _addMovement(BuildContext context, String registerId) {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    var isIn = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Cash Movement'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Cash In'),
                        selected: isIn,
                        onSelected: (_) =>
                            setDialogState(() => isIn = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Cash Out'),
                        selected: !isIn,
                        onSelected: (_) =>
                            setDialogState(() => isIn = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
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
                  onPressed: () {
                    final movement = CashMovement(
                      isInflow: isIn,
                      amount:
                          double.tryParse(amountCtrl.text) ?? 0,
                      reason: reasonCtrl.text.trim(),
                      timestamp: DateTime.now(),
                    );
                    CashRegisterService.addCashMovement(
                        registerId, movement);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _closeRegister(BuildContext context, String registerId) {
    final balanceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Register'),
        content: TextField(
          controller: balanceCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Closing Balance (₹)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              CashRegisterService.closeRegister(
                registerId,
                closingBalance:
                    double.tryParse(balanceCtrl.text) ?? 0,
                closedByName: 'Manager',
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
