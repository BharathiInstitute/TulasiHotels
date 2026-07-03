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

class PlanEnforcementService {
  PlanEnforcementService._();

  static final _firestore = FirebaseFirestore.instance;

  /// Get the user's current [PlanConfig] from Firestore.
  static Future<PlanConfig> getCurrentPlanConfig() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return PlanConfig.free;

    final doc = await _firestore.collection('users').doc(uid).get();
    final planKey =
        (doc.data()?['subscription'] as Map<String, dynamic>?)?['plan']
            as String? ??
        'free';
    return PlanConfig.fromKey(planKey);
  }

  /// Get the user's current [UserLimits] from Firestore.
  static Future<UserLimits> getCurrentLimits() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return UserLimits();

    final doc = await _firestore.collection('users').doc(uid).get();
    return UserLimits.fromMap(doc.data()?['limits'] as Map<String, dynamic>?);
  }

  /// Check whether the user can perform an action that requires a numeric limit.
  static Future<PlanCheckResult> checkLimit(LimitType type) async {
    final limits = await getCurrentLimits();
    final config = await getCurrentPlanConfig();

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
        if (limits.canAddTable) return const PlanCheckResult.allowed();
        return PlanCheckResult.blocked(
          message:
              'You\'ve reached your table limit (${config.maxTables ?? "∞"}). '
              'Upgrade to ${_nextPlanName(config.key)} for more.',
          suggestedPlan: _nextPlanKey(config.key),
        );

      case LimitType.staff:
        if (limits.canAddStaff) return const PlanCheckResult.allowed();
        final staffLabel = config.maxStaff == 0
            ? 'Staff management requires a paid plan.'
            : 'You\'ve reached your staff limit (${config.maxStaff}).';
        return PlanCheckResult.blocked(
          message: '$staffLabel Upgrade to ${_nextPlanName(config.key)}.',
          suggestedPlan: _nextPlanKey(config.key),
        );

      case LimitType.customers:
        if (limits.canAddCustomer) return const PlanCheckResult.allowed();
        return PlanCheckResult.blocked(
          message:
              'You\'ve reached your customer limit (${config.maxCustomers ?? "∞"}). '
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
