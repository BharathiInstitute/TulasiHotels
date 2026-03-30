/// Inventory providers — ingredients, vendors, wastage
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/inventory/services/ingredient_service.dart';
import 'package:tulasihotels/features/inventory/services/vendor_service.dart';
import 'package:tulasihotels/features/inventory/services/wastage_service.dart';
import 'package:tulasihotels/models/ingredient_model.dart';
import 'package:tulasihotels/models/vendor_model.dart';
import 'package:tulasihotels/models/wastage_model.dart';

/// Stream all ingredients
final ingredientsProvider = StreamProvider.autoDispose<List<IngredientModel>>((
  ref,
) {
  return IngredientService.ingredientsStream();
});

/// Stream low-stock ingredients
final lowStockIngredientsProvider =
    StreamProvider.autoDispose<List<IngredientModel>>((ref) {
      return IngredientService.lowStockStream();
    });

/// Stream all vendors
final vendorsProvider = StreamProvider.autoDispose<List<VendorModel>>((ref) {
  return VendorService.vendorsStream();
});

/// Stream active vendors
final activeVendorsProvider = StreamProvider.autoDispose<List<VendorModel>>((
  ref,
) {
  return VendorService.activeVendorsStream();
});

/// Stream recent wastage
final wastageProvider = StreamProvider.autoDispose<List<WastageModel>>((ref) {
  return WastageService.recentWastageStream();
});
