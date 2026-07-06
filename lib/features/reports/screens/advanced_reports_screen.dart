/// Advanced reports / unified analytics dashboard screen
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemCount: _ReportTab.values.length,
              itemBuilder: (context, index) {
                final tab = _ReportTab.values[index];
                final isSelected = tab == _selectedTab;
                final isMobile = MediaQuery.of(context).size.width < 600;
                if (isMobile) {
                  return Tooltip(
                    message: tab.label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _onTabSelected(tab),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Icon(
                          tab.icon,
                          size: 20,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                }
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

  void _showExportError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedTab == _ReportTab.overview && _dailyRevenue == null) {
      _showExportError('No data loaded. Please load reports first.');
      return;
    }

    try {
      final pdf = pw.Document();
      final tabName = _selectedTab.label;
      final dateRange =
          '${_range.start.day}/${_range.start.month}/${_range.start.year} - ${_range.end.day}/${_range.end.month}/${_range.end.year}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Tulasi Restaurants - $tabName Report',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Date Range: $dateRange',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),
            ],
          ),
          build: (context) => _buildPdfContent(tabName),
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: '$tabName Report.pdf');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final exportDir = Directory('${dir.path}/Tulasi Restaurants_Exports');
        if (!exportDir.existsSync()) {
          exportDir.createSync(recursive: true);
        }
        final fileName =
            '${tabName.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${exportDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (mounted) {
          await Share.shareXFiles([
            XFile(file.path),
          ], subject: '$tabName Report');
        }
      }
    } catch (e) {
      _showExportError('PDF export failed: $e');
    }
  }

  List<pw.Widget> _buildPdfContent(String tabName) {
    final widgets = <pw.Widget>[];

    if (_selectedTab == _ReportTab.overview) {
      // Daily Revenue table
      if (_dailyRevenue != null && _dailyRevenue!.isNotEmpty) {
        widgets.add(
          pw.Text(
            'Daily Revenue',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        );
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(4),
            headers: ['Date', 'Revenue (₹)'],
            data: _dailyRevenue!.entries
                .map((e) => [e.key, e.value.toStringAsFixed(2)])
                .toList(),
          ),
        );
        widgets.add(pw.SizedBox(height: 16));
      }

      // Top Products table
      if (_topProducts != null && _topProducts!.isNotEmpty) {
        widgets.add(
          pw.Text(
            'Top Products',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        );
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(4),
            headers: ['#', 'Name', 'Qty', 'Revenue (₹)'],
            data: List.generate(_topProducts!.length, (i) {
              final p = _topProducts![i];
              return [
                '${i + 1}',
                p['name'] ?? '',
                '${p['quantity'] ?? 0}',
                (p['revenue'] as num?)?.toStringAsFixed(2) ?? '0',
              ];
            }),
          ),
        );
        widgets.add(pw.SizedBox(height: 16));
      }

      // Payment Breakdown
      if (_paymentBreakdown != null && _paymentBreakdown!.isNotEmpty) {
        widgets.add(
          pw.Text(
            'Payment Methods',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        );
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(4),
            headers: ['Method', 'Amount (₹)'],
            data: _paymentBreakdown!.entries
                .map((e) => [e.key, e.value.toStringAsFixed(2)])
                .toList(),
          ),
        );
        widgets.add(pw.SizedBox(height: 16));
      }

      // Hourly Orders
      if (_hourlyOrders != null && _hourlyOrders!.isNotEmpty) {
        widgets.add(
          pw.Text(
            'Hourly Orders',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        );
        widgets.add(pw.SizedBox(height: 6));
        final sorted = _hourlyOrders!.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        widgets.add(
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(4),
            headers: ['Hour', 'Orders'],
            data: sorted.map((e) => ['${e.key}:00', '${e.value}']).toList(),
          ),
        );
      }
    } else {
      widgets.add(
        pw.Text(
          'Report: $tabName',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      );
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(
        pw.Text(
          'For detailed sub-report data, use the CSV export option.',
          style: const pw.TextStyle(fontSize: 11),
        ),
      );
    }

    return widgets;
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
