/// Item-wise sales — sortable table with qty, revenue
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/reports/services/advanced_reports_service.dart';

class ItemSalesScreen extends ConsumerStatefulWidget {
  const ItemSalesScreen({super.key});

  @override
  ConsumerState<ItemSalesScreen> createState() => _ItemSalesScreenState();
}

class _ItemSalesScreenState extends ConsumerState<ItemSalesScreen> {
  List<Map<String, dynamic>>? _items;
  bool _loading = false;
  bool _sortByRevenue = true;
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await AdvancedReportsService.topProducts(
      _range.start,
      _range.end,
      limit: 100,
    );
    if (mounted) {
      setState(() {
        _items = data;
        _loading = false;
      });
    }
  }

  void _toggleSort() {
    if (_items == null) return;
    setState(() {
      _sortByRevenue = !_sortByRevenue;
      _items!.sort((a, b) {
        if (_sortByRevenue) {
          return ((b['revenue'] as num?) ?? 0).compareTo(
            (a['revenue'] as num?) ?? 0,
          );
        }
        return ((b['quantity'] as num?) ?? 0).compareTo(
          (a['quantity'] as num?) ?? 0,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Sales'),
        actions: [
          if (_items != null)
            TextButton.icon(
              onPressed: _toggleSort,
              icon: const Icon(Icons.sort),
              label: Text(_sortByRevenue ? 'By Revenue' : 'By Qty'),
            ),
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items == null
          ? Center(
              child: FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.analytics),
                label: const Text('Load Sales Data'),
              ),
            )
          : _items!.isEmpty
          ? const Center(child: Text('No sales data'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items!.length,
              itemBuilder: (context, index) {
                final item = _items![index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text((item['name'] as String?) ?? 'Unknown'),
                    subtitle: Text('Quantity: ${item['quantity']}'),
                    trailing: Text(
                      '₹${((item['revenue'] as num?) ?? 0).toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
      await _load();
    }
  }
}
