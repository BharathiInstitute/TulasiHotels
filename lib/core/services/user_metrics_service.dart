/// User metrics service for tracking activity and syncing to Firestore
/// This data is used by the Super Admin Panel
library;

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:tulasihotels/core/services/error_logging_service.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Subscription plans
enum SubscriptionPlan { free, starter, pro, business }

/// Subscription status
enum SubscriptionStatus { active, trial, expired, cancelled }

/// User subscription model
class UserSubscription {
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String? razorpayCustomerId;
  final String? razorpaySubscriptionId;

  UserSubscription({
    this.plan = SubscriptionPlan.free,
    this.status = SubscriptionStatus.active,
    this.startedAt,
    this.expiresAt,
    this.razorpayCustomerId,
    this.razorpaySubscriptionId,
  });

  Map<String, dynamic> toMap() => {
    'plan': plan.name,
    'status': status.name,
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'razorpayCustomerId': razorpayCustomerId,
    'razorpaySubscriptionId': razorpaySubscriptionId,
  };

  factory UserSubscription.fromMap(Map<String, dynamic>? map) {
    if (map == null) return UserSubscription();
    return UserSubscription(
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == map['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      razorpayCustomerId: map['razorpayCustomerId'] as String?,
      razorpaySubscriptionId: map['razorpaySubscriptionId'] as String?,
    );
  }

  /// Get the [PlanConfig] for this subscription's plan.
  PlanConfig get config => PlanConfig.fromKey(plan.name);

  /// Get plan limits (delegated to PlanConfig)
  int get billsLimit => config.billsLimitFirestore;
  int get productsLimit => config.productsLimitFirestore;
  int get customersLimit => config.customersLimitFirestore;
  int get staffLimit => config.staffLimitFirestore;
  int get tablesLimit => config.tablesLimitFirestore;

  bool get isActive =>
      status == SubscriptionStatus.active || status == SubscriptionStatus.trial;
}

/// User activity tracking
class UserActivity {
  final DateTime? lastActiveAt;
  final String? appVersion;
  final String? platform;
  final String? deviceModel;

  UserActivity({
    this.lastActiveAt,
    this.appVersion,
    this.platform,
    this.deviceModel,
  });

  Map<String, dynamic> toMap() => {
    'lastActiveAt': lastActiveAt != null
        ? Timestamp.fromDate(lastActiveAt!)
        : FieldValue.serverTimestamp(),
    'appVersion': appVersion,
    'platform': platform,
    'deviceModel': deviceModel,
  };
}

/// User limits tracking
class UserLimits {
  final int billsThisMonth;
  final int billsLimit;
  final int productsCount;
  final int productsLimit;
  final int customersCount;
  final int customersLimit;
  final int staffCount;
  final int staffLimit;
  final int tablesCount;
  final int tablesLimit;

  UserLimits({
    this.billsThisMonth = 0,
    this.billsLimit = 300,
    this.productsCount = 0,
    this.productsLimit = 50,
    this.customersCount = 0,
    this.customersLimit = 10,
    this.staffCount = 0,
    this.staffLimit = 0,
    this.tablesCount = 0,
    this.tablesLimit = 5,
  });

  Map<String, dynamic> toMap() => {
    'billsThisMonth': billsThisMonth,
    'billsLimit': billsLimit,
    'productsCount': productsCount,
    'productsLimit': productsLimit,
    'customersCount': customersCount,
    'customersLimit': customersLimit,
    'staffCount': staffCount,
    'staffLimit': staffLimit,
    'tablesCount': tablesCount,
    'tablesLimit': tablesLimit,
  };

  factory UserLimits.fromMap(Map<String, dynamic>? map) {
    if (map == null) return UserLimits();
    return UserLimits(
      billsThisMonth: (map['billsThisMonth'] as int?) ?? 0,
      billsLimit: (map['billsLimit'] as int?) ?? 300,
      productsCount: (map['productsCount'] as int?) ?? 0,
      productsLimit: (map['productsLimit'] as int?) ?? 50,
      customersCount: (map['customersCount'] as int?) ?? 0,
      customersLimit: (map['customersLimit'] as int?) ?? 10,
      staffCount: (map['staffCount'] as int?) ?? 0,
      staffLimit: (map['staffLimit'] as int?) ?? 0,
      tablesCount: (map['tablesCount'] as int?) ?? 0,
      tablesLimit: (map['tablesLimit'] as int?) ?? 5,
    );
  }

  bool get canCreateBill => billsThisMonth < billsLimit;
  bool get canAddProduct => productsCount < productsLimit;
  bool get canAddCustomer => customersCount < customersLimit;
  bool get canAddStaff => staffCount < staffLimit;
  bool get canAddTable => tablesCount < tablesLimit;
  int get billsRemaining => billsLimit - billsThisMonth;
  int get productsRemaining => productsLimit - productsCount;
  int get customersRemaining => customersLimit - customersCount;
  int get staffRemaining => staffLimit - staffCount;
  int get tablesRemaining => tablesLimit - tablesCount;
}

/// Service for tracking user metrics and syncing to Firestore
class UserMetricsService {
  UserMetricsService._();

  static String _appVersion = '1.0.0';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static SharedPreferences? _prefs;

  // Local cache keys
  static const String _userIdKey = 'user_id';

  /// Initialize
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    // Get real version from PackageInfo
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (e) {
      debugPrint('⚠️ PackageInfo unavailable: $e');
    }
    // Enforce subscription expiry on every app launch (fire and forget)
    _checkAndEnforceSubscription().ignore();
  }

  /// Checks if current subscription has expired and downgrades to free if so.
  /// Safe to call on every launch — reads one document from Firestore.
  static Future<void> _checkAndEnforceSubscription() async {
    final userId = _getUserId();
    if (userId == null) return;
    try {
      final snap = await _firestore.collection('users').doc(userId).get();
      if (!snap.exists) return;
      final sub = UserSubscription.fromMap(
        snap.data()?['subscription'] as Map<String, dynamic>?,
      );
      // Only enforce for paid plans that have an expiry date
      if (sub.plan == SubscriptionPlan.free) return;
      if (sub.expiresAt == null) return;
      if (!DateTime.now().isAfter(sub.expiresAt!)) return;

      // Subscription expired — downgrade to free limits
      const freeLimits = PlanConfig.free;
      await _firestore.collection('users').doc(userId).update({
        'subscription.status': SubscriptionStatus.expired.name,
        'subscription.plan': SubscriptionPlan.free.name,
        'limits.billsLimit': freeLimits.billsLimitFirestore,
        'limits.productsLimit': freeLimits.productsLimitFirestore,
        'limits.customersLimit': freeLimits.customersLimitFirestore,
        'limits.staffLimit': freeLimits.staffLimitFirestore,
        'limits.tablesLimit': freeLimits.tablesLimitFirestore,
      });
      debugPrint('⚠️ UserMetrics: Subscription expired — downgraded to free');
    } catch (e, st) {
      debugPrint('❌ UserMetrics: Subscription expiry check failed: $e');
      ErrorLoggingService.logError(
        error: e,
        stackTrace: st,
        metadata: {'context': 'Subscription expiry enforcement'},
      ).ignore();
    }
  }

  /// Get the active store/user ID used for all limit checks.
  /// Uses ActiveStoreManager.storeId (the same document that Firestore
  /// security rules and Cloud Functions operate on).
  static String? _getUserId() {
    // Use the active store ID (same doc rules/CFs use)
    final storeId = ActiveStoreManager.storeId;
    if (storeId != null && storeId.isNotEmpty) return storeId;
    // Fallback to Firebase Auth uid
    final user = _auth.currentUser;
    if (user != null) return user.uid;
    // Fallback to stored user ID
    return _prefs?.getString(_userIdKey);
  }

  /// Track user activity (call on app launch and key actions)
  static Future<void> trackActivity() async {
    final userId = _getUserId();
    if (userId == null) return;

    try {
      String platform = 'unknown';

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          platform = 'android';
        } else if (Platform.isIOS) {
          platform = 'ios';
        } else if (Platform.isWindows) {
          platform = 'windows';
        } else if (Platform.isMacOS) {
          platform = 'macos';
        } else if (Platform.isLinux) {
          platform = 'linux';
        }
      } else {
        platform = 'web';
      }

      await _firestore.collection('users').doc(userId).set({
        'activity': {
          'lastActiveAt': FieldValue.serverTimestamp(),
          'appVersion': _appVersion,
          'platform': platform,
        },
      }, SetOptions(merge: true));

      debugPrint('📊 UserMetrics: Activity tracked');
    } catch (e, st) {
      debugPrint('❌ UserMetrics: Failed to track activity: $e');
      ErrorLoggingService.logError(
        error: e,
        stackTrace: st,
        severity: ErrorSeverity.warning,
        metadata: {'context': 'trackActivity'},
      ).ignore();
    }
  }

  /// Check bill limit — read-only, does NOT increment.
  /// The Cloud Function `onBillCreated` is the sole authority for incrementing
  /// `billsThisMonth` to prevent double-counting.
  static Future<bool> trackBillCreated() async {
    final userId = _getUserId();
    if (userId == null) return true; // Allow if not logged in

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final snap = await userRef.get();
      final data = snap.data() ?? {};
      final limitsMap = data['limits'] as Map<String, dynamic>? ?? {};
      final now = DateTime.now();
      final currentMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final lastResetMonth = (limitsMap['lastResetMonth'] as String?) ?? '';
      final isNewMonth = lastResetMonth != currentMonth;
      final billsThisMonth = isNewMonth
          ? 0
          : ((limitsMap['billsThisMonth'] as int?) ?? 0);
      final limit = (limitsMap['billsLimit'] as int?) ?? 300;
      final allowed = billsThisMonth < limit;

      if (!allowed) {
        debugPrint('⚠️ UserMetrics: Bill limit reached ($billsThisMonth/$limit)');
      }
      return allowed;
    } catch (e, st) {
      debugPrint('❌ UserMetrics: Failed to check bill limit: $e');
      ErrorLoggingService.logError(
        error: e,
        stackTrace: st,
        severity: ErrorSeverity.warning,
        metadata: {'context': 'trackBillCreated'},
      ).ignore();
      return true; // Don't block billing on transient Firestore errors
    }
  }

  /// Track product added — no-op; Cloud Function `onProductCreated` is the
  /// sole authority for incrementing `productsCount` to prevent double-counting.
  static Future<void> trackProductAdded() async {
    // Intentionally empty — handled by Cloud Function onProductCreated.
  }

  /// Track product deleted — no-op; Cloud Function `onProductDeleted` is the
  /// sole authority for decrementing `productsCount` to prevent double-counting.
  static Future<void> trackProductDeleted() async {
    // Intentionally empty — handled by Cloud Function onProductDeleted.
  }

  /// Track customer added — no-op; Cloud Function `onCustomerCreated` is the
  /// sole authority for incrementing `customersCount` to prevent double-counting.
  static Future<void> trackCustomerAdded() async {
    // Intentionally empty — handled by Cloud Function onCustomerCreated.
  }

  /// Get user's current limits
  static Future<UserLimits> getUserLimits() async {
    final userId = _getUserId();
    if (userId == null) return UserLimits();

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return UserLimits();

      final data = doc.data();
      return UserLimits.fromMap(data?['limits'] as Map<String, dynamic>?);
    } catch (e, st) {
      debugPrint('❌ UserMetrics: Failed to get limits: $e');
      ErrorLoggingService.logError(
        error: e,
        stackTrace: st,
        severity: ErrorSeverity.warning,
        metadata: {'context': 'getUserLimits'},
      ).ignore();
      return UserLimits();
    }
  }

  /// Get user's subscription
  static Future<UserSubscription> getUserSubscription() async {
    final userId = _getUserId();
    if (userId == null) return UserSubscription();

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return UserSubscription();

      final data = doc.data();
      return UserSubscription.fromMap(
        data?['subscription'] as Map<String, dynamic>?,
      );
    } catch (e, st) {
      debugPrint('❌ UserMetrics: Failed to get subscription: $e');
      ErrorLoggingService.logError(
        error: e,
        stackTrace: st,
        severity: ErrorSeverity.warning,
        metadata: {'context': 'getUserSubscription'},
      ).ignore();
      return UserSubscription();
    }
  }

  // Monthly reset is now handled atomically inside trackBillCreated.

  /// Initialize user document with default values
  static Future<void> initializeUser({
    required String userId,
    required String email,
    required String shopName,
    required String ownerName,
    String? phone,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'shopName': shopName,
        'ownerName': ownerName,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'subscription': UserSubscription().toMap(),
        'limits': UserLimits().toMap(),
        'activity': {
          'lastActiveAt': FieldValue.serverTimestamp(),
          'appVersion': _appVersion,
          'platform': kIsWeb
              ? 'web'
              : (Platform.isAndroid
                    ? 'android'
                    : (Platform.isWindows ? 'windows' : 'ios')),
        },
      }, SetOptions(merge: true));

      // Save user ID locally
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(_userIdKey, userId);

      debugPrint('📊 UserMetrics: User initialized in Firestore');
    } catch (e, st) {
      debugPrint('❌ UserMetrics: Failed to initialize user: $e');
      ErrorLoggingService.logError(
        error: e,
        stackTrace: st,
        metadata: {'context': 'initializeUser'},
      ).ignore();
    }
  }
}
