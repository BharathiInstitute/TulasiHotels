/// GST export / report screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/billing/services/gst_service.dart';

class GstExportScreen extends ConsumerStatefulWidget {
  const GstExportScreen({super.key});

  @override
  ConsumerState<GstExportScreen> createState() => _GstExportScreenState();
}

class _GstExportScreenState extends ConsumerState<GstExportScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, double>? _gstSummary;
  Map<String, Map<String, double>>? _hsnBreakdown;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('GST Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month picker
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text(
                  '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: theme.textTheme.titleMedium,
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _pickMonth,
              ),
            ),
            const SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _generateReport,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate),
                label: const Text('Generate GST Summary'),
              ),
            ),
            const SizedBox(height: 24),

            // Summary card
            if (_gstSummary != null) ...[
              Text('GST Summary', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _summaryRow(
                        'Taxable Amount',
                        '₹${(_gstSummary!['totalTaxable'] ?? 0).toStringAsFixed(2)}',
                      ),
                      _summaryRow(
                        'CGST',
                        '₹${(_gstSummary!['totalCgst'] ?? 0).toStringAsFixed(2)}',
                      ),
                      _summaryRow(
                        'SGST',
                        '₹${(_gstSummary!['totalSgst'] ?? 0).toStringAsFixed(2)}',
                      ),
                      const Divider(),
                      _summaryRow(
                        'Total Tax',
                        '₹${(_gstSummary!['totalTax'] ?? 0).toStringAsFixed(2)}',
                        bold: true,
                      ),
                      _summaryRow(
                        'Total Revenue',
                        '₹${(_gstSummary!['totalRevenue'] ?? 0).toStringAsFixed(2)}',
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // HSN breakdown
            if (_hsnBreakdown != null && _hsnBreakdown!.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('HSN Breakdown', style: theme.textTheme.titleLarge),
                  TextButton.icon(
                    onPressed: _exportCsv,
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('HSN Code')),
                      DataColumn(label: Text('Taxable'), numeric: true),
                      DataColumn(label: Text('CGST'), numeric: true),
                      DataColumn(label: Text('SGST'), numeric: true),
                    ],
                    rows: _hsnBreakdown!.entries.map((entry) {
                      final vals = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text(entry.key)),
                          DataCell(
                            Text(
                              '₹${(vals['taxableAmount'] ?? 0).toStringAsFixed(2)}',
                            ),
                          ),
                          DataCell(
                            Text('₹${(vals['cgst'] ?? 0).toStringAsFixed(2)}'),
                          ),
                          DataCell(
                            Text('₹${(vals['sgst'] ?? 0).toStringAsFixed(2)}'),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: bold
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() => _loading = true);
    try {
      final start = DateTime(_selectedMonth.year, _selectedMonth.month);
      final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      final summary = await GstService.getGstSummary(start, end);
      final hsn = await GstService.getHsnBreakdown(start, end);
      setState(() {
        _gstSummary = summary;
        _hsnBreakdown = hsn;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _exportCsv() async {
    final bills = await GstService.getMonthlyBills(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final csv = GstService.generateGstCsv(bills);
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('GST CSV Export'),
        content: SingleChildScrollView(
          child: SelectableText(
            csv,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}
