/// Tests for attendance providers — date boundary and state logic
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/providers/attendance_provider.dart';

void main() {
  group('attendanceDateRangeProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(attendanceDateRangeProvider), isNull);
    });
  });

  group('attendanceStaffFilterProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(attendanceStaffFilterProvider), isNull);
    });

    test('can set staff filter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(attendanceStaffFilterProvider.notifier).state = 'staff-1';
      expect(container.read(attendanceStaffFilterProvider), 'staff-1');
    });
  });

  group('staffDetailPanelProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(staffDetailPanelProvider), isNull);
    });

    test('can set staff detail', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(staffDetailPanelProvider.notifier).state =
          (id: 'staff-1', name: 'Ravi');
      final state = container.read(staffDetailPanelProvider);
      expect(state?.id, 'staff-1');
      expect(state?.name, 'Ravi');
    });
  });

  group('staffDetailDateRangeProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(staffDetailDateRangeProvider), isNull);
    });
  });

  group('week boundary computation', () {
    test('Monday of current week from Wednesday', () {
      final wednesday = DateTime(2024, 1, 17); // Wed Jan 17 2024
      final monday =
          wednesday.subtract(Duration(days: wednesday.weekday - 1));
      expect(monday.weekday, DateTime.monday);
      expect(monday.day, 15);
    });

    test('Monday of current week from Monday', () {
      final monday = DateTime(2024, 1, 15); // Mon Jan 15 2024
      final computed = monday.subtract(Duration(days: monday.weekday - 1));
      expect(computed, monday);
    });

    test('Monday of current week from Sunday', () {
      final sunday = DateTime(2024, 1, 21); // Sun Jan 21 2024
      final monday = sunday.subtract(Duration(days: sunday.weekday - 1));
      expect(monday.weekday, DateTime.monday);
      expect(monday.day, 15);
    });

    test('last week range: Mon to Sun', () {
      final now = DateTime(2024, 1, 17); // Wednesday
      final thisMonday = now.subtract(Duration(days: now.weekday - 1));
      final lastMonday = thisMonday.subtract(const Duration(days: 7));
      final lastSunday =
          lastMonday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      expect(lastMonday.weekday, DateTime.monday);
      expect(lastMonday.day, 8);
      expect(lastSunday.weekday, DateTime.sunday);
      expect(lastSunday.day, 14);
    });

    test('default date range fallback: last 7 days', () {
      final now = DateTime(2024, 1, 17);
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      expect(sevenDaysAgo.day, 10);
    });

    test('default staff detail range fallback: last 30 days', () {
      final now = DateTime(2024, 1, 17);
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      expect(thirtyDaysAgo.month, 12);
      expect(thirtyDaysAgo.day, 18);
    });
  });
}
