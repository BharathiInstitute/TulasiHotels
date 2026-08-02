/// Tests for SubscriptionPricing — pure pricing logic
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/subscription/services/subscription_service.dart';

void main() {
  group('SubscriptionPricing.getPrice', () {
    test('pro monthly returns 20', () {
      expect(SubscriptionPricing.getPrice('pro', 'monthly'), 20);
    });

    test('pro annual returns 204', () {
      expect(SubscriptionPricing.getPrice('pro', 'annual'), 204);
    });

    test('business monthly returns 30', () {
      expect(SubscriptionPricing.getPrice('business', 'monthly'), 30);
    });

    test('business annual returns 300', () {
      expect(SubscriptionPricing.getPrice('business', 'annual'), 300);
    });

    test('unknown plan returns 0', () {
      expect(SubscriptionPricing.getPrice('enterprise', 'monthly'), 0);
    });

    test('unknown cycle returns 0', () {
      expect(SubscriptionPricing.getPrice('pro', 'weekly'), 0);
    });

    test('both unknown returns 0', () {
      expect(SubscriptionPricing.getPrice('unknown', 'unknown'), 0);
    });
  });
}
