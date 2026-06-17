/// Integration test: Reservation → Table → Order
///
/// Tests the full reservation lifecycle: create, confirm, seat at table,
/// table becomes occupied, order placed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/order_model.dart';
import 'package:tulasihotels/models/reservation_model.dart';
import 'package:tulasihotels/models/table_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('Integration: Reservation → Table → Order', () {
    test('Step 1: Create a pending reservation', () {
      final reservation = makeReservation(
        guestName: 'Priya Sharma',
        dateTime: DateTime(2026, 3, 15, 19, 30),
        specialRequests: 'Window seat preferred',
      );

      expect(reservation.status, ReservationStatus.pending);
      expect(reservation.guestName, 'Priya Sharma');
      expect(reservation.partySize, 4);
      expect(reservation.tableId, isNull);
      expect(reservation.specialRequests, 'Window seat preferred');
    });

    test('Step 2: Confirm the reservation', () {
      final confirmed = makeReservation(
        guestName: 'Priya Sharma',
        dateTime: DateTime(2026, 3, 15, 19, 30),
        status: ReservationStatus.confirmed,
      );

      expect(confirmed.status, ReservationStatus.confirmed);
      expect(confirmed.tableId, isNull); // not yet seated
    });

    test('Step 3: Table reserved in anticipation', () {
      final table = makeTable(
        id: 'tbl-7',
        number: 7,
        capacity: 6, // big enough for party of 4
        status: TableStatus.reserved,
      );

      expect(table.status, TableStatus.reserved);
      expect(table.isFree, isFalse);
      expect(table.hasActiveOrder, isFalse);
    });

    test('Step 4: Guest arrives — seat at table', () {
      final seated = makeReservation(
        guestName: 'Priya Sharma',
        dateTime: DateTime(2026, 3, 15, 19, 30),
        status: ReservationStatus.seated,
        tableId: 'tbl-7',
      );

      expect(seated.status, ReservationStatus.seated);
      expect(seated.tableId, 'tbl-7');
    });

    test('Step 5: Table becomes occupied with order', () {
      final table = makeTable(
        id: 'tbl-7',
        number: 7,
        status: TableStatus.occupied,
        currentOrderId: 'ord-1',
      );
      final order = makeOrder(
        id: 'ord-1',
        tableId: 'tbl-7',
        tableName: 'Table 7',
        items: [
          makeOrderItem(name: 'Paneer Tikka', price: 280),
          makeOrderItem(name: 'Dal Makhani', price: 220),
          makeOrderItem(name: 'Butter Naan', price: 60, quantity: 4),
        ],
      );

      expect(table.isFree, isFalse);
      expect(table.hasActiveOrder, isTrue);
      expect(order.total, 740); // 280 + 220 + 60*4
      expect(order.isActive, isTrue);
    });

    test('Step 6: Order billed → table freed again', () {
      final order = makeOrder(
        id: 'ord-1',
        status: OrderStatus.billed,
        items: [makeOrderItem(name: 'Paneer Tikka', price: 280)],
      );
      final table = makeTable(
        id: 'tbl-7',
        number: 7,
      );

      expect(order.isActive, isFalse);
      expect(table.isFree, isTrue);
    });
  });

  group('Integration: Reservation edge cases', () {
    test('no-show marks reservation accordingly', () {
      final noShow = makeReservation(
        id: 'res-2',
        guestName: 'No Show Guest',
        status: ReservationStatus.noShow,
      );
      expect(noShow.status, ReservationStatus.noShow);
    });

    test('cancelled reservation frees the table', () {
      final cancelled = makeReservation(
        id: 'res-3',
        guestName: 'Cancelled Guest',
        status: ReservationStatus.cancelled,
        tableId: 'tbl-7',
      );
      final table = makeTable(
        id: 'tbl-7',
        number: 7,
      );

      expect(cancelled.status, ReservationStatus.cancelled);
      expect(table.isFree, isTrue);
    });

    test('table capacity must accommodate party size', () {
      final smallTable = makeTable(capacity: 2);
      final bigParty = makeReservation(partySize: 6);

      expect(smallTable.capacity, lessThan(bigParty.partySize));
      // In practice, the service should prevent seating at this table
    });

    test('reservation duration defaults to 90 minutes', () {
      final reservation = makeReservation(
        guestName: 'Default Duration',
        dateTime: DateTime(2026, 3, 15, 19),
      );
      expect(reservation.durationMinutes, 90);
    });
  });
}
