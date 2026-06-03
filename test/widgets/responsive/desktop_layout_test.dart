/// Tests for desktop layout: 1024–1919px and 1920+ breakpoints
///
/// Verifies desktop/desktopLarge breakpoint behavior, grid columns,
/// sidebar collapse threshold, responsive scaling.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/core/theme/adaptive_layout.dart';
import 'package:tulasihotels/core/theme/responsive_helper.dart';
import 'package:tulasihotels/core/theme/responsive_scale.dart';

void main() {
  group('Desktop Layout: Breakpoint detection', () {
    test('1024px → desktop', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1024), DeviceType.desktop);
    });

    test('1280px → desktop', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1280), DeviceType.desktop);
    });

    test('1440px → desktop', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1440), DeviceType.desktop);
    });

    test('1919px → still desktop', () {
      expect(ResponsiveHelper.getDeviceTypeFromWidth(1919), DeviceType.desktop);
    });

    test('1920px → desktopLarge', () {
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(1920),
        DeviceType.desktopLarge,
      );
    });

    test('2560px (4K) → desktopLarge', () {
      expect(
        ResponsiveHelper.getDeviceTypeFromWidth(2560),
        DeviceType.desktopLarge,
      );
    });
  });

  group('Desktop Layout: AdaptiveLayout renders desktop builder', () {
    testWidgets('at 1280px shows desktop content', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
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

      expect(find.text('DESKTOP'), findsOneWidget);
    });

    testWidgets('at 1920px shows desktopLarge when provided', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLayout(
            mobile: (_) => const Text('MOBILE'),
            desktop: (_) => const Text('DESKTOP'),
            desktopLarge: (_) => const Text('XL'),
          ),
        ),
      );

      expect(find.text('XL'), findsOneWidget);
    });

    testWidgets('desktopLarge falls back to desktop', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLayout(
            mobile: (_) => const Text('MOBILE'),
            desktop: (_) => const Text('DESKTOP'),
          ),
        ),
      );

      expect(find.text('DESKTOP'), findsOneWidget);
    });
  });

  group('Desktop Layout: Grid columns', () {
    testWidgets('desktop (1280px) gets 4 columns', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
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

    testWidgets('large desktop (1440px) gets 5 columns', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
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

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('desktopLarge (1920px) gets 6 columns', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
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

      expect(find.text('6'), findsOneWidget);
    });
  });

  group('Desktop Layout: Responsive scaling', () {
    test('design width is 1920', () {
      expect(ResponsiveScale.designWidth, 1920.0);
    });

    test('min scale is 0.3', () {
      expect(ResponsiveScale.minScale, 0.3);
    });

    test('max scale is 1.5', () {
      expect(ResponsiveScale.maxScale, 1.5);
    });

    test('min font size is 11', () {
      expect(ResponsiveScale.minFontSize, 11.0);
    });

    test('min touch target is 48', () {
      expect(ResponsiveScale.minTouchTarget, 48.0);
    });

    test('ensureTouchTarget enforces 48px minimum', () {
      expect(ResponsiveScale.ensureTouchTarget(30), 48.0);
      expect(ResponsiveScale.ensureTouchTarget(48), 48.0);
      expect(ResponsiveScale.ensureTouchTarget(60), 60.0);
    });
  });

  group('Desktop Layout: AdaptiveLayoutStatic variant', () {
    testWidgets('at 1280px shows desktop widget', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveLayoutStatic(
            mobile: Text('MOBILE'),
            desktop: Text('DESKTOP'),
          ),
        ),
      );

      expect(find.text('DESKTOP'), findsOneWidget);
    });
  });

  group('Desktop Layout: Horizontal padding', () {
    testWidgets('desktop gets 32px horizontal padding', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = ResponsiveHelper.horizontalPadding(context);
              return Text('$padding');
            },
          ),
        ),
      );

      expect(find.text('32.0'), findsOneWidget);
    });

    testWidgets('desktopLarge gets 40px horizontal padding', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = ResponsiveHelper.horizontalPadding(context);
              return Text('$padding');
            },
          ),
        ),
      );

      expect(find.text('40.0'), findsOneWidget);
    });
  });
}
