/// Widget-level tests for A11y semantic wrappers.
///
/// Verifies that A11y.label, A11y.button, A11y.header, and A11y.liveRegion
/// apply the correct Semantics properties for screen readers.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/core/utils/a11y.dart';

void main() {
  group('A11y.label', () {
    testWidgets('wraps child with Semantics and ExcludeSemantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.label(label: 'Add to cart', child: const Icon(Icons.add)),
        ),
      );

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Add to cart'),
      );
      expect(semantics.label, 'Add to cart');
      expect(semantics.flagsCollection.isButton, isFalse);
      expect(semantics.flagsCollection.isHeader, isFalse);
    });

    testWidgets('button flag is respected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.label(
            label: 'Buy now',
            button: true,
            child: const Text('Buy'),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.bySemanticsLabel('Buy now'));
      expect(semantics.flagsCollection.isButton, isTrue);
    });

    testWidgets('header flag is respected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.label(
            label: 'Products Section',
            header: true,
            child: const Text('Products'),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Products Section'),
      );
      expect(semantics.flagsCollection.isHeader, isTrue);
    });

    testWidgets('image flag is respected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.label(
            label: 'Hotel logo',
            image: true,
            child: const Icon(Icons.hotel),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Hotel logo'),
      );
      expect(semantics.flagsCollection.isImage, isTrue);
    });

    testWidgets('hint is passed through', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.label(
            label: 'Checkout',
            hint: 'Double tap to proceed',
            child: const Text('Go'),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.bySemanticsLabel('Checkout'));
      expect(semantics.hint, 'Double tap to proceed');
    });

    testWidgets('value is passed through', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.label(
            label: 'Quantity',
            value: '3',
            child: const Text('3'),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.bySemanticsLabel('Quantity'));
      expect(semantics.value, '3');
    });
  });

  group('A11y.button', () {
    testWidgets('marks widget as button with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.button(
            label: 'Submit order',
            child: const ElevatedButton(onPressed: null, child: Text('Submit')),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Submit order'),
      );
      expect(semantics.label, 'Submit order');
      expect(semantics.flagsCollection.isButton, isTrue);
    });

    testWidgets('hint is passed through', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.button(
            label: 'Delete item',
            hint: 'Double tap to delete',
            child: const Icon(Icons.delete),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Delete item'),
      );
      expect(semantics.hint, 'Double tap to delete');
    });

    testWidgets('enabled defaults to true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.button(label: 'Enabled btn', child: const Text('Click')),
        ),
      );

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Enabled btn'),
      );
      expect(semantics.flagsCollection.isEnabled != Tristate.none, isTrue);
      expect(semantics.flagsCollection.isEnabled == Tristate.isTrue, isTrue);
    });
  });

  group('A11y.header', () {
    testWidgets('marks widget as header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.header(label: 'Dashboard', child: const Text('Dashboard')),
        ),
      );

      final semantics = tester.getSemantics(find.bySemanticsLabel('Dashboard'));
      expect(semantics.flagsCollection.isHeader, isTrue);
      expect(semantics.label, 'Dashboard');
    });

    testWidgets('uses ExcludeSemantics for child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.header(
            label: 'Settings Title',
            child: const Text('Settings'),
          ),
        ),
      );

      // Only one semantics node with the label — child text is excluded
      expect(find.bySemanticsLabel('Settings Title'), findsOneWidget);
    });
  });

  group('A11y.liveRegion', () {
    testWidgets('creates a live region semantics node', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.liveRegion(
            message: 'Item added to cart',
            child: const SizedBox.shrink(),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Item added to cart'),
      );
      expect(semantics.flagsCollection.isLiveRegion, isTrue);
    });

    testWidgets('does not exclude child semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.liveRegion(
            message: 'Order placed',
            child: const Text('Success'),
          ),
        ),
      );

      // The child text should still be accessible (no ExcludeSemantics)
      expect(find.text('Success'), findsOneWidget);
    });

    testWidgets('wraps in Semantics without ExcludeSemantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11y.liveRegion(
            message: 'Alert',
            child: const Text('Alert text'),
          ),
        ),
      );

      // Verify Semantics widget is present with liveRegion true
      final semanticsWidget = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      expect(semanticsWidget.properties.label, 'Alert');
    });
  });
}
