import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/billing/widgets/payment_modal.dart';

void main() {
  group('PaymentModal', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = PaymentModal();
      expect(widget, isNotNull);
    });

    test('creates state', () {
      const widget = PaymentModal();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
