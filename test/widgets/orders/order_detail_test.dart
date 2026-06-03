import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/orders/screens/order_detail_screen.dart';

void main() {
  group('OrderDetailScreen', () {
    test('is a ConsumerWidget', () {
      const widget = OrderDetailScreen(orderId: 'order-123');
      expect(widget, isNotNull);
    });

    test('requires orderId', () {
      const widget = OrderDetailScreen(orderId: 'abc');
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = OrderDetailScreen(
        key: Key('detail'),
        orderId: 'order-1',
      );
      expect(widget.key, const Key('detail'));
    });
  });
}
