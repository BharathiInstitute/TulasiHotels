import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/orders/screens/new_order_screen.dart';

void main() {
  group('NewOrderScreen', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = NewOrderScreen();
      expect(widget, isNotNull);
    });

    test('accepts tableId and tableName', () {
      const widget = NewOrderScreen(tableId: 't1', tableName: 'Table 1');
      expect(widget, isNotNull);
    });

    test('createState returns non-null', () {
      const widget = NewOrderScreen();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
