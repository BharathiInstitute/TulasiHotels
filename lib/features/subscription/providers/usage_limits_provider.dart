/// Real-time usage limits provider — streams UserLimits from Firestore.
/// Used by all panels to check if limits are reached and show usage counts.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/services/user_metrics_service.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';

/// Real-time stream of the current hotel's usage limits.
/// Driven by Firestore .snapshots() on users/{hotelId}.
final usageLimitsProvider = StreamProvider<UserLimits>((ref) {
  // Use the Riverpod-managed hotel ID so this re-evaluates when hotel changes
  final hotelId = ref.watch(currentHotelIdProvider);
  if (hotelId == null) return Stream.value(UserLimits());

  return FirebaseFirestore.instance
      .collection('users')
      .doc(hotelId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return UserLimits();
        return UserLimits.fromMap(
          doc.data()?['limits'] as Map<String, dynamic>?,
        );
      });
});

/// Convenience: current limits synchronously (defaults to UserLimits() while loading).
final currentLimitsProvider = Provider<UserLimits>((ref) {
  return ref.watch(usageLimitsProvider).valueOrNull ?? UserLimits();
});
