/// Tests for mobile layout: common screen sizes, breakpoints, grid columns
///
/// Verifies that at mobile widths (<600), responsive helpers return
/// correct values for padding, grid columns, button heights.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/core/theme/adaptive_layout.dart';
import 'package:tulasihotels/core/theme/responsive_helper.dart';

void main() {
  group('Mobile Layout: Breakpoint detection', () {
    test('375×667 (iPhone SE) → mobile', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(375), DeviceType.mobile);
    });

    test('390×844 (iPhone 14) → mobile', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(390), DeviceType.mobile);
    });

    test('360×640 (Android standard) → mobile', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(360), DeviceType.mobile);
    });

    test('320×568 (small phone) → mobile', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(320), DeviceType.mobile);
    });

    test('599 is still mobile', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(599), DeviceType.mobile);
    });

    test('600 is tablet (not mobile)', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(600), DeviceType.tablet);
    });
  });

  group('Mobile Layout: AdaptiveLayout renders mobile builder', () {
    testWidgets('at 375px shows mobile content', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
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

      expect(find.text('MOBILE'), findsOneWidget);
      expect(find.text('TABLET'), findsNothing);
      expect(find.text('DESKTOP'), findsNothing);
    });

    testWidgets('at 360px shows mobile content', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      expect(find.text('MOBILE'), findsOneWidget);
    });
  });

  group('Mobile Layout: ResponsiveLayout renders mobile widget', () {
    testWidgets('at 390px shows mobile widget', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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

      expect(find.text('MOBILE'), findsOneWidget);
    });
  });

  group('Mobile Layout: Grid columns', () {
    testWidgets('small phone (320px) gets 2 columns', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
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

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('medium phone (390px) gets 3 columns', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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

    testWidgets('large phone (428px) gets 4 columns', (tester) async {
      tester.view.physicalSize = const Size(428, 926);
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

      expect(find.text('4'), findsOneWidget);
    });
  });

  group('Mobile Layout: Button height', () {
    testWidgets('small phone gets 40px buttons', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
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

      expect(find.text('40.0'), findsOneWidget);
    });

    testWidgets('standard phone gets 44px buttons', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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

      expect(find.text('44.0'), findsOneWidget);
    });
  });
}
