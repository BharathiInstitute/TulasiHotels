/// Order billing screen — generate bill from a completed order
/// Shows order summary, discount/service charge controls, payment method selection
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/services/print_helper.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/billing/services/billing_service.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/orders/screens/order_detail_screen.dart';
import 'package:tulasihotels/features/orders/services/order_service.dart';
import 'package:tulasihotels/features/settings/providers/printer_provider.dart';
import 'package:tulasihotels/features/coupons/providers/coupon_provider.dart';
import 'package:tulasihotels/features/coupons/services/coupon_service.dart';
import 'package:tulasihotels/router/app_router.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/coupon_model.dart';
import 'package:tulasihotels/models/order_model.dart';

class OrderBillingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderBillingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderBillingScreen> createState() => _OrderBillingScreenState();
}

class _OrderBillingScreenState extends ConsumerState<OrderBillingScreen> {
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  CouponModel? _selectedCoupon;
  double _couponDiscount = 0;
  double _serviceChargePercent = 0;
  bool _isProcessing = false;
  bool _isValidatingCoupon = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final theme = Theme.of(context);
    final billingPermissions = ref.watch(
      routePermissionProvider(AppRoutes.billing),
    );

    return orderAsync.when(
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Generate Bill')),
            body: const Center(child: Text('Order not found')),
          );
        }

        final subtotal = order.total;
        final serviceCharge = subtotal * _serviceChargePercent / 100;
        final total = subtotal - _couponDiscount + serviceCharge;

        return Scaffold(
          appBar: AppBar(title: Text('Bill — Order #${order.orderNumber}')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Order info card
              _OrderInfoCard(order: order),
              const SizedBox(height: 16),

              // Items list
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Items', style: theme.textTheme.titleMedium),
                    ),
                    ...order.items.map(
                      (item) => ListTile(
                        dense: true,
                        title: Text(item.name),
                        subtitle: item.itemNotes != null
                            ? Text(
                                item.itemNotes!,
                                style: theme.textTheme.bodySmall,
                              )
                            : null,
                        trailing: Text(
                          '${item.quantity} × ?${item.price.toStringAsFixed(0)} = ?${item.total.toStringAsFixed(0)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: theme.textTheme.titleSmall),
                          Text(
                            '?${subtotal.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Discount & Service Charge
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Adjustments', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),

                      // Coupon
                      ref
                          .watch(allCouponsProvider)
                          .when(
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) =>
                                const Text('Could not load coupons'),
                            data: (coupons) {
                              final activeCoupons = coupons
                                  .where((c) => c.isActive)
                                  .toList();
                              return Row(
                                children: [
                                  const Expanded(
                                    flex: 2,
                                    child: Text('Coupon'),
                                  ),
                                  Expanded(
                                    child: _isValidatingCoupon
                                        ? const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : DropdownButtonFormField<CouponModel?>(
                                            initialValue: _selectedCoupon,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                            ),
                                            hint: const Text('None'),
                                            items: [
                                              const DropdownMenuItem<
                                                CouponModel?
                                              >(child: Text('None')),
                                              ...activeCoupons.map(
                                                (
                                                  c,
                                                ) => DropdownMenuItem<CouponModel?>(
                                                  value: c,
                                                  child: Text(
                                                    '${c.code} · ${c.type == CouponType.percentage ? '${c.value.toStringAsFixed(0)}%' : '₹${c.value.toStringAsFixed(0)}'}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (coupon) async {
                                              if (coupon == null) {
                                                setState(() {
                                                  _selectedCoupon = null;
                                                  _couponDiscount = 0;
                                                });
                                                return;
                                              }
                                              final messenger =
                                                  ScaffoldMessenger.of(context);
                                              setState(
                                                () =>
                                                    _isValidatingCoupon = true,
                                              );
                                              final validated =
                                                  await CouponService.validateCoupon(
                                                    coupon.code,
                                                    subtotal,
                                                  );
                                              if (mounted) {
                                                setState(() {
                                                  _isValidatingCoupon = false;
                                                  if (validated != null) {
                                                    _selectedCoupon = coupon;
                                                    _couponDiscount = validated
                                                        .calculateDiscount(
                                                          subtotal,
                                                        );
                                                  } else {
                                                    _selectedCoupon = null;
                                                    _couponDiscount = 0;
                                                  }
                                                });
                                                if (validated == null) {
                                                  messenger.showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Coupon is invalid or expired',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                  ),
                                ],
                              );
                            },
                          ),
                      const SizedBox(height: 12),

                      // Service charge
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text('Service Charge (%)'),
                          ),
                          Expanded(
                            child: DropdownButtonFormField<double>(
                              initialValue: _serviceChargePercent,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('None')),
                                DropdownMenuItem(value: 5, child: Text('5%')),
                                DropdownMenuItem(value: 10, child: Text('10%')),
                              ],
                              onChanged: (v) => setState(
                                () => _serviceChargePercent = v ?? 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment method
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<PaymentMethod>(
                        segments: [
                          ButtonSegment(
                            value: PaymentMethod.cash,
                            label: Text(PaymentMethod.cash.displayName),
                            icon: const Icon(Icons.money),
                          ),
                          ButtonSegment(
                            value: PaymentMethod.upi,
                            label: Text(PaymentMethod.upi.displayName),
                            icon: const Icon(Icons.phone_android),
                          ),
                          ButtonSegment(
                            value: PaymentMethod.udhar,
                            label: Text(PaymentMethod.udhar.displayName),
                            icon: const Icon(Icons.credit_card),
                          ),
                        ],
                        selected: {_paymentMethod},
                        onSelectionChanged: (s) =>
                            setState(() => _paymentMethod = s.first),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Totals summary
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SummaryRow('Subtotal', subtotal),
                      if (_couponDiscount > 0)
                        _SummaryRow(
                          'Coupon (${_selectedCoupon?.code})',
                          -_couponDiscount,
                        ),
                      if (serviceCharge > 0)
                        _SummaryRow(
                          'Service Charge (${_serviceChargePercent.toStringAsFixed(0)}%)',
                          serviceCharge,
                        ),
                      const Divider(),
                      _SummaryRow('Total', total, isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Generate Bill button
              FilledButton.icon(
                onPressed: _isProcessing || !billingPermissions.canCreate
                    ? null
                    : () => _generateBill(order, total),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long),
                label: Text(
                  _isProcessing
                      ? 'Processing...'
                      : 'Generate Bill — ?${total.toStringAsFixed(0)}',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Generate Bill')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Generate Bill')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _generateBill(OrderModel order, double total) async {
    final permissions = ref.read(routePermissionProvider(AppRoutes.billing));
    if (!permissions.canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to create bills.'),
        ),
      );
      return;
    }

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill total must be greater than zero')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final bill = await BillingService.createBillFromOrder(
        order: order,
        paymentMethod: _paymentMethod,
        discount: _couponDiscount,
        serviceChargePercent: _serviceChargePercent,
      );

      // Mark coupon as used
      if (_selectedCoupon != null) {
        unawaited(CouponService.applyCoupon(_selectedCoupon!.id));
      }

      // Mark order as billed and free the table
      await OrderService.completeOrder(order.id);

      if (mounted) {
        final printerState = ref.read(printerProvider);
        final messenger = ScaffoldMessenger.of(context);

        // Auto-print if enabled
        if (printerState.autoPrint) {
          unawaited(_printReceipt(bill, messenger));
        }

        Navigator.pop(context);

        // Show success with print option
        _showBillCompleteDialog(bill);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printReceipt(
    BillModel bill,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    final user = ref.read(currentUserProvider);
    final printerState = ref.read(printerProvider);

    await PrintHelper.printReceipt(
      bill: bill,
      printerState: printerState,
      user: user,
      scaffoldMessenger: scaffoldMessenger,
      onRetry: () => _printReceipt(bill, scaffoldMessenger),
    );
  }

  void _showBillCompleteDialog(BillModel bill) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                'Bill Generated!',
                style: Theme.of(dialogContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Bill No: #${bill.billNumber}'),
              Text(
                '\u{20B9}${bill.total.toStringAsFixed(0)}',
                style: Theme.of(dialogContext).textTheme.headlineSmall
                    ?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(dialogContext);
                        await _printReceipt(bill, messenger);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  final OrderModel order;

  const _OrderInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Order #${order.orderNumber}',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Chip(
                  label: Text(order.orderType.displayName),
                  avatar: Text(order.orderType.emoji),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (order.tableName != null) ...[
                  const Icon(Icons.table_restaurant, size: 16),
                  const SizedBox(width: 4),
                  Text(order.tableName!),
                  const SizedBox(width: 16),
                ],
                if (order.waiterName != null) ...[
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Text(order.waiterName!),
                ],
                const Spacer(),
                Text(
                  '${order.items.length} items',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;

  const _SummaryRow(this.label, this.amount, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '${amount < 0 ? '-' : ''}?${amount.abs().toStringAsFixed(2)}',
            style: style,
          ),
        ],
      ),
    );
  }
}
