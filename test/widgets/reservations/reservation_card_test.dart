import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/reservations/widgets/reservation_card.dart';
import 'package:tulasihotels/models/reservation_model.dart';

import '../../helpers/test_factories_extended.dart';

void main() {
  Widget buildCard(
    ReservationModel reservation, {
    VoidCallback? onTap,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ReservationCard(
          reservation: reservation,
          onTap: onTap,
          onConfirm: onConfirm,
          onCancel: onCancel,
        ),
      ),
    );
  }

  group('ReservationCard', () {
    testWidgets('shows guest name', (tester) async {
      final res = makeReservation(guestName: 'Anand Sharma');
      await tester.pumpWidget(buildCard(res));
      expect(find.text('Anand Sharma'), findsOneWidget);
    });

    testWidgets('shows party size', (tester) async {
      final res = makeReservation(partySize: 8);
      await tester.pumpWidget(buildCard(res));
      expect(find.textContaining('8'), findsWidgets);
    });

    testWidgets('shows phone number', (tester) async {
      final res = makeReservation(phone: '9876543210');
      await tester.pumpWidget(buildCard(res));
      expect(find.textContaining('9876543210'), findsOneWidget);
    });

    testWidgets('shows special requests when provided', (tester) async {
      final res = makeReservation(specialRequests: 'Window seat preferred');
      await tester.pumpWidget(buildCard(res));
      expect(find.text('Window seat preferred'), findsOneWidget);
    });

    testWidgets('shows confirm/cancel buttons for pending status', (
      tester,
    ) async {
      final res = makeReservation(status: ReservationStatus.pending);
      var confirmed = false;
      var cancelled = false;
      await tester.pumpWidget(
        buildCard(
          res,
          onConfirm: () => confirmed = true,
          onCancel: () => cancelled = true,
        ),
      );
      final confirmBtn = find.textContaining('Confirm');
      final cancelBtn = find.textContaining('Cancel');
      expect(confirmBtn, findsOneWidget);
      expect(cancelBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      expect(confirmed, isTrue);

      await tester.tap(cancelBtn);
      expect(cancelled, isTrue);
    });

    testWidgets('hides action buttons for confirmed status', (tester) async {
      final res = makeReservation(status: ReservationStatus.confirmed);
      await tester.pumpWidget(buildCard(res));
      // No FilledButton/OutlinedButton action buttons — status chip shows "Confirmed" text
      expect(find.widgetWithText(FilledButton, 'Confirm'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsNothing);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      final res = makeReservation();
      await tester.pumpWidget(buildCard(res, onTap: () => tapped = true));
      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('shows status chip', (tester) async {
      final res = makeReservation(status: ReservationStatus.seated);
      await tester.pumpWidget(buildCard(res));
      expect(find.textContaining('Seated'), findsOneWidget);
    });
  });
}
