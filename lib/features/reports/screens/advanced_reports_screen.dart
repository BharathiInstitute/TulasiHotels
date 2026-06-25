/// Advanced reports / unified analytics dashboard screen
library;

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tulasihotels/features/reports/services/advanced_reports_service.dart';
import 'package:tulasihotels/features/reports/screens/menu_performance_screen.dart';
import 'package:tulasihotels/features/reports/screens/weekly_report_screen.dart';
import 'package:tulasihotels/features/reports/screens/pnl_report_screen.dart';
import 'package:tulasihotels/features/reports/screens/peak_hours_screen.dart';
import 'package:tulasihotels/features/reports/screens/item_sales_screen.dart';
import 'package:tulasihotels/features/reports/screens/comparative_screen.dart';
import 'package:tulasihotels/features/reports/screens/feedback_report_screen.dart';
import 'package:tulasihotels/features/billing/screens/gst_export_screen.dart';

enum _ReportTab {
  overview('Overview', Icons.analytics),
  menuPerformance('Menu Performance', Icons.restaurant_menu),
  weeklyReport('Weekly Report', Icons.calendar_view_week),
  pnlReport('P&L Report', Icons.account_balance),
  peakHours('Peak Hours', Icons.schedule),
  itemSales('Item Sales', Icons.shopping_bag),
  comparative('Comparative', Icons.compare_arrows),
  feedbackReport('Feedback Report', Icons.star),
  gstExport('GST Export', Icons.description);

  final String label;
  final IconData icon;
  const _ReportTab(this.label, this.icon);
}

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
  _ReportTab _selectedTab = _ReportTab.overview;

  Map<String, double>? _dailyRevenue;
  List<Map<String, dynamic>>? _topProducts;
  Map<String, double>? _paymentBreakdown;
  Map<String, int>? _orderTypeDistribution;
  Map<int, int>? _hourlyOrders;
  List<Map<String, dynamic>>? _waiterPerformance;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            onPressed: _exportCurrentReport,
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export as CSV',
          ),
          TextButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              '${_range.start.day}/${_range.start.month} - ${_range.end.day}/${_range.end.month}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Report type chips
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: _ReportTab.values.length,
              itemBuilder: (context, index) {
                final tab = _ReportTab.values[index];
                final isSelected = tab == _selectedTab;
                return FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: Icon(tab.icon, size: 16),
                  label: Text(tab.label, style: const TextStyle(fontSize: 12)),
                  onSelected: (_) => _onTabSelected(tab),
                );
              },
            ),
          ),

          // Report content
          Expanded(
            child: _selectedTab == _ReportTab.overview
                ? (_loading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildReportContent(theme))
                : _buildSelectedReport(),
          ),
        ],
      ),
    );
  }

  void _onTabSelected(_ReportTab tab) {
    setState(() => _selectedTab = tab);
  }

  Widget _buildSelectedReport() {
    return switch (_selectedTab) {
      _ReportTab.menuPerformance => const MenuPerformanceScreen(),
      _ReportTab.weeklyReport => const WeeklyReportScreen(),
      _ReportTab.pnlReport => const PnlReportScreen(),
      _ReportTab.peakHours => const PeakHoursScreen(),
      _ReportTab.itemSales => const ItemSalesScreen(),
      _ReportTab.comparative => const ComparativeScreen(),
      _ReportTab.feedbackReport => const FeedbackReportScreen(),
      _ReportTab.gstExport => const GstExportScreen(),
      _ReportTab.overview => const SizedBox.shrink(),
    };
  }

  Widget _buildReportContent(ThemeData theme) {
    if (_dailyRevenue == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: _loadReports,
          icon: const Icon(Icons.analytics),
          label: const Text('Load Analytics'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards row
        _buildSummaryCards(theme),
        const SizedBox(height: 24),

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
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                SizedBox(width: 48, child: Text(label)),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: maxVal > 0 ? e.value / maxVal : 0,
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
        if (_waiterPerformance != null && _waiterPerformance!.isNotEmpty) ...[
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
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    final totalRevenue = _dailyRevenue?.values.fold(0.0, (a, b) => a + b) ?? 0;
    final totalOrders =
        _orderTypeDistribution?.values.fold(0, (a, b) => a + b) ?? 0;
    final topProduct = _topProducts?.isNotEmpty == true
        ? (_topProducts!.first['name'] as String?) ?? '-'
        : '-';

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Revenue', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    '₹${totalRevenue.toStringAsFixed(0)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Orders', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    '$totalOrders',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top Seller', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    topProduct,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportCurrentReport() async {
    final rows = <List<dynamic>>[];
    final tabName = _selectedTab.label;

    switch (_selectedTab) {
      case _ReportTab.overview:
        if (_dailyRevenue == null) {
          _showExportError('No data loaded. Please wait for reports to load.');
          return;
        }
        rows.add(['Report', 'Overview']);
        rows.add([
          'Date Range',
          '${_range.start.day}/${_range.start.month}/${_range.start.year} - ${_range.end.day}/${_range.end.month}/${_range.end.year}',
        ]);
        rows.add([]);
        // Daily revenue
        rows.add(['Daily Revenue']);
        rows.add(['Date', 'Revenue']);
        for (final e in _dailyRevenue!.entries) {
          rows.add([e.key, e.value.toStringAsFixed(2)]);
        }
        rows.add([]);
        // Top products
        if (_topProducts != null) {
          rows.add(['Top Products']);
          rows.add(['Rank', 'Name', 'Quantity', 'Revenue']);
          for (var i = 0; i < _topProducts!.length; i++) {
            final p = _topProducts![i];
            rows.add([
              i + 1,
              p['name'] ?? '',
              p['quantity'] ?? 0,
              (p['revenue'] as num?)?.toStringAsFixed(2) ?? '0',
            ]);
          }
          rows.add([]);
        }
        // Payment breakdown
        if (_paymentBreakdown != null) {
          rows.add(['Payment Methods']);
          rows.add(['Method', 'Amount']);
          for (final e in _paymentBreakdown!.entries) {
            rows.add([e.key, e.value.toStringAsFixed(2)]);
          }
          rows.add([]);
        }
        // Hourly orders
        if (_hourlyOrders != null) {
          rows.add(['Hourly Orders']);
          rows.add(['Hour', 'Orders']);
          final sorted = _hourlyOrders!.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          for (final e in sorted) {
            rows.add(['${e.key}:00', e.value]);
          }
        }
      case _ReportTab.menuPerformance:
      case _ReportTab.weeklyReport:
      case _ReportTab.pnlReport:
      case _ReportTab.peakHours:
      case _ReportTab.itemSales:
      case _ReportTab.comparative:
      case _ReportTab.feedbackReport:
      case _ReportTab.gstExport:
        // For sub-tabs, export bills for the range
        final bills = await AdvancedReportsService.getBillsInRange(
          _range.start,
          _range.end,
        );
        if (bills.isEmpty) {
          _showExportError('No data found in the selected date range.');
          return;
        }
        rows.add(['Report', tabName]);
        rows.add([
          'Date Range',
          '${_range.start.day}/${_range.start.month}/${_range.start.year} - ${_range.end.day}/${_range.end.month}/${_range.end.year}',
        ]);
        rows.add([]);
        rows.add([
          'Bill Number',
          'Date',
          'Items',
          'Total',
          'Payment Method',
          'Customer',
        ]);
        for (final bill in bills) {
          rows.add([
            bill.billNumber,
            bill.date,
            bill.items.map((i) => '${i.name} x${i.quantity}').join('; '),
            bill.total.toStringAsFixed(2),
            bill.paymentMethod.name,
            bill.customerName ?? '',
          ]);
        }
    }

    if (rows.isEmpty) {
      _showExportError('No data to export.');
      return;
    }

    try {
      final csvContent = const ListToCsvConverter().convert(rows);
      final fileName =
          '${tabName.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';

      if (kIsWeb) {
        // Web: download via data URI isn't ideal, try share
        await Share.share(csvContent, subject: '$fileName.csv');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final exportDir = Directory('${dir.path}/Tulasi Hotels_Exports');
        if (!exportDir.existsSync()) {
          exportDir.createSync(recursive: true);
        }
        final file = File('${exportDir.path}/$fileName.csv');
        await file.writeAsString(csvContent);

        if (mounted) {
          await Share.shareXFiles([
            XFile(file.path),
          ], subject: '$tabName Report');
        }
      }
    } catch (e) {
      _showExportError('Export failed: $e');
    }
  }

  void _showExportError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
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
      if (mounted) {
        setState(() {
          _dailyRevenue = results[0] as Map<String, double>;
          _topProducts = results[1] as List<Map<String, dynamic>>;
          _paymentBreakdown = results[2] as Map<String, double>;
          _orderTypeDistribution = results[3] as Map<String, int>;
          _hourlyOrders = results[4] as Map<int, int>;
          _waiterPerformance = results[5] as List<Map<String, dynamic>>;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
