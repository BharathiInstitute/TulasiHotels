import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/khata/widgets/add_customer_modal.dart';
import 'package:tulasihotels/features/khata/widgets/give_udhaar_modal.dart';
import 'package:tulasihotels/features/khata/widgets/record_payment_modal.dart';

import '../../helpers/test_factories.dart';

void main() {
  group('AddCustomerModal', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = AddCustomerModal();
      expect(widget, isNotNull);
    });

    test('accepts optional customer param', () {
      final customer = makeCustomer();
      final widget = AddCustomerModal(customer: customer);
      expect(widget, isNotNull);
    });

    test('createState returns non-null', () {
      const widget = AddCustomerModal();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });

  group('GiveUdhaarModal', () {
    test('is a ConsumerStatefulWidget', () {
      final customer = makeCustomer();
      final widget = GiveUdhaarModal(customer: customer);
      expect(widget, isNotNull);
    });

    test('requires customer param', () {
      final customer = makeCustomer(name: 'Test Customer');
      final widget = GiveUdhaarModal(customer: customer);
      expect(widget, isNotNull);
    });

    test('createState returns non-null', () {
      final customer = makeCustomer();
      final widget = GiveUdhaarModal(customer: customer);
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });

  group('RecordPaymentModal', () {
    test('is a ConsumerStatefulWidget', () {
      final customer = makeCustomer();
      final widget = RecordPaymentModal(customer: customer);
      expect(widget, isNotNull);
    });

    test('requires customer param', () {
      final customer = makeCustomer(name: 'Payment Customer');
      final widget = RecordPaymentModal(customer: customer);
      expect(widget, isNotNull);
    });

    test('createState returns non-null', () {
      final customer = makeCustomer();
      final widget = RecordPaymentModal(customer: customer);
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
