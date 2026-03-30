/// Billing service for bills
/// Supports demo mode with local in-memory data
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/services/demo_data_service.dart';
import 'package:tulasihotels/core/services/offline_storage_service.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/order_model.dart';

/// Today's bills provider - reads from demo data or Firestore
final todayBillsProvider = FutureProvider<List<BillModel>>((ref) async {
  final isDemoMode = ref.watch(isDemoModeProvider);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  if (isDemoMode) {
    return DemoDataService.getBillsInRange(startOfDay, endOfDay);
  }

  final bills = await OfflineStorageService.getCachedBillsInRange(
    startOfDay,
    endOfDay,
  );
  return bills;
});

/// Today's summary provider — derives from todayBillsProvider to avoid duplicate fetch
final todaySummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final todayBills = await ref.watch(todayBillsProvider.future);

  double totalSales = 0;
  double cashAmount = 0;
  double upiAmount = 0;
  double udharAmount = 0;

  for (final bill in todayBills) {
    totalSales += bill.total;
    switch (bill.paymentMethod) {
      case PaymentMethod.cash:
        cashAmount += bill.total;
        break;
      case PaymentMethod.upi:
        upiAmount += bill.total;
        break;
      case PaymentMethod.udhar:
        udharAmount += bill.total;
        break;
      case PaymentMethod.unknown:
        break;
    }
  }

  return {
    'totalSales': totalSales,
    'billCount': todayBills.length,
    'cashAmount': cashAmount,
    'upiAmount': upiAmount,
    'udharAmount': udharAmount,
  };
});

/// Shared billing service for bill creation (2.4)
/// Extracted from pos_web_screen and payment_modal to avoid duplication.
class BillingService {
  /// Create a BillModel and persist it.
  /// Returns the saved [BillModel] or throws on failure.
  static Future<BillModel> createAndSaveBill({
    required List<CartItem> items,
    required double total,
    required PaymentMethod paymentMethod,
    String? customerId,
    String? customerName,
    double? receivedAmount,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final bill = BillModel(
      id: generateSafeId('bill'),
      billNumber: await OfflineStorageService.getNextBillNumber(),
      items: items,
      total: total,
      paymentMethod: paymentMethod,
      customerId: customerId,
      customerName: customerName,
      receivedAmount: receivedAmount ?? total,
      createdAt: now,
      date: dateStr,
    );

    await OfflineStorageService.saveBillLocally(bill);

    // Handle Udhar customer balance + transaction
    if (paymentMethod == PaymentMethod.udhar && customerId != null) {
      await OfflineStorageService.updateCustomerBalance(customerId, total);
      await OfflineStorageService.saveTransaction(
        customerId: customerId,
        type: 'purchase',
        amount: total,
        billId: bill.id,
      );
    }

    return bill;
  }

  /// Create a bill from a completed hotel order.
  /// Converts OrderItems → CartItems, applies discount & service charge,
  /// saves the bill, and returns it.
  static Future<BillModel> createBillFromOrder({
    required OrderModel order,
    required PaymentMethod paymentMethod,
    double discount = 0,
    double serviceChargePercent = 0,
    String? customerId,
    String? customerName,
    double? receivedAmount,
  }) async {
    final cartItems = order.items.map((e) => e.toCartItem()).toList();
    final subtotal = order.total;
    final serviceCharge = subtotal * serviceChargePercent / 100;
    final total = subtotal - discount + serviceCharge;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final bill = BillModel(
      id: generateSafeId('bill'),
      billNumber: await OfflineStorageService.getNextBillNumber(),
      items: cartItems,
      total: total,
      paymentMethod: paymentMethod,
      customerId: customerId,
      customerName: customerName,
      receivedAmount: receivedAmount ?? total,
      createdAt: now,
      date: dateStr,
      orderId: order.id,
      tableId: order.tableId,
      tableName: order.tableName,
      waiterId: order.waiterId,
      waiterName: order.waiterName,
      orderType: order.orderType.name,
      subtotal: subtotal,
      discount: discount,
      serviceCharge: serviceCharge,
    );

    if (paymentMethod == PaymentMethod.udhar && customerId != null) {
      await OfflineStorageService.saveBillWithUdharAtomic(
        bill: bill,
        customerId: customerId,
        amount: total,
      );
    } else {
      await OfflineStorageService.saveBillLocally(bill);
    }

    return bill;
  }

  /// Create multiple split bills from an order
  static Future<List<BillModel>> createSplitBills({
    required OrderModel order,
    required List<List<OrderItem>> splits,
    required PaymentMethod paymentMethod,
    double discountPercent = 0,
  }) async {
    final bills = <BillModel>[];
    final parentId = generateSafeId('bill');
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (var i = 0; i < splits.length; i++) {
      final splitItems = splits[i];
      final cartItems = splitItems.map((e) => e.toCartItem()).toList();
      final subtotal =
          splitItems.fold<double>(0, (s, item) => s + item.price * item.quantity);
      final discount = subtotal * discountPercent / 100;
      final total = subtotal - discount;

      final bill = BillModel(
        id: i == 0 ? parentId : generateSafeId('bill'),
        billNumber: await OfflineStorageService.getNextBillNumber(),
        items: cartItems,
        total: total,
        paymentMethod: paymentMethod,
        createdAt: now,
        date: dateStr,
        orderId: order.id,
        tableId: order.tableId,
        tableName: order.tableName,
        waiterId: order.waiterId,
        waiterName: order.waiterName,
        orderType: order.orderType.name,
        subtotal: subtotal,
        discount: discount,
        parentBillId: i == 0 ? null : parentId,
        splitIndex: i + 1,
      );

      await OfflineStorageService.saveBillLocally(bill);
      bills.add(bill);
    }

    return bills;
  }
}
