/// Centralized plan configuration — single source of truth for all
/// feature gates and numeric limits per subscription tier.
library;

/// Boolean features that can be gated by plan.
enum PlanFeature {
  kitchenDisplay,
  inventoryBasic,
  inventoryFull,
  cashRegister,
  gstExport,
  reservations,
  coupons,
  reportsBasic, // daily summary
  reports3, // 3 dashboards
  reports9, // 9 dashboards
  reportsCustom, // custom report builder
  multiLocation,
}

/// Immutable configuration for a single subscription plan.
class PlanConfig {
  /// Machine key used in Firestore (`free`, `starter`, `pro`, `business`).
  final String key;

  /// Display name shown in UI.
  final String name;

  // ── Numeric limits ──────────────────────────────────────────────
  /// Max bills per calendar month. `null` = unlimited.
  final int? billsPerMonth;

  /// Max product / menu items. `null` = unlimited.
  final int? maxProducts;

  /// Max tables. `null` = unlimited.
  final int? maxTables;

  /// Max staff users (excludes owner). `null` = unlimited.
  final int? maxStaff;

  /// Max customers (khata entries). `null` = unlimited.
  final int? maxCustomers;

  // ── Feature flags ───────────────────────────────────────────────
  final Set<PlanFeature> _features;

  const PlanConfig({
    required this.key,
    required this.name,
    this.billsPerMonth,
    this.maxProducts,
    this.maxTables,
    this.maxStaff,
    this.maxCustomers,
    Set<PlanFeature> features = const {},
  }) : _features = features;

  /// Whether this plan includes the given feature.
  bool has(PlanFeature feature) => _features.contains(feature);

  /// Firestore-safe numeric limit (uses 999999 for unlimited).
  int get billsLimitFirestore => billsPerMonth ?? 999999;
  int get productsLimitFirestore => maxProducts ?? 999999;
  int get tablesLimitFirestore => maxTables ?? 999999;
  int get staffLimitFirestore => maxStaff ?? 999999;
  int get customersLimitFirestore => maxCustomers ?? 999999;

  // ── Plan definitions ────────────────────────────────────────────

  static const free = PlanConfig(
    key: 'free',
    name: 'Free',
    billsPerMonth: 300,
    maxProducts: 50,
    maxTables: 5,
    maxStaff: 0,
    maxCustomers: 10,
    features: {PlanFeature.reportsBasic},
  );

  static const starter = PlanConfig(
    key: 'starter',
    name: 'Starter',
    maxProducts: 200,
    maxTables: 15,
    maxStaff: 3,
    maxCustomers: 100,
    features: {
      PlanFeature.kitchenDisplay,
      PlanFeature.inventoryBasic,
      PlanFeature.cashRegister,
      PlanFeature.gstExport,
      PlanFeature.reportsBasic,
      PlanFeature.reports3,
    },
  );

  static const pro = PlanConfig(
    key: 'pro',
    name: 'Pro',
    maxTables: 50,
    maxStaff: 10,
    features: {
      PlanFeature.kitchenDisplay,
      PlanFeature.inventoryBasic,
      PlanFeature.inventoryFull,
      PlanFeature.cashRegister,
      PlanFeature.gstExport,
      PlanFeature.reservations,
      PlanFeature.coupons,
      PlanFeature.reportsBasic,
      PlanFeature.reports3,
      PlanFeature.reports9,
    },
  );

  static const business = PlanConfig(
    key: 'business',
    name: 'Business',
    features: {
      PlanFeature.kitchenDisplay,
      PlanFeature.inventoryBasic,
      PlanFeature.inventoryFull,
      PlanFeature.cashRegister,
      PlanFeature.gstExport,
      PlanFeature.reservations,
      PlanFeature.coupons,
      PlanFeature.reportsBasic,
      PlanFeature.reports3,
      PlanFeature.reports9,
      PlanFeature.reportsCustom,
      PlanFeature.multiLocation,
    },
  );

  /// Look up config by plan key string (from Firestore).
  static PlanConfig fromKey(String key) {
    switch (key) {
      case 'starter':
        return starter;
      case 'pro':
        return pro;
      case 'business':
        return business;
      default:
        return free;
    }
  }

  /// Ordered list of all plans (for UI iteration).
  static const List<PlanConfig> allPlans = [free, starter, pro, business];

  /// Human-readable feature list for the subscription screen.
  List<String> get featureDescriptions {
    switch (key) {
      case 'free':
        return [
          '300 bills/month',
          'Up to 50 menu items',
          '5 tables',
          'Single user (Owner)',
          '10 customers',
          'Daily summary report',
          'PDF receipt sharing',
        ];
      case 'starter':
        return [
          'Everything in Free, plus:',
          'Unlimited billing',
          'Up to 200 menu items',
          '15 tables',
          'Up to 3 staff users',
          '100 customers',
          'Kitchen Display System',
          'Basic inventory tracking',
          'Cash register',
          'GST export (GSTR-1)',
          '3 analytics dashboards',
        ];
      case 'pro':
        return [
          'Everything in Starter, plus:',
          'Unlimited menu items & customers',
          '50 tables',
          'Up to 10 staff users',
          'Full inventory & ingredients',
          'Reservations & events',
          'Coupons & discounts',
          '9 analytics dashboards',
        ];
      case 'business':
        return [
          'Everything in Pro, plus:',
          'Unlimited tables & staff',
          'Multi-location management',
          'Custom report builder',
        ];
      default:
        return [];
    }
  }
}
