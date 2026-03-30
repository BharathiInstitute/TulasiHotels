/// Salary management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/services/salary_service.dart';
import 'package:tulasihotels/models/staff_model.dart';

class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});

  @override
  ConsumerState<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends ConsumerState<SalaryScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<SalarySlip>? _slips;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickMonth,
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _selectedMonth = DateTime(
                        _selectedMonth.year, _selectedMonth.month - 1);
                    _slips = null;
                  }),
                ),
                Text(
                  '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _selectedMonth = DateTime(
                        _selectedMonth.year, _selectedMonth.month + 1);
                    _slips = null;
                  }),
                ),
              ],
            ),
          ),

          // Calculate button
          if (_slips == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: _loading
                    ? null
                    : () => _calculateAll(staffAsync.valueOrNull ?? []),
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate),
                label: const Text('Calculate Salaries'),
              ),
            ),

          // Results
          if (_slips != null)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _slips!.length,
                itemBuilder: (context, index) {
                  final slip = _slips![index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${slip.presentDays}'),
                      ),
                      title: Text(slip.staffName),
                      subtitle: Text(
                        '${slip.presentDays} days • ${slip.totalHours.toStringAsFixed(1)} hrs',
                      ),
                      trailing: Text(
                        '₹${slip.netSalary.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _showSlipDetail(context, slip),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _calculateAll(List<StaffModel> staffList) async {
    setState(() => _loading = true);
    try {
      final slips = <SalarySlip>[];
      for (final staff in staffList) {
        final slip = await SalaryService.calculateSalary(
          staffId: staff.id,
          staffName: staff.name,
          month: _selectedMonth,
          baseSalary: 15000, // Default — should be per-staff configurable
        );
        slips.add(slip);
      }
      setState(() => _slips = slips);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _slips = null;
      });
    }
  }

  void _showSlipDetail(BuildContext context, SalarySlip slip) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slip.staffName, style: theme.textTheme.headlineSmall),
              Text('${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: theme.textTheme.bodyMedium),
              const Divider(height: 24),
              _row('Total Days', '${slip.totalDays}'),
              _row('Present Days', '${slip.presentDays}'),
              _row('Total Hours', slip.totalHours.toStringAsFixed(1)),
              _row('Overtime Hours', slip.overtimeHours.toStringAsFixed(1)),
              const Divider(height: 24),
              _row('Base Salary', '₹${slip.baseSalary.toStringAsFixed(0)}'),
              _row('Overtime Pay', '₹${slip.overtimePay.toStringAsFixed(0)}'),
              _row('Deductions', '-₹${slip.deductions.toStringAsFixed(0)}'),
              _row('Advances', '-₹${slip.advances.toStringAsFixed(0)}'),
              const Divider(height: 24),
              _row(
                'Net Salary',
                '₹${slip.netSalary.toStringAsFixed(0)}',
                bold: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: bold
                  ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                  : null),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }
}
