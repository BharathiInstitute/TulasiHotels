/// Split bill screen — split order items between people
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/billing/services/billing_service.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/order_model.dart';

class SplitBillScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const SplitBillScreen({super.key, required this.order});

  @override
  ConsumerState<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends ConsumerState<SplitBillScreen> {
  int _splitCount = 2;
  bool _splitEqually = true;
  late List<List<OrderItem>> _splits;

  @override
  void initState() {
    super.initState();
    _initSplits();
  }

  void _initSplits() {
    if (_splitEqually) {
      // Put all items in first split (equal division by total)
      _splits = List.generate(_splitCount, (i) => i == 0 ? List.from(widget.order.items) : []);
    } else {
      _splits = List.generate(_splitCount, (_) => []);
      // Distribute items round-robin
      for (var i = 0; i < widget.order.items.length; i++) {
        _splits[i % _splitCount].add(widget.order.items[i]);
      }
    }
  }

  double _splitTotal(int index) {
    if (_splitEqually) {
      return widget.order.total / _splitCount;
    }
    return _splits[index]
        .fold<double>(0, (sum, item) => sum + item.price * item.quantity);
  }

  Future<void> _confirmSplit() async {
    try {
      await BillingService.createSplitBills(
        order: widget.order,
        splits: _splits,
        paymentMethod: PaymentMethod.cash,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill split into $_splitCount parts')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error splitting bill: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Split Bill — Order #${widget.order.orderNumber}'),
      ),
      body: Column(
        children: [
          // Split mode toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Split Equally'),
                  selected: _splitEqually,
                  onSelected: (v) => setState(() {
                    _splitEqually = true;
                    _initSplits();
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Split by Items'),
                  selected: !_splitEqually,
                  onSelected: (v) => setState(() {
                    _splitEqually = false;
                    _initSplits();
                  }),
                ),
                const Spacer(),
                const Text('People: '),
                DropdownButton<int>(
                  value: _splitCount,
                  items: List.generate(
                    9,
                    (i) => DropdownMenuItem(
                      value: i + 2,
                      child: Text('${i + 2}'),
                    ),
                  ),
                  onChanged: (val) => setState(() {
                    _splitCount = val ?? 2;
                    _initSplits();
                  }),
                ),
              ],
            ),
          ),
          // Split previews
          Expanded(
            child: ListView.builder(
              itemCount: _splitCount,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text('Person ${index + 1}'),
                    subtitle: _splitEqually
                        ? null
                        : Text('${_splits[index].length} items'),
                    trailing: Text(
                      '₹${_splitTotal(index).toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Total bar
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${widget.order.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge,
                ),
                FilledButton.icon(
                  onPressed: _confirmSplit,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Split'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
