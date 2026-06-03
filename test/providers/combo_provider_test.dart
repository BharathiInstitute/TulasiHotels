/// Tests for combo providers — stream provider types
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/menu/providers/combo_provider.dart';
import 'package:tulasihotels/models/combo_model.dart';

void main() {
  group('combosStreamProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          combosStreamProvider.overrideWith(
            (_) => Stream.value(<ComboModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(combosStreamProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          combosStreamProvider.overrideWith(
            (_) => Stream.value(<ComboModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(combosStreamProvider),
        isA<AsyncValue<List<ComboModel>>>(),
      );
    });
  });

  group('availableCombosProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          availableCombosProvider.overrideWith(
            (_) => Stream.value(<ComboModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(availableCombosProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          availableCombosProvider.overrideWith(
            (_) => Stream.value(<ComboModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(availableCombosProvider),
        isA<AsyncValue<List<ComboModel>>>(),
      );
    });
  });
}
