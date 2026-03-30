/// Monthly Profit & Loss report
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/reports/services/advanced_reports_service.dart';

class PnlReportScreen extends ConsumerStatefulWidget {
  const PnlReportScreen({super.key});

  @override
  ConsumerState<PnlReportScreen> createState() => _PnlReportScreenState();
}

class _PnlReportScreenState extends ConsumerState<PnlReportScreen> {
  bool _loading = false;
  Map<String, double>? _dailyRevenue;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> _load() async {
    setState(() => _loading = true);
    final start = _month;
    final end = DateTime(_month.year, _month.month + 1);
    final revenue = await AdvancedReportsService.dailyRevenue(start, end);
    if (mounted) {
      setState(() {
      _dailyRevenue = revenue;
      _loading = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthLabel =
        '${_monthName(_month.month)} ${_month.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly P&L'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _month = DateTime(_month.year, _month.month - 1);
              _dailyRevenue = null;
            }),
          ),
          Center(child: Text(monthLabel)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _month = DateTime(_month.year, _month.month + 1);
              _dailyRevenue = null;
            }),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dailyRevenue == null
              ? Center(
                  child: FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Generate P&L'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _PnlRow(
                      label: 'Total Revenue',
                      amount: _totalRevenue,
                      isTotal: true,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text('Daily Breakdown', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._dailyRevenue!.entries.map((e) => _PnlRow(
                          label: e.key,
                          amount: e.value,
                        )),
                  ],
                ),
    );
  }

  double get _totalRevenue =>
      _dailyRevenue?.values.fold<double>(0.0, (a, b) => a + b) ?? 0;

  String _monthName(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m];
  }
}

class _PnlRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;
  final Color? color;

  const _PnlRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: color)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${amount.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}
