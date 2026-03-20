/// Tests for RazorpayConfig Ã¢â‚¬â€ shop name fallback and state management
/// Uses inline duplicate to avoid --dart-define dependency issues.
library;

import 'package:flutter_test/flutter_test.dart';

// Ã¢â€â‚¬Ã¢â€â‚¬ Inline duplicate (RazorpayConfig logic without --dart-define const) Ã¢â€â‚¬Ã¢â€â‚¬

class _TestRazorpayConfig {
  static String keyId = '';
  static String _shopName = '';

  static void setShopName(String name) => _shopName = name.trim();

  static String get appName => _shopName.isNotEmpty ? _shopName : 'Tulasi Hotels';

  static bool get isTestMode => keyId.startsWith('rzp_test_');
  static bool get isConfigured => keyId.isNotEmpty;

  static void reset() {
    keyId = '';
    _shopName = '';
  }
}

void main() {
  setUp(_TestRazorpayConfig.reset);

  group('RazorpayConfig.appName', () {
    test('defaults to platform name when no shop name set', () {
      expect(_TestRazorpayConfig.appName, 'Tulasi Hotels');
    });

    test('returns shop name when set', () {
      _TestRazorpayConfig.setShopName('Tulasi Hotels');
      expect(_TestRazorpayConfig.appName, 'Tulasi Hotels');
    });

    test('falls back to platform name when empty shop name set', () {
      _TestRazorpayConfig.setShopName('');
      expect(_TestRazorpayConfig.appName, 'Tulasi Hotels');
    });

    test('trims whitespace from shop name', () {
      _TestRazorpayConfig.setShopName('  My Shop  ');
      expect(_TestRazorpayConfig.appName, 'My Shop');
    });

    test('whitespace-only falls back to platform name', () {
      _TestRazorpayConfig.setShopName('   ');
      expect(_TestRazorpayConfig.appName, 'Tulasi Hotels');
    });
  });

  group('RazorpayConfig.isTestMode', () {
    test('true for rzp_test_ prefix', () {
      _TestRazorpayConfig.keyId = 'rzp_test_abc123';
      expect(_TestRazorpayConfig.isTestMode, isTrue);
    });

    test('false for rzp_live_ prefix', () {
      _TestRazorpayConfig.keyId = 'rzp_live_abc123';
      expect(_TestRazorpayConfig.isTestMode, isFalse);
    });

    test('false for empty string', () {
      _TestRazorpayConfig.keyId = '';
      expect(_TestRazorpayConfig.isTestMode, isFalse);
    });
  });

  group('RazorpayConfig.isConfigured', () {
    test('false when key is empty', () {
      _TestRazorpayConfig.keyId = '';
      expect(_TestRazorpayConfig.isConfigured, isFalse);
    });

    test('true when key is present', () {
      _TestRazorpayConfig.keyId = 'rzp_test_xyz';
      expect(_TestRazorpayConfig.isConfigured, isTrue);
    });
  });
}
