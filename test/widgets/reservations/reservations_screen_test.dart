import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/reservations/providers/reservation_provider.dart';
import 'package:tulasihotels/features/reservations/screens/reservations_screen.dart';


import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('ReservationsScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(
        tester,
        const ReservationsScreen(),
        overrides: [
          todayReservationsProvider.overrideWith((_) => Stream.value([])),
        ],
      );
      expect(find.text('Reservations'), findsOneWidget);
    });

    testWidgets('shows FAB for new reservation', (tester) async {
      await pumpWidget(
        tester,
        const ReservationsScreen(),
        overrides: [
          todayReservationsProvider.overrideWith((_) => Stream.value([])),
        ],
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Reservation'), findsOneWidget);
    });

    testWidgets('shows guest name in list', (tester) async {
      final items = [
        makeReservation(guestName: 'Rahul Sharma'),
        makeReservation(id: 'r2', guestName: 'Priya Patel'),
      ];
      await pumpWidget(
        tester,
        const ReservationsScreen(),
        overrides: [
          todayReservationsProvider.overrideWith((_) => Stream.value(items)),
        ],
      );
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Priya Patel'), findsOneWidget);
    });

    testWidgets('shows party size in subtitle', (tester) async {
      final items = [makeReservation(partySize: 6)];
      await pumpWidget(
        tester,
        const ReservationsScreen(),
        overrides: [
          todayReservationsProvider.overrideWith((_) => Stream.value(items)),
        ],
      );
      expect(find.textContaining('6'), findsWidgets);
    });

    testWidgets('shows status-coloured avatar', (tester) async {
      final items = [
        makeReservation(
          guestName: 'Pending Guest',
        ),
      ];
      await pumpWidget(
        tester,
        const ReservationsScreen(),
        overrides: [
          todayReservationsProvider.overrideWith((_) => Stream.value(items)),
        ],
      );
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('shows popup menu for actions', (tester) async {
      final items = [makeReservation(guestName: 'Action Guest')];
      await pumpWidget(
        tester,
        const ReservationsScreen(),
        overrides: [
          todayReservationsProvider.overrideWith((_) => Stream.value(items)),
        ],
      );
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayReservationsProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: ReservationsScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
