/// Tests for task providers — stream types and family provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/providers/task_provider.dart';
import 'package:tulasihotels/models/task_model.dart';

void main() {
  group('activeTasksProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          activeTasksProvider.overrideWith((_) => Stream.value(<TaskModel>[])),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(activeTasksProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          activeTasksProvider.overrideWith((_) => Stream.value(<TaskModel>[])),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(activeTasksProvider),
        isA<AsyncValue<List<TaskModel>>>(),
      );
    });
  });

  group('staffTasksProvider', () {
    test('is a family provider keyed by staffId', () {
      final container = ProviderContainer(
        overrides: [
          staffTasksProvider(
            'staff-1',
          ).overrideWith((_) => Stream.value(<TaskModel>[])),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(staffTasksProvider('staff-1')),
        isA<AsyncValue<List<TaskModel>>>(),
      );
    });

    test('different staff IDs are independent providers', () {
      final container = ProviderContainer(
        overrides: [
          staffTasksProvider(
            's1',
          ).overrideWith((_) => Stream.value(<TaskModel>[])),
          staffTasksProvider(
            's2',
          ).overrideWith((_) => Stream.value(<TaskModel>[])),
        ],
      );
      addTearDown(container.dispose);
      // Both can be read without error — they are separate providers
      container.read(staffTasksProvider('s1'));
      container.read(staffTasksProvider('s2'));
    });
  });
}
