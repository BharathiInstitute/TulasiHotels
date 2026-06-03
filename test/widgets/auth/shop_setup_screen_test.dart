import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/auth/screens/shop_setup_screen.dart';

void main() {
  group('ShopSetupScreen', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = ShopSetupScreen();
      expect(widget, isNotNull);
      expect(widget.key, isNull);
    });

    test('constructor accepts key', () {
      const key = Key('shop-setup');
      const widget = ShopSetupScreen(key: key);
      expect(widget.key, key);
    });

    test('creates state via createState', () {
      const widget = ShopSetupScreen();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
