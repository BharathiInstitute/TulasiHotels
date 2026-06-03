/// Tests for tablet layout: 600–1023px breakpoint
///
/// Verifies that at tablet widths, adaptive layouts show tablet content,
/// grid columns adjust, and responsive values are correct.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/core/theme/adaptive_layout.dart';
import 'package:tulasihotels/core/theme/responsive_helper.dart';

void main() {
  group('Tablet Layout: Breakpoint detection', () {
    test('600px → tablet', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(600), DeviceType.tablet);
    });

    test('768px (iPad) → tablet', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(768), DeviceType.tablet);
    });

    test('1023px → still tablet', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1023), DeviceType.tablet);
    });

    test('1024px → desktop (not tablet)', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1024), DeviceType.desktop);
    });
  });

  group('Tablet Layout: AdaptiveLayout renders tablet builder', () {
    testWidgets('at 768px shows tablet content', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLayout(
            mobile: (_) => const Text('MOBILE'),
            tablet: (_) => const Text('TABLET'),
            desktop: (_) => const Text('DESKTOP'),
          ),
        ),
      );

      expect(find.text('TABLET'), findsOneWidget);
      expect(find.text('MOBILE'), findsNothing);
    });

    testWidgets('at 600px shows tablet content', (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLayout(
            mobile: (_) => const Text('MOBILE'),
            tablet: (_) => const Text('TABLET'),
          ),
        ),
      );

      expect(find.text('TABLET'), findsOneWidget);
    });

    testWidgets('falls back to mobile when tablet not provided', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(home: AdaptiveLayout(mobile: (_) => const Text('MOBILE'))),
      );

      expect(find.text('MOBILE'), findsOneWidget);
    });
  });

  group('Tablet Layout: Grid columns', () {
    testWidgets('tablet (768px) gets 3 columns', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final cols = ResponsiveHelper.gridColumns(context);
              return Text('$cols');
            },
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });
  });

  group('Tablet Layout: Button height', () {
    testWidgets('tablet gets 48px buttons', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final height = ResponsiveHelper.buttonHeight(context);
              return Text('$height');
            },
          ),
        ),
      );

      expect(find.text('48.0'), findsOneWidget);
    });
  });

  group('Tablet Layout: ResponsiveLayout at tablet width', () {
    testWidgets('at 800px shows tablet widget', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('MOBILE'),
            tablet: Text('TABLET'),
            desktop: Text('DESKTOP'),
          ),
        ),
      );

      expect(find.text('TABLET'), findsOneWidget);
    });
  });
}
