/// Peak hours analysis — heatmap-style display of busiest hours
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/reports/services/advanced_reports_service.dart';

class PeakHoursScreen extends ConsumerStatefulWidget {
  const PeakHoursScreen({super.key});

  @override
  ConsumerState<PeakHoursScreen> createState() => _PeakHoursScreenState();
}

class _PeakHoursScreenState extends ConsumerState<PeakHoursScreen> {
  Map<int, int>? _hourlyOrders;
  bool _loading = false;
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await AdvancedReportsService.hourlyOrderCounts(
      _range.start,
      _range.end,
    );
    if (mounted) {
      setState(() {
        _hourlyOrders = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peak Hours'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hourlyOrders == null
          ? Center(
              child: FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.access_time),
                label: const Text('Analyze Peak Hours'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Orders by Hour', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                ..._buildHourRows(theme),
              ],
            ),
    );
  }

  List<Widget> _buildHourRows(ThemeData theme) {
    final maxOrders = _hourlyOrders!.values.fold(0, (a, b) => a > b ? a : b);

    return List.generate(24, (hour) {
      final count = _hourlyOrders![hour] ?? 0;
      final fraction = maxOrders > 0 ? count / maxOrders : 0.0;
      final label = '${hour.toString().padLeft(2, '0')}:00';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 50, child: Text(label)),
            Expanded(
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 20,
                backgroundColor: Colors.grey.shade200,
                color: _heatColor(fraction),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '$count',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: fraction > 0.7
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Color _heatColor(double fraction) {
    if (fraction > 0.75) return Colors.red;
    if (fraction > 0.5) return Colors.orange;
    if (fraction > 0.25) return Colors.amber;
    return Colors.green;
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
