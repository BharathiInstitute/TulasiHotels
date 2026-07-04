/// Service to manage which items are "active" when plan limits < actual counts.
///
/// When a user downgrades, they choose which products/tables to keep active.
/// Only active items can be used in billing. Locked items are visible but greyed out.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tulasihotels/core/services/active_store_manager.dart';

class ActiveItemsService {
  ActiveItemsService._();

  static final _firestore = FirebaseFirestore.instance;

  static String? get _storeId =>
      ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;

  /// Get the set of active product IDs.
  /// Returns null if no restriction (all products are active).
  static Future<Set<String>?> getActiveProductIds() async {
    final storeId = _storeId;
    if (storeId == null) return null;

    final doc = await _firestore.collection('users').doc(storeId).get();
    final data = doc.data();
    final ids = data?['limits']?['activeProductIds'] as List<dynamic>?;
    if (ids == null || ids.isEmpty) return null;
    return ids.cast<String>().toSet();
  }

  /// Get the set of active table IDs.
  /// Returns null if no restriction (all tables are active).
  static Future<Set<String>?> getActiveTableIds() async {
    final storeId = _storeId;
    if (storeId == null) return null;

    final doc = await _firestore.collection('users').doc(storeId).get();
    final data = doc.data();
    final ids = data?['limits']?['activeTableIds'] as List<dynamic>?;
    if (ids == null || ids.isEmpty) return null;
    return ids.cast<String>().toSet();
  }

  /// Check if a product is active (can be used in billing).
  /// If no restriction exists (activeProductIds is null), all products are active.
  static Future<bool> isProductActive(String productId) async {
    final activeIds = await getActiveProductIds();
    if (activeIds == null) return true; // No restriction
    return activeIds.contains(productId);
  }

  /// Check if a table is active.
  static Future<bool> isTableActive(String tableId) async {
    final activeIds = await getActiveTableIds();
    if (activeIds == null) return true;
    return activeIds.contains(tableId);
  }

  /// Save the user's selection of active products.
  /// Called when user picks which items to keep after a downgrade.
  static Future<void> setActiveProducts(List<String> productIds) async {
    final storeId = _storeId;
    if (storeId == null) return;

    await _firestore.collection('users').doc(storeId).update({
      'limits.activeProductIds': productIds,
    });
    debugPrint('✅ ActiveItems: Set ${productIds.length} active products');
  }

  /// Save the user's selection of active tables.
  static Future<void> setActiveTables(List<String> tableIds) async {
    final storeId = _storeId;
    if (storeId == null) return;

    await _firestore.collection('users').doc(storeId).update({
      'limits.activeTableIds': tableIds,
    });
    debugPrint('✅ ActiveItems: Set ${tableIds.length} active tables');
  }

  /// Clear active item restrictions (e.g., when upgrading to a higher plan).
  /// All items become active again.
  static Future<void> clearRestrictions() async {
    final storeId = _storeId;
    if (storeId == null) return;

    await _firestore.collection('users').doc(storeId).update({
      'limits.activeProductIds': FieldValue.delete(),
      'limits.activeTableIds': FieldValue.delete(),
    });
    debugPrint('✅ ActiveItems: Cleared all restrictions');
  }

  /// Check if user needs to select active items after a downgrade.
  /// Returns true if productsCount > productsLimit and no selection exists.
  static Future<bool> needsProductSelection() async {
    final storeId = _storeId;
    if (storeId == null) return false;

    final doc = await _firestore.collection('users').doc(storeId).get();
    final data = doc.data();
    final limits = data?['limits'] as Map<String, dynamic>? ?? {};

    final productsCount = (limits['productsCount'] as int?) ?? 0;
    final productsLimit = (limits['productsLimit'] as int?) ?? 50;
    final activeIds = limits['activeProductIds'] as List<dynamic>?;

    // Needs selection if over limit AND no selection made yet
    return productsCount > productsLimit && (activeIds == null || activeIds.isEmpty);
  }

  /// Check if user needs to select active tables.
  static Future<bool> needsTableSelection() async {
    final storeId = _storeId;
    if (storeId == null) return false;

    final doc = await _firestore.collection('users').doc(storeId).get();
    final data = doc.data();
    final limits = data?['limits'] as Map<String, dynamic>? ?? {};

    final tablesCount = (limits['tablesCount'] as int?) ?? 0;
    final tablesLimit = (limits['tablesLimit'] as int?) ?? 5;
    final activeIds = limits['activeTableIds'] as List<dynamic>?;

    return tablesCount > tablesLimit && (activeIds == null || activeIds.isEmpty);
  }
}
