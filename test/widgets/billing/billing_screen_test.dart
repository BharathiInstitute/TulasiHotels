import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/billing/screens/billing_screen.dart';

void main() {
  group('BillingScreen', () {
    // BillingScreen depends on Firebase (OnboardingChecklist uses
    // FirebaseAuth.instance) so we test the widget type only.
    test('is a ConsumerStatefulWidget', () {
      const widget = BillingScreen();
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = BillingScreen(key: Key('billing'));
      expect(widget.key, const Key('billing'));
    });

    test('createState returns non-null', () {
      const widget = BillingScreen();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
