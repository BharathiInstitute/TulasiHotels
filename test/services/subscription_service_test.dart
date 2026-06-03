/// Tests for SubscriptionPricing — pure pricing logic
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/subscription/services/subscription_service.dart';

void main() {
  group('SubscriptionPricing.getPrice', () {
    test('pro monthly returns 299', () {
      expect(SubscriptionPricing.getPrice('pro', 'monthly'), 299);
    });

    test('pro annual returns 2999', () {
      expect(SubscriptionPricing.getPrice('pro', 'annual'), 2999);
    });

    test('business monthly returns 999', () {
      expect(SubscriptionPricing.getPrice('business', 'monthly'), 999);
    });

    test('business annual returns 9999', () {
      expect(SubscriptionPricing.getPrice('business', 'annual'), 9999);
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
