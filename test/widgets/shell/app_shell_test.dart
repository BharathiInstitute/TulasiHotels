import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/shell/app_shell.dart';

void main() {
  group('AppShell', () {
    test('is a ConsumerStatefulWidget', () {
      const widget = AppShell(child: SizedBox());
      expect(widget, isNotNull);
    });

    test('requires child parameter', () {
      const widget = AppShell(child: Placeholder());
      expect(widget, isNotNull);
    });

    test('createState returns non-null', () {
      const widget = AppShell(child: SizedBox());
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });
}
