/// Tests for shift providers — week start calculation and state management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/providers/shift_provider.dart';
import 'package:tulasihotels/models/shift_model.dart';

void main() {
  group('shiftWeekStartProvider', () {
    test('defaults to Monday of current week', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final weekStart = container.read(shiftWeekStartProvider);
      // Should be Monday (weekday == 1)
      expect(weekStart.weekday, DateTime.monday);
    });

    test('is on or before today', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final weekStart = container.read(shiftWeekStartProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(
        weekStart.isBefore(today) || weekStart.isAtSameMomentAs(today),
        isTrue,
      );
    });

    test('is within 6 days before today', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final weekStart = container.read(shiftWeekStartProvider);
      final now = DateTime.now();
      expect(now.difference(weekStart).inDays, lessThanOrEqualTo(6));
    });

    test('can be updated to a different Monday', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final lastMonday = DateTime(2024, 7); // A known Monday
      container.read(shiftWeekStartProvider.notifier).state = lastMonday;
      expect(container.read(shiftWeekStartProvider), lastMonday);
    });
  });

  group('todayShiftsProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          todayShiftsProvider.overrideWith((_) => Stream.value(<ShiftModel>[])),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(todayShiftsProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          todayShiftsProvider.overrideWith((_) => Stream.value(<ShiftModel>[])),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(todayShiftsProvider),
        isA<AsyncValue<List<ShiftModel>>>(),
      );
    });
  });

  group('staffShiftsProvider', () {
    test('is a family provider keyed by staffId', () {
      final container = ProviderContainer(
        overrides: [
          staffShiftsProvider(
            'staff-1',
          ).overrideWith((_) => Stream.value(<ShiftModel>[])),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(staffShiftsProvider('staff-1')),
        isA<AsyncValue<List<ShiftModel>>>(),
      );
    });

    test('different staff IDs are independent providers', () {
      final container = ProviderContainer(
        overrides: [
          staffShiftsProvider(
            's1',
          ).overrideWith((_) => Stream.value(<ShiftModel>[])),
          staffShiftsProvider(
            's2',
          ).overrideWith((_) => Stream.value(<ShiftModel>[])),
        ],
      );
      addTearDown(container.dispose);
      // Both can be read without error
      container.read(staffShiftsProvider('s1'));
      container.read(staffShiftsProvider('s2'));
    });
  });
}
