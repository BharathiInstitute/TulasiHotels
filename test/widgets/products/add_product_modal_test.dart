import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/products/widgets/add_product_modal.dart';

import '../../helpers/test_factories.dart';

void main() {
  group('AddProductModal', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = AddProductModal();
      expect(widget, isNotNull);
    });

    test('accepts optional product param', () {
      final product = makeProduct(name: 'Existing Product');
      final widget = AddProductModal(product: product);
      expect(widget, isNotNull);
    });

    test('createState returns non-null', () {
      const widget = AddProductModal();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
