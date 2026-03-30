/// Weekly revenue report — day-by-day breakdown with payment modes
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/reports/services/advanced_reports_service.dart';

class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() =>
      _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  Map<String, double>? _dailyRevenue;
  Map<String, double>? _paymentBreakdown;
  bool _loading = false;

  DateTime get _weekStart {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final start = _weekStart;
    final end = start.add(const Duration(days: 7));
    final results = await Future.wait([
      AdvancedReportsService.dailyRevenue(start, end),
      AdvancedReportsService.revenueByPaymentMethod(start, end),
    ]);
    if (mounted) {
      setState(() {
      _dailyRevenue = results[0];
      _paymentBreakdown = results[1];
      _loading = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Revenue')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dailyRevenue == null
              ? Center(
                  child: FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Load Report'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Total
                    Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Week Total',
                                style: theme.textTheme.titleMedium),
                            Text(
                              '₹${_dailyRevenue!.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Daily breakdown
                    Text('Daily Breakdown', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ..._dailyRevenue!.entries.map((e) => ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(e.key),
                          trailing: Text(
                            '₹${e.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        )),
                    const Divider(height: 32),

                    // Payment modes
                    if (_paymentBreakdown != null &&
                        _paymentBreakdown!.isNotEmpty) ...[
                      Text('Payment Modes',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ..._paymentBreakdown!.entries.map((e) => ListTile(
                            leading: Icon(_paymentIcon(e.key)),
                            title: Text(e.key),
                            trailing: Text(
                              '₹${e.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }

  IconData _paymentIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'upi':
        return Icons.qr_code;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }
}
