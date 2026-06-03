/// Tests for inventory providers — provider types and data flow
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/inventory/providers/inventory_provider.dart';
import 'package:tulasihotels/models/ingredient_model.dart';
import 'package:tulasihotels/models/vendor_model.dart';
import 'package:tulasihotels/models/wastage_model.dart';

import '../helpers/test_factories_extended.dart';

void main() {
  group('Inventory providers', () {
    test('ingredientsProvider starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          ingredientsProvider.overrideWith(
            (_) => Stream.value([makeIngredient(name: 'Rice')]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final value = container.read(ingredientsProvider);
      expect(value.isLoading, isTrue);
    });

    test('lowStockIngredientsProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          lowStockIngredientsProvider.overrideWith(
            (_) => Stream.value(<IngredientModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(lowStockIngredientsProvider),
        isA<AsyncValue<List<IngredientModel>>>(),
      );
    });

    test('vendorsProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          vendorsProvider.overrideWith((_) => Stream.value(<VendorModel>[])),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(vendorsProvider),
        isA<AsyncValue<List<VendorModel>>>(),
      );
    });

    test('activeVendorsProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          activeVendorsProvider.overrideWith(
            (_) => Stream.value(<VendorModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(activeVendorsProvider),
        isA<AsyncValue<List<VendorModel>>>(),
      );
    });

    test('wastageProvider is a StreamProvider', () {
      final container = ProviderContainer(
        overrides: [
          wastageProvider.overrideWith((_) => Stream.value(<WastageModel>[])),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(wastageProvider),
        isA<AsyncValue<List<WastageModel>>>(),
      );
    });
  });

  group('Inventory provider data flow', () {
    test('ingredientsProvider can be overridden', () {
      final container = ProviderContainer(
        overrides: [
          ingredientsProvider.overrideWith(
            (_) => Stream.value(<IngredientModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(ingredientsProvider),
        isA<AsyncValue<List<IngredientModel>>>(),
      );
    });
  });
}
