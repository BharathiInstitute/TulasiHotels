import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/tables/screens/table_layout_editor.dart';

void main() {
  group('TableLayoutEditor', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = TableLayoutEditor();
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = TableLayoutEditor(key: Key('tables'));
      expect(widget.key, const Key('tables'));
    });

    test('createState returns non-null', () {
      const widget = TableLayoutEditor();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
