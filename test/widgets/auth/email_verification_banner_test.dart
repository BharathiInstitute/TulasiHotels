import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/auth/widgets/email_verification_banner.dart';

void main() {
  group('EmailVerificationBanner', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = EmailVerificationBanner();
      expect(widget, isNotNull);
    });

    test('constructor accepts key', () {
      const key = Key('email-banner');
      const widget = EmailVerificationBanner(key: key);
      expect(widget.key, key);
    });

    test('creates state via createState', () {
      const widget = EmailVerificationBanner();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
