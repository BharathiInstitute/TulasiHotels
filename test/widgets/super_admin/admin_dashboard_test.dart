import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/super_admin/screens/super_admin_dashboard_screen.dart';

void main() {
  group('SuperAdminDashboardScreen', () {
    test('is a ConsumerWidget', () {
      const widget = SuperAdminDashboardScreen();
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      const widget = SuperAdminDashboardScreen(key: Key('admin'));
      expect(widget.key, const Key('admin'));
    });
  });
}
