/// Advanced reports / analytics dashboard screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/reports/services/advanced_reports_service.dart';

class AdvancedReportsScreen extends ConsumerStatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  ConsumerState<AdvancedReportsScreen> createState() =>
      _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends ConsumerState<AdvancedReportsScreen> {
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  bool _loading = false;

  Map<String, double>? _dailyRevenue;
  List<Map<String, dynamic>>? _topProducts;
  Map<String, double>? _paymentBreakdown;
  Map<String, int>? _orderTypeDistribution;
  Map<int, int>? _hourlyOrders;
  List<Map<String, dynamic>>? _waiterPerformance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          TextButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range),
            label: Text(
              '${_range.start.day}/${_range.start.month} - ${_range.end.day}/${_range.end.month}',
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dailyRevenue == null
          ? Center(
              child: FilledButton.icon(
                onPressed: _loadReports,
                icon: const Icon(Icons.analytics),
                label: const Text('Load Analytics'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Daily revenue
                if (_dailyRevenue != null) ...[
                  Text('Daily Revenue', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: _dailyRevenue!.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key),
                                Text(
                                  '₹${e.value.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Top products
                if (_topProducts != null && _topProducts!.isNotEmpty) ...[
                  Text('Top Products', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: _topProducts!.asMap().entries.map((e) {
                        final rank = e.key + 1;
                        final product = e.value;
                        return ListTile(
                          leading: CircleAvatar(child: Text('$rank')),
                          title: Text((product['name'] as String?) ?? ''),
                          subtitle: Text('Qty: ${product['quantity']}'),
                          trailing: Text(
                            '₹${(product['revenue'] as num).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Payment method breakdown
                if (_paymentBreakdown != null) ...[
                  Text('Payment Methods', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: _paymentBreakdown!.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key.toUpperCase()),
                                Text('₹${e.value.toStringAsFixed(0)}'),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Order type distribution
                if (_orderTypeDistribution != null) ...[
                  Text('Order Types', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: _orderTypeDistribution!.entries.map((e) {
                          return Chip(label: Text('${e.key}: ${e.value}'));
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Hourly order counts
                if (_hourlyOrders != null && _hourlyOrders!.isNotEmpty) ...[
                  Text('Hourly Orders', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children:
                            (_hourlyOrders!.entries.toList()
                                  ..sort((a, b) => a.key.compareTo(b.key)))
                                .map((e) {
                                  final hour = e.key;
                                  final label = hour < 12
                                      ? '${hour}AM'
                                      : hour == 12
                                      ? '12PM'
                                      : '${hour - 12}PM';
                                  final maxVal = _hourlyOrders!.values.reduce(
                                    (a, b) => a > b ? a : b,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 48, child: Text(label)),
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: maxVal > 0
                                                ? e.value / maxVal
                                                : 0,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${e.value}'),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Waiter performance
                if (_waiterPerformance != null &&
                    _waiterPerformance!.isNotEmpty) ...[
                  Text('Waiter Performance', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: _waiterPerformance!.map((w) {
                        return ListTile(
                          title: Text((w['name'] as String?) ?? 'Unknown'),
                          subtitle: Text('${w['billCount']} bills'),
                          trailing: Text(
                            '₹${(w['totalRevenue'] as num).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _range = picked);
      await _loadReports();
    }
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AdvancedReportsService.dailyRevenue(_range.start, _range.end),
        AdvancedReportsService.topProducts(_range.start, _range.end),
        AdvancedReportsService.revenueByPaymentMethod(_range.start, _range.end),
        AdvancedReportsService.orderTypeDistribution(_range.start, _range.end),
        AdvancedReportsService.hourlyOrderCounts(_range.start, _range.end),
        AdvancedReportsService.waiterPerformance(_range.start, _range.end),
      ]);
      setState(() {
        _dailyRevenue = results[0] as Map<String, double>;
        _topProducts = results[1] as List<Map<String, dynamic>>;
        _paymentBreakdown = results[2] as Map<String, double>;
        _orderTypeDistribution = results[3] as Map<String, int>;
        _hourlyOrders = results[4] as Map<int, int>;
        _waiterPerformance = results[5] as List<Map<String, dynamic>>;
      });
    } finally {
      setState(() => _loading = false);
    }
  }
}
