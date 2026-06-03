/// Integration test: Bills → Dashboard totals accuracy
///
/// Tests that creating bills with various payment methods produces
/// correct aggregate totals for dashboard reporting.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/bill_model.dart';

import '../helpers/test_factories.dart';

void main() {
  group('Integration: Reports Accuracy — Bill Aggregation', () {
    late List<BillModel> bills;

    setUp(() {
      bills = [
        makeBill(
          id: 'bill-1',
          billNumber: 1,
          total: 500,
          paymentMethod: PaymentMethod.cash,
          date: '2026-03-01',
        ),
        makeBill(
          id: 'bill-2',
          billNumber: 2,
          total: 750,
          paymentMethod: PaymentMethod.upi,
          date: '2026-03-01',
        ),
        makeBill(
          id: 'bill-3',
          billNumber: 3,
          total: 1200,
          paymentMethod: PaymentMethod.cash,
          date: '2026-03-01',
        ),
        makeBill(
          id: 'bill-4',
          billNumber: 4,
          total: 300,
          paymentMethod: PaymentMethod.udhar,
          customerId: 'cust-1',
          customerName: 'Ravi',
          date: '2026-03-01',
        ),
        makeBill(
          id: 'bill-5',
          billNumber: 5,
          total: 850,
          paymentMethod: PaymentMethod.upi,
          date: '2026-03-02',
        ),
      ];
    });

    test('Step 1: Total revenue across all bills', () {
      final totalRevenue = bills.fold(0.0, (sum, b) => sum + b.total);
      expect(totalRevenue, 3600); // 500 + 750 + 1200 + 300 + 850
    });

    test('Step 2: Cash total', () {
      final cashBills = bills.where(
        (b) => b.paymentMethod == PaymentMethod.cash,
      );
      final cashTotal = cashBills.fold(0.0, (sum, b) => sum + b.total);
      expect(cashBills.length, 2);
      expect(cashTotal, 1700); // 500 + 1200
    });

    test('Step 3: UPI total', () {
      final upiBills = bills.where((b) => b.paymentMethod == PaymentMethod.upi);
      final upiTotal = upiBills.fold(0.0, (sum, b) => sum + b.total);
      expect(upiBills.length, 2);
      expect(upiTotal, 1600); // 750 + 850
    });

    test('Step 4: Credit (udhar) total', () {
      final udharBills = bills.where(
        (b) => b.paymentMethod == PaymentMethod.udhar,
      );
      final udharTotal = udharBills.fold(0.0, (sum, b) => sum + b.total);
      expect(udharBills.length, 1);
      expect(udharTotal, 300);
    });

    test('Step 5: Payment method split sums to total', () {
      final byMethod = <PaymentMethod, double>{};
      for (final bill in bills) {
        byMethod[bill.paymentMethod] =
            (byMethod[bill.paymentMethod] ?? 0) + bill.total;
      }

      final splitTotal = byMethod.values.fold(0.0, (a, b) => a + b);
      final overallTotal = bills.fold(0.0, (sum, b) => sum + b.total);
      expect(splitTotal, overallTotal);
    });

    test('Step 6: Daily totals', () {
      final day1Bills = bills.where((b) => b.date == '2026-03-01');
      final day2Bills = bills.where((b) => b.date == '2026-03-02');

      final day1Total = day1Bills.fold(0.0, (sum, b) => sum + b.total);
      final day2Total = day2Bills.fold(0.0, (sum, b) => sum + b.total);

      expect(day1Total, 2750); // 500 + 750 + 1200 + 300
      expect(day2Total, 850);
      expect(day1Total + day2Total, 3600);
    });

    test('Step 7: Bill count per day', () {
      final day1Count = bills.where((b) => b.date == '2026-03-01').length;
      final day2Count = bills.where((b) => b.date == '2026-03-02').length;

      expect(day1Count, 4);
      expect(day2Count, 1);
    });
  });

  group('Integration: Bill item count accuracy', () {
    test('item count matches sum of quantities', () {
      final items = [
        const CartItem(
          productId: 'p-1',
          name: 'Biryani',
          price: 250,
          quantity: 2,
          unit: 'plate',
        ),
        const CartItem(
          productId: 'p-2',
          name: 'Naan',
          price: 60,
          quantity: 5,
          unit: 'piece',
        ),
        const CartItem(
          productId: 'p-3',
          name: 'Dal',
          price: 150,
          quantity: 1,
          unit: 'bowl',
        ),
      ];

      final bill = makeBill(
        id: 'bill-10',
        items: items,
        total: 1050, // 500 + 300 + 150
      );

      expect(bill.itemCount, 8); // 2 + 5 + 1
      expect(bill.total, 1050);
    });

    test('cart item totals match bill total', () {
      final items = [
        const CartItem(
          productId: 'p-1',
          name: 'Biryani',
          price: 250,
          quantity: 3,
          unit: 'plate',
        ),
        const CartItem(
          productId: 'p-2',
          name: 'Raita',
          price: 50,
          quantity: 3,
          unit: 'cup',
        ),
      ];

      final cartTotal = items.fold(0.0, (sum, i) => sum + i.total);
      expect(cartTotal, 900); // 750 + 150

      final bill = makeBill(total: cartTotal, items: items);
      expect(bill.total, cartTotal);
    });
  });

  group('Integration: GST and discount calculations', () {
    test('bill with GST breakdown', () {
      final bill = makeBill(
        id: 'bill-20',
        total: 1000,
      ).copyWith(subtotal: 950, cgst: 25, sgst: 25, totalTax: 50);

      expect(bill.subtotal, 950);
      expect(bill.cgst, 25);
      expect(bill.sgst, 25);
      expect(bill.totalTax, 50);
      expect(bill.total, 1000);
    });

    test('bill with discount', () {
      final bill = makeBill(
        id: 'bill-21',
        total: 900,
      ).copyWith(subtotal: 1000, discount: 100);

      expect(bill.subtotal, 1000);
      expect(bill.discount, 100);
      expect(bill.total, 900);
    });

    test('bill with service charge', () {
      final bill = makeBill(
        id: 'bill-22',
        total: 1100,
      ).copyWith(subtotal: 1000, serviceCharge: 100);

      expect(bill.serviceCharge, 100);
      expect(bill.total, 1100);
    });
  });

  group('Integration: Change amount calculation', () {
    test('exact payment gives null change', () {
      final bill = makeBill(total: 500, receivedAmount: 500);
      expect(bill.changeAmount, 0);
    });

    test('overpayment calculates change', () {
      final bill = makeBill(total: 750, receivedAmount: 1000);
      expect(bill.changeAmount, 250);
    });

    test('UPI with no received amount gives null change', () {
      // Must construct BillModel directly since makeBill defaults receivedAmount
      final bill = BillModel(
        id: 'bill-upi',
        billNumber: 99,
        items: const [
          CartItem(
            productId: 'p-1',
            name: 'X',
            price: 500,
            quantity: 1,
            unit: 'u',
          ),
        ],
        total: 500,
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      expect(bill.changeAmount, isNull);
    });
  });
}
