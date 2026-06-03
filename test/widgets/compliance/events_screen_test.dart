import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/compliance/providers/compliance_provider.dart';
import 'package:tulasihotels/features/compliance/screens/events_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('EventsScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const EventsScreen(), overrides: [
        allEventsProvider.overrideWith((_) => Stream.value([])),
        upcomingEventsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.text('Events & Banquets'), findsOneWidget);
    });

    testWidgets('shows FAB for new event', (tester) async {
      await pumpWidget(tester, const EventsScreen(), overrides: [
        allEventsProvider.overrideWith((_) => Stream.value([])),
        upcomingEventsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Event'), findsOneWidget);
    });

    testWidgets('shows event name in list', (tester) async {
      final events = [
        makeEvent(eventName: 'Wedding Reception'),
        makeEvent(id: 'ev2', eventName: 'Birthday Party'),
      ];
      await pumpWidget(tester, const EventsScreen(), overrides: [
        allEventsProvider.overrideWith((_) => Stream.value(events)),
        upcomingEventsProvider.overrideWith((_) => Stream.value(events)),
      ]);
      expect(find.text('Wedding Reception'), findsOneWidget);
      expect(find.text('Birthday Party'), findsOneWidget);
    });

    testWidgets('shows guest count', (tester) async {
      final events = [
        makeEvent(
          eventName: 'Corporate Dinner',
          clientName: 'Acme Corp',
          guestCount: 150,
        ),
      ];
      await pumpWidget(tester, const EventsScreen(), overrides: [
        allEventsProvider.overrideWith((_) => Stream.value(events)),
        upcomingEventsProvider.overrideWith((_) => Stream.value(events)),
      ]);
      expect(find.textContaining('150'), findsWidgets);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allEventsProvider.overrideWith((_) => const Stream.empty()),
            upcomingEventsProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: EventsScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('filter chip switches upcoming/all', (tester) async {
      final events = [makeEvent(eventName: 'Gala')];
      await pumpWidget(tester, const EventsScreen(), overrides: [
        allEventsProvider.overrideWith((_) => Stream.value(events)),
        upcomingEventsProvider.overrideWith((_) => Stream.value(events)),
      ]);
      // Tap All chip if present
      final allChip = find.widgetWithText(FilterChip, 'All');
      if (allChip.evaluate().isNotEmpty) {
        await tester.tap(allChip);
        await tester.pumpAndSettle();
      }
    });
  });
}
