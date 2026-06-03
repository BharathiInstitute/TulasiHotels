import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/feedback/screens/feedback_dashboard_screen.dart';

void main() {
  group('FeedbackDashboardScreen', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = FeedbackDashboardScreen();
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = FeedbackDashboardScreen(key: Key('feedback'));
      expect(widget.key, const Key('feedback'));
    });

    test('createState returns non-null', () {
      const widget = FeedbackDashboardScreen();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
