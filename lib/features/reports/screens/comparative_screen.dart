/// Comparative report — side-by-side KPIs with trend arrows
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/reports/services/advanced_reports_service.dart';

class ComparativeScreen extends ConsumerStatefulWidget {
  const ComparativeScreen({super.key});

  @override
  ConsumerState<ComparativeScreen> createState() => _ComparativeScreenState();
}

class _ComparativeScreenState extends ConsumerState<ComparativeScreen> {
  bool _loading = false;
  Map<String, double>? _period1Revenue;
  Map<String, double>? _period2Revenue;
  Map<String, int>? _period1Orders;
  Map<String, int>? _period2Orders;

  DateTime get _thisWeekStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  DateTime get _lastWeekStart =>
      _thisWeekStart.subtract(const Duration(days: 7));

  Future<void> _load() async {
    setState(() => _loading = true);
    final thisEnd = _thisWeekStart.add(const Duration(days: 7));
    final lastEnd = _thisWeekStart;

    final results = await Future.wait([
      AdvancedReportsService.dailyRevenue(_lastWeekStart, lastEnd),
      AdvancedReportsService.dailyRevenue(_thisWeekStart, thisEnd),
      AdvancedReportsService.orderTypeDistribution(_lastWeekStart, lastEnd),
      AdvancedReportsService.orderTypeDistribution(_thisWeekStart, thisEnd),
    ]);
    if (mounted) {
      setState(() {
      _period1Revenue = results[0] as Map<String, double>;
      _period2Revenue = results[1] as Map<String, double>;
      _period1Orders = results[2] as Map<String, int>;
      _period2Orders = results[3] as Map<String, int>;
      _loading = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Week Comparison')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _period1Revenue == null
              ? Center(
                  child: FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Compare Weeks'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ComparisonCard(
                      label: 'Revenue',
                      lastValue: _sum(_period1Revenue),
                      thisValue: _sum(_period2Revenue),
                      prefix: '₹',
                    ),
                    _ComparisonCard(
                      label: 'Total Orders',
                      lastValue: _sumInt(_period1Orders).toDouble(),
                      thisValue: _sumInt(_period2Orders).toDouble(),
                    ),
                    const SizedBox(height: 16),
                    Text('Revenue by Day', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Last Week',
                              style: theme.textTheme.titleSmall,
                              textAlign: TextAlign.center),
                        ),
                        Expanded(
                          child: Text('This Week',
                              style: theme.textTheme.titleSmall,
                              textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                    const Divider(),
                    ...List.generate(7, (i) {
                      final last = _period1Revenue?.values.elementAtOrNull(i) ?? 0;
                      final current = _period2Revenue?.values.elementAtOrNull(i) ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '₹${last.toStringAsFixed(0)}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '₹${current.toStringAsFixed(0)}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: current >= last
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
    );
  }

  double _sum(Map<String, double>? map) =>
      map?.values.fold<double>(0.0, (a, b) => a + b) ?? 0;

  int _sumInt(Map<String, int>? map) =>
      map?.values.fold<int>(0, (a, b) => a + b) ?? 0;
}

class _ComparisonCard extends StatelessWidget {
  final String label;
  final double lastValue;
  final double thisValue;
  final String prefix;

  const _ComparisonCard({
    required this.label,
    required this.lastValue,
    required this.thisValue,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final change = thisValue - lastValue;
    final pct = lastValue > 0 ? (change / lastValue * 100) : 0.0;
    final isUp = change >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last Week',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text('$prefix${lastValue.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                Icon(
                  isUp ? Icons.trending_up : Icons.trending_down,
                  color: isUp ? Colors.green : Colors.red,
                  size: 32,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('This Week',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text('$prefix${thisValue.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${isUp ? '+' : ''}${pct.toStringAsFixed(1)}%',
              style: TextStyle(
                color: isUp ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
