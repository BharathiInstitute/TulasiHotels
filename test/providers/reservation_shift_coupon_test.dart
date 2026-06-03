/// Tests for reservation, shift, coupon state providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/reservations/providers/reservation_provider.dart';
import 'package:tulasihotels/features/staff/providers/shift_provider.dart';

void main() {
  group('reservationDateFilterProvider', () {
    test('defaults to current date (today)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(reservationDateFilterProvider);
      final now = DateTime.now();
      expect(value.year, now.year);
      expect(value.month, now.month);
      expect(value.day, now.day);
    });

    test('can be set to a specific date', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final target = DateTime(2024, 12, 25);
      container.read(reservationDateFilterProvider.notifier).state = target;
      expect(container.read(reservationDateFilterProvider), target);
    });
  });

  group('shiftWeekStartProvider', () {
    test('defaults to Monday of current week', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(shiftWeekStartProvider);
      expect(value.weekday, DateTime.monday);
    });

    test('can be set to a different week', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final target = DateTime(2024, 1, 8); // Monday
      container.read(shiftWeekStartProvider.notifier).state = target;
      expect(container.read(shiftWeekStartProvider), target);
    });
  });
}
