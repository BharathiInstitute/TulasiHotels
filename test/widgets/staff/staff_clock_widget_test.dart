import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/widgets/staff_clock_widget.dart';

void main() {
  group('StaffClockWidget', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = StaffClockWidget();
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = StaffClockWidget(key: Key('clock'));
      expect(widget.key, const Key('clock'));
    });

    test('createState returns non-null', () {
      const widget = StaffClockWidget();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
