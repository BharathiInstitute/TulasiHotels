/// Riverpod providers for active item restrictions (downgrade enforcement).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/services/active_store_manager.dart';

/// Streams the set of active product IDs from Firestore.
/// Returns null if no restriction (all products active).
final activeProductIdsProvider = StreamProvider<Set<String>?>((ref) {
  final storeId =
      ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;
  if (storeId == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(storeId)
      .snapshots()
      .map((doc) {
    final ids = doc.data()?['limits']?['activeProductIds'] as List<dynamic>?;
    if (ids == null || ids.isEmpty) return null;
    return ids.cast<String>().toSet();
  });
});

/// Streams the set of active table IDs from Firestore.
/// Returns null if no restriction (all tables active).
final activeTableIdsProvider = StreamProvider<Set<String>?>((ref) {
  final storeId =
      ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;
  if (storeId == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(storeId)
      .snapshots()
      .map((doc) {
    final ids = doc.data()?['limits']?['activeTableIds'] as List<dynamic>?;
    if (ids == null || ids.isEmpty) return null;
    return ids.cast<String>().toSet();
  });
});

/// Check if a specific product is active (usable in billing).
/// If provider returns null, all products are active (no downgrade restriction).
bool isProductActive(Set<String>? activeIds, String productId) {
  if (activeIds == null) return true;
  return activeIds.contains(productId);
}

/// Check if a specific table is active.
bool isTableActive(Set<String>? activeIds, String tableId) {
  if (activeIds == null) return true;
  return activeIds.contains(tableId);
}
