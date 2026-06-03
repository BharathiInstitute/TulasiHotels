import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/settings/screens/billing_settings_screen.dart';

void main() {
  group('BillingSettingsScreen', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = BillingSettingsScreen();
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = BillingSettingsScreen(key: Key('billing-settings'));
      expect(widget.key, const Key('billing-settings'));
    });

    test('createState returns non-null', () {
      const widget = BillingSettingsScreen();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
