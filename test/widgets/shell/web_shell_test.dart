import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/shell/web_shell.dart';

void main() {
  group('WebShell', () {
    test('is a ConsumerWidget', () {
      final widget = WebShell(
        selectedIndex: 0,
        visibleIndices: const [0, 1, 2],
        onItemTapped: (_) {},
        child: const SizedBox(),
      );
      expect(widget, isNotNull);
    });

    test('accepts required parameters', () {
      final widget = WebShell(
        selectedIndex: 2,
        visibleIndices: const [0, 1, 2, 3],
        onItemTapped: (_) {},
        child: const Placeholder(),
      );
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      final widget = WebShell(
        key: const Key('web-shell'),
        selectedIndex: 0,
        visibleIndices: const [0],
        onItemTapped: (_) {},
        child: const SizedBox(),
      );
      expect(widget.key, const Key('web-shell'));
    });
  });
}
