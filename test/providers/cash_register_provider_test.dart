/// Tests for cash register providers — stream types and data flow
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/providers/cash_register_provider.dart';
import 'package:tulasihotels/models/cash_register_model.dart';

void main() {
  group('todayRegisterProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          todayRegisterProvider.overrideWith((_) => Stream.value(null)),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(todayRegisterProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of nullable CashRegisterModel', () {
      final container = ProviderContainer(
        overrides: [
          todayRegisterProvider.overrideWith((_) => Stream.value(null)),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(todayRegisterProvider),
        isA<AsyncValue<CashRegisterModel?>>(),
      );
    });
  });

  group('registerHistoryProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          registerHistoryProvider.overrideWith(
            (_) => Stream.value(<CashRegisterModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(registerHistoryProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          registerHistoryProvider.overrideWith(
            (_) => Stream.value(<CashRegisterModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(registerHistoryProvider),
        isA<AsyncValue<List<CashRegisterModel>>>(),
      );
    });
  });
}
