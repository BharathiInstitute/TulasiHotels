/// Ingredient / stock management service
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/models/ingredient_model.dart';

class IngredientService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _basePath {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return 'users/$uid';
  }

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
    await _ingredientsRef
        .doc(ingredient.id)
        .set(ingredient.toFirestore());
  }

  /// Update an ingredient
  static Future<void> updateIngredient(IngredientModel ingredient) async {
    await _ingredientsRef
        .doc(ingredient.id)
        .update(ingredient.toFirestore());
  }

  /// Adjust stock level (add or subtract)
  static Future<void> adjustStock(
      String ingredientId, double adjustment) async {
    await _ingredientsRef.doc(ingredientId).update({
      'currentStock': FieldValue.increment(adjustment),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete an ingredient
  static Future<void> deleteIngredient(String ingredientId) async {
    await _ingredientsRef.doc(ingredientId).delete();
  }
}
