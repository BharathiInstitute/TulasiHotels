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
/// - If the logged-in user IS the hotel owner (storeId == user.uid) → owner
/// - If they are a member of someone else's hotel → their role/permissions
/// - Returns null (full access) if no hotel selected or doc doesn't exist
final currentMemberProvider = StreamProvider<StoreMember?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  // Use the currently selected hotel as the store ID.
  // Falls back to the user's own UID for backward compatibility.
  final storeId = ref.watch(currentHotelIdProvider) ?? user.uid;

  final docRef = FirebaseFirestore.instance
      .collection('users/$storeId/members')
      .doc(user.uid);

  return docRef.snapshots().map((snap) {
    if (!snap.exists) return null;
    return StoreMember.fromFirestore(snap);
  }).handleError((error) {
    debugPrint('⚠️ currentMemberProvider error: $error');
    return null;
  });
});
