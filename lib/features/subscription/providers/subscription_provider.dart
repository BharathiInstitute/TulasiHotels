/// Riverpod provider that streams the current user's subscription plan
/// from Firestore in real-time.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';

/// Real-time subscription plan stream: "free", "starter", "pro", or "business"
final subscriptionPlanProvider = StreamProvider<String>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value('free');

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
        final sub = doc.data()?['subscription'] as Map<String, dynamic>?;
        return (sub?['plan'] as String?) ?? 'free';
      });
});

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
