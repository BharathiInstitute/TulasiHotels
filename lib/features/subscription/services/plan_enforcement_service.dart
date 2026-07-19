/// Service that checks plan limits and feature access.
///
/// Call [checkLimit] before creating a resource (staff, table, product, etc.)
/// and [checkFeature] before opening a gated screen.
/// Both return a [PlanCheckResult] that indicates whether the action is allowed
/// and provides an upgrade message when it isn't.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:tulasihotels/core/services/connectivity_service.dart';
import 'package:tulasihotels/core/services/user_metrics_service.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';

/// Result of a plan limit / feature check.
class PlanCheckResult {
  final bool allowed;
  final String? message;
  final String? suggestedPlan;

  const PlanCheckResult.allowed()
    : allowed = true,
      message = null,
      suggestedPlan = null;

  const PlanCheckResult.blocked({required this.message, this.suggestedPlan})
    : allowed = false;
}

/// Limit types that can be checked.
enum LimitType { bills, products, tables, staff, customers }

/// Exception thrown when a plan limit is reached.
class PlanLimitException implements Exception {
  final String message;
  const PlanLimitException(this.message);
  @override
  String toString() => message;
}

class PlanEnforcementService {
  PlanEnforcementService._();

  static final _firestore = FirebaseFirestore.instance;

  /// Returns the active store/owner UID — always the owner's doc regardless
  /// of whether the current Firebase user is the owner or a team member.
  static String? get _storeId =>
      ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;

  /// Returns the Firebase Auth UID of the current user.
  /// Subscription and plan data are ALWAYS stored under this UID, not the hotel ID.
  static String? get _ownerUid => FirebaseAuth.instance.currentUser?.uid;

  /// Get the store's current [PlanConfig] from Firestore.
  static Future<PlanConfig> getCurrentPlanConfig() async {
    final ownerUid = _ownerUid;
    if (ownerUid == null) return PlanConfig.free;

    final doc = await _firestore.collection('users').doc(ownerUid).get();
    final planKey =
        (doc.data()?['subscription'] as Map<String, dynamic>?)?['plan']
            as String? ??
        'free';
    return PlanConfig.fromKey(planKey);
  }

  /// Get the store's current [UserLimits] from Firestore.
  static Future<UserLimits> getCurrentLimits() async {
    final ownerUid = _ownerUid;
    if (ownerUid == null) return UserLimits();

    final doc = await _firestore.collection('users').doc(ownerUid).get();
    return UserLimits.fromMap(doc.data()?['limits'] as Map<String, dynamic>?);
  }

  /// Check whether the user can perform an action that requires a numeric limit.
  ///
  /// Does a single fresh Firestore read for plan + limits to eliminate stale
  /// cache issues — snackbar only appears when the real limit is reached.
  static Future<PlanCheckResult> checkLimit(LimitType type) async {
    // When offline, never block — all features should work offline
    if (ConnectivityService.isOffline) return const PlanCheckResult.allowed();

    final storeId = _storeId;   // hotel ID — used for counting staff/tables/products
    final ownerUid = _ownerUid; // Firebase Auth UID — used for subscription & limits

    // Read subscription from owner's Firebase Auth UID doc (where Cloud Functions write it).
    // This is DIFFERENT from storeId (hotel ID) which has no subscription data.
    Map<String, dynamic>? subscriptionData;
    Map<String, dynamic>? limitsData;
    if (ownerUid != null) {
      try {
        // Force server read with timeout — subscription is always on owner's Firebase Auth UID doc
        final doc = await _firestore
            .collection('users')
            .doc(ownerUid)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
        final data = doc.data();
        subscriptionData = data?['subscription'] as Map<String, dynamic>?;
        limitsData = data?['limits'] as Map<String, dynamic>?;
      } catch (e) {
        // Server unavailable or timeout — fall back to cache
        try {
          final doc = await _firestore.collection('users').doc(ownerUid).get(const GetOptions(source: Source.cache));
          final data = doc.data();
          subscriptionData = data?['subscription'] as Map<String, dynamic>?;
          limitsData = data?['limits'] as Map<String, dynamic>?;
        } catch (_) {}
      }
    }

    final planKey = (subscriptionData?['plan'] as String?) ?? 'free';
    final config = PlanConfig.fromKey(planKey);
    final limits = UserLimits.fromMap(limitsData);

    // Helper: effective limit = max(plan config, stored Firestore limit)
    // Ensures stale Firestore limits (e.g., 0 from free plan) never
    // incorrectly block users who have already upgraded to a paid plan.
    int effectiveLimit(int planLimit, int storedLimit) =>
        planLimit > storedLimit ? planLimit : storedLimit;

    switch (type) {
      case LimitType.bills:
        if (limits.canCreateBill) return const PlanCheckResult.allowed();
        return PlanCheckResult.blocked(
          message:
              'You\'ve reached your monthly bill limit (${config.billsPerMonth ?? "∞"}). '
              'Upgrade to ${_nextPlanName(config.key)} for more.',
          suggestedPlan: _nextPlanKey(config.key),
        );

      case LimitType.products:
        if (limits.canAddProduct) return const PlanCheckResult.allowed();
        return PlanCheckResult.blocked(
          message:
              'You\'ve reached your product limit (${config.maxProducts ?? "∞"}). '
              'Upgrade to ${_nextPlanName(config.key)} for more.',
          suggestedPlan: _nextPlanKey(config.key),
        );

      case LimitType.tables:
        if (storeId != null) {
          try {
            final snap = await _firestore
                .collection('users')
                .doc(storeId)
                .collection('tables')
                .count()
                .get()
                .timeout(const Duration(seconds: 5));
            final realCount = snap.count ?? 0;
            final tableLimit = effectiveLimit(config.maxTables ?? 999999, limits.tablesLimit);
            if (tableLimit > 0 && realCount >= tableLimit) {
              return PlanCheckResult.blocked(
                message: 'You\'ve reached your table limit ($tableLimit). '
                    'Upgrade to ${_nextPlanName(config.key)}.',
                suggestedPlan: _nextPlanKey(config.key),
              );
            }
          } catch (_) {
            // count() failed (offline or timeout) — allow the action
          }
          return const PlanCheckResult.allowed();
        }
        if (limits.canAddTable) return const PlanCheckResult.allowed();
        return PlanCheckResult.blocked(
          message: 'You\'ve reached your table limit (${config.maxTables ?? "∞"}). '
              'Upgrade to ${_nextPlanName(config.key)} for more.',
          suggestedPlan: _nextPlanKey(config.key),
        );

      case LimitType.staff:
        if (storeId != null) {
          try {
            final results = await Future.wait([
              _firestore.collection('users').doc(storeId)
                  .collection('staff').count().get(),
              _firestore.collection('users').doc(storeId)
                  .collection('members')
                  .where('role', isNotEqualTo: 'owner')
                  .count()
                  .get(),
            ]).timeout(const Duration(seconds: 5));
            final realStaffCount = (results[0].count ?? 0) + (results[1].count ?? 0);
            final staffLimit = effectiveLimit(config.maxStaff ?? 0, limits.staffLimit);

            if (staffLimit == 0) {
              return PlanCheckResult.blocked(
                message: 'Staff management requires a paid plan. '
                    'Upgrade to ${_nextPlanName(config.key)}.',
                suggestedPlan: _nextPlanKey(config.key),
              );
            }
            if (realStaffCount >= staffLimit) {
              return PlanCheckResult.blocked(
                message: 'You\'ve reached your staff limit ($staffLimit). '
                    'Upgrade to ${_nextPlanName(config.key)}.',
                suggestedPlan: _nextPlanKey(config.key),
              );
            }
          } catch (_) {
            // count() failed (offline or timeout) — allow the action
          }
          return const PlanCheckResult.allowed();
        }
        if (limits.canAddStaff) return const PlanCheckResult.allowed();
        return PlanCheckResult.blocked(
          message: config.maxStaff == 0
              ? 'Staff management requires a paid plan. Upgrade to ${_nextPlanName(config.key)}.'
              : 'You\'ve reached your staff limit (${config.maxStaff}). Upgrade to ${_nextPlanName(config.key)}.',
          suggestedPlan: _nextPlanKey(config.key),
        );

      case LimitType.customers:
        if (limits.canAddCustomer) return const PlanCheckResult.allowed();
        return PlanCheckResult.blocked(
          message: 'You\'ve reached your customer limit (${config.maxCustomers ?? "∞"}). '
              'Upgrade to ${_nextPlanName(config.key)} for more.',
          suggestedPlan: _nextPlanKey(config.key),
        );
    }
  }

  /// Check whether the user's plan includes a boolean feature.
  static Future<PlanCheckResult> checkFeature(PlanFeature feature) async {
    final config = await getCurrentPlanConfig();
    if (config.has(feature)) return const PlanCheckResult.allowed();

    return PlanCheckResult.blocked(
      message:
          '${_featureLabel(feature)} is not available on the ${config.name} plan. '
          'Upgrade to ${_nextPlanWithFeature(feature)} to unlock it.',
      suggestedPlan: _nextPlanKeyWithFeature(feature),
    );
  }

  /// Synchronously check a feature if you already have the config.
  static PlanCheckResult checkFeatureSync(
    PlanConfig config,
    PlanFeature feature,
  ) {
    if (config.has(feature)) return const PlanCheckResult.allowed();
    return PlanCheckResult.blocked(
      message:
          '${_featureLabel(feature)} is not available on the ${config.name} plan. '
          'Upgrade to ${_nextPlanWithFeature(feature)} to unlock it.',
      suggestedPlan: _nextPlanKeyWithFeature(feature),
    );
  }

  /// Update Firestore limits when plan changes (called after successful payment).
  /// Uses the active store ID so multi-hotel setups are handled correctly.
  /// Clears active item restrictions when upgrading (all items become usable).
  static Future<void> syncLimitsForPlan(String planKey) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    // Use the active store (falls back to uid for single-store users)
    final storeId = ActiveStoreManager.storeId ?? uid;

    final config = PlanConfig.fromKey(planKey);
    await _firestore.collection('users').doc(storeId).update({
      'limits.billsLimit': config.billsLimitFirestore,
      'limits.productsLimit': config.productsLimitFirestore,
      'limits.customersLimit': config.customersLimitFirestore,
      'limits.staffLimit': config.staffLimitFirestore,
      'limits.tablesLimit': config.tablesLimitFirestore,
      'limits.activeProductIds': FieldValue.delete(),
      'limits.activeTableIds': FieldValue.delete(),
      'subscription.plan': planKey,
    });
  }

  // ── Helpers ───────────────────────────────────────────────────

  static String _nextPlanKey(String current) {
    const order = ['free', 'starter', 'pro', 'business'];
    final idx = order.indexOf(current);
    if (idx < 0 || idx >= order.length - 1) return 'business';
    return order[idx + 1];
  }

  static String _nextPlanName(String current) {
    return PlanConfig.fromKey(_nextPlanKey(current)).name;
  }

  static String _nextPlanWithFeature(PlanFeature feature) {
    for (final plan in PlanConfig.allPlans) {
      if (plan.has(feature)) return plan.name;
    }
    return 'Business';
  }

  static String? _nextPlanKeyWithFeature(PlanFeature feature) {
    for (final plan in PlanConfig.allPlans) {
      if (plan.has(feature)) return plan.key;
    }
    return 'business';
  }

  static String _featureLabel(PlanFeature feature) {
    switch (feature) {
      case PlanFeature.kitchenDisplay:
        return 'Kitchen Display System';
      case PlanFeature.inventoryBasic:
        return 'Inventory tracking';
      case PlanFeature.inventoryFull:
        return 'Full inventory & ingredients';
      case PlanFeature.cashRegister:
        return 'Cash register';
      case PlanFeature.gstExport:
        return 'GST export';
      case PlanFeature.reservations:
        return 'Reservations';
      case PlanFeature.coupons:
        return 'Coupons & discounts';
      case PlanFeature.reportsBasic:
        return 'Basic reports';
      case PlanFeature.reports3:
        return '3 analytics dashboards';
      case PlanFeature.reports9:
        return '9 analytics dashboards';
      case PlanFeature.reportsCustom:
        return 'Custom report builder';
      case PlanFeature.multiLocation:
        return 'Multi-location management';
    }
  }
}
