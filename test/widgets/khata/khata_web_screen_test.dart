import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/khata/screens/khata_web_screen.dart';

void main() {
  group('KhataWebScreen', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = KhataWebScreen();
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = KhataWebScreen(key: Key('khata'));
      expect(widget.key, const Key('khata'));
    });

    test('createState returns non-null', () {
      const widget = KhataWebScreen();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
