/// Tests for A11y utility â€” currency formatting and stock status labels
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/core/utils/a11y.dart';

void main() {
  group('A11y.currency', () {
    test('formats positive amount', () {
      expect(A11y.currency(100), 'â‚¹100.00');
    });

    test('formats zero', () {
      expect(A11y.currency(0), 'â‚¹0.00');
    });

    test('formats decimal amount with 2 places', () {
      expect(A11y.currency(49.5), 'â‚¹49.50');
    });

    test('truncates to 2 decimal places', () {
      expect(A11y.currency(99.999), 'â‚¹100.00');
    });

    test('handles large amounts', () {
      expect(A11y.currency(100000), 'â‚¹100000.00');
    });

    test('handles negative amount', () {
      expect(A11y.currency(-50), 'â‚¹-50.00');
    });
  });

  group('A11y.stockStatus', () {
    test('out of stock', () {
      expect(A11y.stockStatus(0, false, true), 'Out of stock');
    });

    test('low stock shows remaining', () {
      expect(A11y.stockStatus(3, true, false), 'Low stock: 3 remaining');
    });

    test('normal stock shows count', () {
      expect(A11y.stockStatus(50, false, false), '50 in stock');
    });

    test('out of stock takes priority over low stock', () {
      // If both isOut and isLow are true, isOut wins (checked first)
      expect(A11y.stockStatus(0, true, true), 'Out of stock');
    });

    test('zero stock but not flagged as out', () {
      // Shows normal "0 in stock" if isOut flag is false
      expect(A11y.stockStatus(0, false, false), '0 in stock');
    });

    test('high stock value', () {
      expect(A11y.stockStatus(9999, false, false), '9999 in stock');
    });
  });
}
