import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/settings/widgets/edit_shop_modal.dart';

void main() {
  group('EditShopModal', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = EditShopModal();
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = EditShopModal(key: Key('edit-shop'));
      expect(widget.key, const Key('edit-shop'));
    });

    test('createState returns non-null', () {
      const widget = EditShopModal();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
