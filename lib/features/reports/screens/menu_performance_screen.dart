/// Menu performance report — top/bottom sellers, margins
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/reports/services/advanced_reports_service.dart';

class MenuPerformanceScreen extends ConsumerStatefulWidget {
  const MenuPerformanceScreen({super.key});

  @override
  ConsumerState<MenuPerformanceScreen> createState() =>
      _MenuPerformanceScreenState();
}

class _MenuPerformanceScreenState extends ConsumerState<MenuPerformanceScreen> {
  List<Map<String, dynamic>>? _topProducts;
  bool _loading = false;
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await AdvancedReportsService.topProducts(
      _range.start,
      _range.end,
      limit: 20,
    );
    if (mounted) {
      setState(() {
        _topProducts = data;
        _loading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Performance'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _topProducts == null
          ? Center(
              child: FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.analytics),
                label: const Text('Analyze'),
              ),
            )
          : _topProducts!.isEmpty
          ? const Center(child: Text('No data for this period'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Top Sellers', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                ..._topProducts!
                    .take(10)
                    .map(
                      (p) => Card(
                        child: ListTile(
                          title: Text((p['name'] as String?) ?? 'Unknown'),
                          subtitle: Text(
                            'Qty: ${p['quantity']} · Revenue: ₹${((p['revenue'] as num?) ?? 0).toStringAsFixed(0)}',
                          ),
                          trailing: Text(
                            '₹${((p['revenue'] as num?) ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                if (_topProducts!.length > 10) ...[
                  const SizedBox(height: 24),
                  Text('Slow Movers', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ..._topProducts!.reversed
                      .take(10)
                      .map(
                        (p) => Card(
                          child: ListTile(
                            title: Text((p['name'] as String?) ?? 'Unknown'),
                            subtitle: Text('Qty: ${p['quantity']}'),
                            trailing: const Icon(
                              Icons.trending_down,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            ),
    );
  }
}
