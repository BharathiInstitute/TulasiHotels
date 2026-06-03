import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/shell/web_shell.dart';

void main() {
  group('WebShell', () {
    test('is a ConsumerWidget', () {
      final widget = WebShell(
        child: const SizedBox(),
        selectedIndex: 0,
        visibleIndices: const [0, 1, 2],
        onItemTapped: (_) {},
      );
      expect(widget, isNotNull);
    });

    test('accepts required parameters', () {
      final widget = WebShell(
        child: const Placeholder(),
        selectedIndex: 2,
        visibleIndices: const [0, 1, 2, 3],
        onItemTapped: (_) {},
      );
      expect(widget, isNotNull);
    });

    test('accepts key parameter', () {
      final widget = WebShell(
        key: const Key('web-shell'),
        child: const SizedBox(),
        selectedIndex: 0,
        visibleIndices: const [0],
        onItemTapped: (_) {},
      );
      expect(widget.key, const Key('web-shell'));
    });
  });
}
