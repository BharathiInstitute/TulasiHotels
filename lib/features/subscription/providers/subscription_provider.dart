/// Riverpod provider that streams the current user's subscription plan
/// from Firestore in real-time.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';

/// Real-time subscription plan stream: "free", "starter", "pro", or "business"
final subscriptionPlanProvider = StreamProvider<String>((ref) {
  final authUid = FirebaseAuth.instance.currentUser?.uid;
  if (authUid == null) return Stream.value('free');

  // Prefer currently selected store so owners/members see the same plan.
  final hotelId = ref.watch(currentHotelIdProvider);
  if (hotelId != null && hotelId.isNotEmpty) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(hotelId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          final sub = data?['subscription'] as Map<String, dynamic>?;
          final plan = sub?['plan'] as String?;
          if (plan != null && plan.isNotEmpty) return plan;
          return _inferPlanFromLimits(data);
        });
  }

  // Fallback for legacy/single-store sessions without selected hotel context.
  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUid)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        final sub = data?['subscription'] as Map<String, dynamic>?;
        final plan = sub?['plan'] as String?;
        if (plan != null && plan.isNotEmpty) return plan;
        return _inferPlanFromLimits(data);
      });
});

/// Real-time plan stream for a selected hotel/store doc (users/{hotelId}).
final hotelSubscriptionPlanProvider = StreamProvider.family<String, String>((
  ref,
  hotelId,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(hotelId)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        final sub = data?['subscription'] as Map<String, dynamic>?;
        final plan = sub?['plan'] as String?;
        if (plan != null && plan.isNotEmpty) return plan;
        return _inferPlanFromLimits(data);
      });
});

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

bool _isUnlimited(int value) => value >= 999999;

String _inferPlanFromLimits(Map<String, dynamic>? data) {
  final limits = data?['limits'] as Map<String, dynamic>?;
  if (limits == null) return 'free';

  final staffLimit = _asInt(limits['staffLimit']);
  final tablesLimit = _asInt(limits['tablesLimit']);
  final productsLimit = _asInt(limits['productsLimit']);
  final customersLimit = _asInt(limits['customersLimit']);
  final billsLimit = _asInt(limits['billsLimit']);

  // Business has unlimited staff/tables in our current plan config.
  if (_isUnlimited(staffLimit) || _isUnlimited(tablesLimit)) {
    return 'business';
  }

  // Pro has higher staff/table caps and generally unlimited products/customers.
  if (staffLimit >= 10 ||
      tablesLimit >= 50 ||
      (_isUnlimited(productsLimit) && _isUnlimited(customersLimit))) {
    return 'pro';
  }

  // Starter upgrades key free limits.
  if (staffLimit >= 3 ||
      tablesLimit >= 15 ||
      productsLimit >= 200 ||
      customersLimit >= 100 ||
      _isUnlimited(billsLimit)) {
    return 'starter';
  }

  return 'free';
}

/// Derived provider: current plan's full config (limits + feature flags).
final planConfigProvider = Provider<PlanConfig>((ref) {
  final planAsync = ref.watch(subscriptionPlanProvider);
  return planAsync.when(
    data: (key) => PlanConfig.fromKey(key),
    loading: () => PlanConfig.free,
    error: (_, _) => PlanConfig.free,
  );
});

/// Convenience: check whether the current plan includes a feature.
final hasFeatureProvider = Provider.family<bool, PlanFeature>((ref, feature) {
  return ref.watch(planConfigProvider).has(feature);
});
