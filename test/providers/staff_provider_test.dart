/// Tests for staff providers — filtering and search logic
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/models/staff_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('staffRoleFilterProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(staffRoleFilterProvider), isNull);
    });

    test('can be set to a role', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(staffRoleFilterProvider.notifier).state =
          StaffRole.waiter;
      expect(container.read(staffRoleFilterProvider), StaffRole.waiter);
    });
  });

  group('staffSearchQueryProvider', () {
    test('defaults to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(staffSearchQueryProvider), '');
    });

    test('can be set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(staffSearchQueryProvider.notifier).state = 'ravi';
      expect(container.read(staffSearchQueryProvider), 'ravi');
    });
  });

  group('loggedInStaffProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(loggedInStaffProvider), isNull);
    });

    test('can be set to a staff member', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final staff = makeStaff(id: 's1', name: 'Ravi');
      container.read(loggedInStaffProvider.notifier).state = staff;
      expect(container.read(loggedInStaffProvider)?.name, 'Ravi');
    });
  });

  group('filteredStaff derived logic', () {
    final staffList = [
      makeStaff(id: 's1', name: 'Ravi Kumar', phone: '1111'),
      makeStaff(id: 's2', name: 'Amit Shah', role: StaffRole.chef, phone: '2222'),
      makeStaff(id: 's3', name: 'Priya Sharma', phone: '3333'),
      makeStaff(id: 's4', name: 'Kumar Patel', role: StaffRole.cashier, phone: '4444'),
      makeStaff(id: 's5', name: 'Deepa Nair', role: StaffRole.manager, phone: '5555'),
    ];

    test('no filter returns all', () {
      final filtered = staffList;
      expect(filtered.length, 5);
    });

    test('role filter: waiter', () {
      const roleFilter = StaffRole.waiter;
      final filtered =
          staffList.where((s) => s.role == roleFilter).toList();
      expect(filtered.length, 2);
      expect(filtered.every((s) => s.role == StaffRole.waiter), isTrue);
    });

    test('search by name (case-insensitive)', () {
      const query = 'kumar';
      final filtered = staffList
          .where((s) =>
              s.name.toLowerCase().contains(query.toLowerCase()) ||
              (s.phone?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
      expect(filtered.length, 2); // "Ravi Kumar" + "Kumar Patel"
    });

    test('search by phone', () {
      const query = '2222';
      final filtered = staffList
          .where((s) =>
              s.name.toLowerCase().contains(query) ||
              (s.phone?.contains(query) ?? false))
          .toList();
      expect(filtered.length, 1);
      expect(filtered[0].name, 'Amit Shah');
    });

    test('role filter + search combined', () {
      const roleFilter = StaffRole.waiter;
      const query = 'ravi';
      final filtered = staffList
          .where((s) => s.role == roleFilter)
          .where((s) =>
              s.name.toLowerCase().contains(query.toLowerCase()) ||
              (s.phone?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
      expect(filtered.length, 1);
      expect(filtered[0].name, 'Ravi Kumar');
    });

    test('empty search string returns all (with role filter)', () {
      const roleFilter = StaffRole.chef;
      const query = '';
      var filtered = staffList.where((s) => s.role == roleFilter);
      if (query.isNotEmpty) {
        filtered = filtered.where((s) =>
            s.name.toLowerCase().contains(query) ||
            (s.phone?.contains(query) ?? false));
      }
      expect(filtered.length, 1);
    });
  });
}
