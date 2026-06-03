import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/shared/widgets/update_banner.dart';

/// Tests for UpdateBanner widget.
///
/// UpdateBanner depends on Platform.isWindows and WindowsUpdateService (static),
/// so we test basic structure and child rendering.
void main() {
  group('UpdateBanner', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateBanner(child: Scaffold(body: Text('App Content'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets('is a StatefulWidget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateBanner(child: Scaffold(body: Text('Test'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(UpdateBanner), findsOneWidget);
    });

    testWidgets('child always visible regardless of banner state', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateBanner(
            child: Scaffold(
              body: Column(children: [Text('Dashboard'), Text('Sales: 100')]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sales: 100'), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      const key = Key('update-banner');
      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateBanner(
            key: key,
            child: Scaffold(body: Text('Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
    });
  });
}
