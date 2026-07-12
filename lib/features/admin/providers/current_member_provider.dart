/// Provider for the current authenticated user's store membership
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';

/// Streams the current user's member document from the SELECTED hotel's
/// members collection.
///
/// - If no hotel is selected → returns null (no member context)
/// - If the logged-in user IS the hotel owner (storeId == user.uid) → null (owner)
/// - If they are a member of someone else's hotel → their role/permissions
/// - Returns null if doc doesn't exist (owner or unresolved member)
final currentMemberProvider = StreamProvider<StoreMember?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  // Must have a selected hotel — don't fall back to user.uid
  final storeId = ref.watch(currentHotelIdProvider);
  if (storeId == null) return Stream.value(null);

  // Avoid querying a stale/unauthorized hotel ID from local storage.
  // If the selected store is not in the user's accessible hotels list,
  // skip the members query to prevent Firestore permission-denied noise.
  final hotelsAsync = ref.watch(hotelsStreamProvider);
  final canAccessSelectedStore = hotelsAsync.when(
    data: (hotels) => hotels.any((h) => h.id == storeId),
    loading: () => true,
    error: (_, __) => false,
  );
  if (!canAccessSelectedStore) {
    debugPrint(
      '⚠️ currentMemberProvider: skipping member query for inaccessible store $storeId',
    );
    return Stream.value(null);
  }

  // If user IS the store owner, no member doc needed (full access)
  if (storeId == user.uid) return Stream.value(null);

  final docRef = FirebaseFirestore.instance
      .collection('users/$storeId/members')
      .doc(user.uid);

  return docRef
      .snapshots()
      .map((snap) {
        if (!snap.exists) return null;
        return StoreMember.fromFirestore(snap);
      })
      .handleError((error) {
        debugPrint('⚠️ currentMemberProvider error: $error');
        return null;
      });
});
