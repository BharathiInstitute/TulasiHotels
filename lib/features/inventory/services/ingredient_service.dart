/// Ingredient / stock management service
library;

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/features/permissions/services/module_mutation_guard.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/models/ingredient_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class IngredientService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _basePath => ActiveStoreManager.basePath;

  static CollectionReference<Map<String, dynamic>> get _ingredientsRef =>
      _firestore.collection('$_basePath/ingredients');

  /// Stream all ingredients
  static Stream<List<IngredientModel>> ingredientsStream() {
    return _ingredientsRef
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => IngredientModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream low-stock ingredients
  static Stream<List<IngredientModel>> lowStockStream() {
    return _ingredientsRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => IngredientModel.fromFirestore(doc))
              .where((i) => i.isLowStock)
              .toList(),
        );
  }

  /// Get a single ingredient
  static Future<IngredientModel?> getIngredient(String ingredientId) async {
    final doc = await _ingredientsRef.doc(ingredientId).get();
    if (!doc.exists) return null;
    return IngredientModel.fromFirestore(doc);
  }

  /// Create an ingredient
  static Future<void> createIngredient(IngredientModel ingredient) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.ingredients,
      PermissionAction.create,
    );
    await _ingredientsRef
        .doc(ingredient.id)
        .set(ingredient.toFirestore());
  }

  /// Update an ingredient
  static Future<void> updateIngredient(IngredientModel ingredient) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.ingredients,
      PermissionAction.update,
    );
    await _ingredientsRef
        .doc(ingredient.id)
        .update(ingredient.toFirestore());
  }

  /// Adjust stock level (add or subtract)
  static Future<void> adjustStock(
      String ingredientId, double adjustment) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.ingredients,
      PermissionAction.update,
    );
    await _ingredientsRef.doc(ingredientId).update({
      'currentStock': FieldValue.increment(adjustment),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete an ingredient
  static Future<void> deleteIngredient(String ingredientId) async {
    await ModuleMutationGuard.requireAction(
      AppRoutes.ingredients,
      PermissionAction.delete,
    );
    await _ingredientsRef.doc(ingredientId).delete();
  }
}
