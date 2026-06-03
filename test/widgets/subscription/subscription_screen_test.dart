import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/subscription/screens/subscription_screen.dart';

void main() {
  group('SubscriptionScreen', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = SubscriptionScreen();
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = SubscriptionScreen(key: Key('subscription'));
      expect(widget.key, const Key('subscription'));
    });
  });
}
