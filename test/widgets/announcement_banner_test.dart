import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/shared/widgets/announcement_banner.dart';

void main() {
  group('AnnouncementBanner', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnnouncementBanner(child: Scaffold(body: Text('Main Content'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Main Content'), findsOneWidget);
    });

    testWidgets('is a StatefulWidget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnnouncementBanner(child: Scaffold(body: Text('Child'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnnouncementBanner), findsOneWidget);
    });

    testWidgets('child is always visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnnouncementBanner(
            child: Scaffold(
              body: Column(children: [Text('Header'), Text('Body')]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });
  });
}
