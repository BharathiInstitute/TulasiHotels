/// Tests for reservation providers — date filter state management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/reservations/providers/reservation_provider.dart';
import 'package:tulasihotels/models/reservation_model.dart';

void main() {
  group('reservationDateFilterProvider', () {
    test('defaults to today', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final date = container.read(reservationDateFilterProvider);
      final now = DateTime.now();
      expect(date.year, now.year);
      expect(date.month, now.month);
      expect(date.day, now.day);
    });

    test('can be set to a future date', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final future = DateTime(2025, 6, 15);
      container.read(reservationDateFilterProvider.notifier).state = future;
      expect(container.read(reservationDateFilterProvider), future);
    });

    test('can be set to a past date', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final past = DateTime(2024);
      container.read(reservationDateFilterProvider.notifier).state = past;
      expect(container.read(reservationDateFilterProvider), past);
    });
  });

  group('todayReservationsProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          todayReservationsProvider.overrideWith(
            (_) => Stream.value(<ReservationModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(todayReservationsProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          todayReservationsProvider.overrideWith(
            (_) => Stream.value(<ReservationModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(todayReservationsProvider),
        isA<AsyncValue<List<ReservationModel>>>(),
      );
    });
  });

  group('upcomingReservationsProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          upcomingReservationsProvider.overrideWith(
            (_) => Stream.value(<ReservationModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(upcomingReservationsProvider).isLoading, isTrue);
    });
  });
}
