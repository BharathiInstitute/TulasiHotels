/// Subscription management service
///
/// Handles plan upgrades via Razorpay (web/desktop) and calls the
/// `activateSubscription` Cloud Function to verify payment + update Firestore.
///
/// Android/iOS: Should use `in_app_purchase` package when Play Store/App Store
/// products are configured. Currently falls back to Razorpay on all platforms.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/core/services/cloud_function_helper.dart';
import 'package:tulasihotels/core/services/razorpay_service.dart';
import 'package:tulasihotels/core/services/user_metrics_service.dart';

/// Pricing map for subscription plans
class SubscriptionPricing {
  static const Map<String, Map<String, double>> prices = {
    'pro': {'monthly': 299, 'annual': 2999},
    'business': {'monthly': 999, 'annual': 9999},
  };

  static double getPrice(String plan, String cycle) {
    return prices[plan]?[cycle] ?? 0;
  }
}

/// Service for managing subscription upgrades
class SubscriptionService {
  SubscriptionService();

  /// Get the current user's subscription from Firestore
  Future<UserSubscription> getCurrentSubscription() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return UserSubscription();

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final subMap = doc.data()?['subscription'] as Map<String, dynamic>?;
    return UserSubscription.fromMap(subMap);
  }

  /// Initiate a subscription upgrade via Razorpay checkout.
  ///
  /// Flow:
  /// 1. Open Razorpay checkout with plan amount
  /// 2. On success, call `activateSubscription` Cloud Function
  /// 3. Cloud Function verifies payment with Razorpay API
  /// 4. Cloud Function updates user subscription in Firestore
  ///
  /// Returns [SubscriptionResult] with success/failure info.
  Future<SubscriptionResult> upgradePlan({
    required String plan,
    required String cycle,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    final price = SubscriptionPricing.getPrice(plan, cycle);
    if (price <= 0) {
      return SubscriptionResult.failure('Invalid plan or cycle');
    }

    // Step 1: Collect payment via Razorpay
    final paymentResult = await _collectPayment(
      amount: price,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      description: '${plan[0].toUpperCase()}${plan.substring(1)} Plan ($cycle)',
    );

    if (!paymentResult.success || paymentResult.paymentId == null) {
      return SubscriptionResult.failure(
        paymentResult.errorMessage ?? 'Payment failed',
      );
    }

    // Step 2: Verify payment & activate subscription via Cloud Function
    try {
      final data = await CloudFunctionHelper.call('activateSubscription', {
        'plan': plan,
        'cycle': cycle,
        'razorpayPaymentId': paymentResult.paymentId,
        'razorpayOrderId': paymentResult.orderId,
        'razorpaySignature': paymentResult.signature,
      });

      if (data['success'] == true) {
        return SubscriptionResult.success(
          plan: plan,
          cycle: cycle,
          expiresAt: data['expiresAt'] as String?,
        );
      } else {
        return SubscriptionResult.failure('Activation failed');
      }
    } catch (e) {
      return SubscriptionResult.failure(e.toString());
    }
  }

  Future<PaymentResult> _collectPayment({
    required double amount,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
    String? description,
  }) async {
    final completer = _RazorpayCompleter();

    RazorpayService.instance.openCheckout(
      amount: amount,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      description: description,
      onComplete: completer.complete,
    );

    return completer.future;
  }
}

/// Result of a subscription upgrade attempt
class SubscriptionResult {
  final bool success;
  final String? plan;
  final String? cycle;
  final String? expiresAt;
  final String? error;

  const SubscriptionResult._({
    required this.success,
    this.plan,
    this.cycle,
    this.expiresAt,
    this.error,
  });

  factory SubscriptionResult.success({
    required String plan,
    required String cycle,
    String? expiresAt,
  }) {
    return SubscriptionResult._(
      success: true,
      plan: plan,
      cycle: cycle,
      expiresAt: expiresAt,
    );
  }

  factory SubscriptionResult.failure(String error) {
    return SubscriptionResult._(success: false, error: error);
  }
}

/// Helper to convert Razorpay callback to Future
class _RazorpayCompleter {
  PaymentResult? _result;
  void Function()? _listener;

  void complete(PaymentResult result) {
    _result = result;
    _listener?.call();
  }

  Future<PaymentResult> get future async {
    if (_result != null) return _result!;

    await Future.doWhile(() async {
      if (_result != null) return false;
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    }).timeout(const Duration(minutes: 10), onTimeout: () {});

    return _result ??
        const PaymentResult(success: false, errorMessage: 'Payment timed out');
  }
}
