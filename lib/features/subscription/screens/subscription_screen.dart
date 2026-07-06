import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tulasihotels/core/services/cloud_function_helper.dart';
import 'package:tulasihotels/features/subscription/providers/subscription_provider.dart';
import 'package:tulasihotels/features/subscription/services/subscription_service.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';

/// Screen for viewing and managing subscription plans.
///
/// All platforms redirect to the website pricing page for payment via
/// Razorpay Checkout.js. The app listens for Firestore subscription
/// changes in real-time, so the UI updates automatically after payment.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isAnnual = false;
  bool _isLoading = false;

  String _currentPlan = 'free';
  String _subscriptionStatus = 'active';
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final sub = doc.data()?['subscription'] as Map<String, dynamic>?;
    if (sub != null && mounted) {
      setState(() {
        _currentPlan = (sub['plan'] as String?) ?? 'free';
        _subscriptionStatus = (sub['status'] as String?) ?? 'active';
        _expiresAt = (sub['expiresAt'] as Timestamp?)?.toDate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch real-time subscription plan from Firestore
    final planAsync = ref.watch(subscriptionPlanProvider);
    planAsync.whenData((plan) {
      if (plan != _currentPlan) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _currentPlan = plan);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              GoRouter.of(context).go('/billing');
            }
          },
        ),
        title: const Text('Subscription Plans'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose the right plan for your business',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_currentPlan != 'free' && _expiresAt != null)
              Text(
                'Current: ${_currentPlan[0].toUpperCase()}${_currentPlan.substring(1)} '
                '($_subscriptionStatus) — expires ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            const SizedBox(height: 16),
            // Monthly / Annual toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Monthly'),
                Switch(
                  value: _isAnnual,
                  onChanged: (v) => setState(() => _isAnnual = v),
                ),
                const Text('Annual'),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Save ~17%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...PlanConfig.allPlans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPlanCard(
                  context,
                  planKey: plan.key,
                  name: plan.name,
                  monthlyPrice: SubscriptionPricing.getPrice(
                    plan.key,
                    'monthly',
                  ).toInt(),
                  annualPrice: SubscriptionPricing.getPrice(
                    plan.key,
                    'annual',
                  ).toInt(),
                  features: plan.featureDescriptions,
                  color: _planColor(plan.key),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String planKey,
    required String name,
    required int monthlyPrice,
    required int annualPrice,
    required List<String> features,
    required Color color,
  }) {
    final isCurrent = _currentPlan == planKey;
    final price = _isAnnual ? annualPrice : monthlyPrice;
    final period = planKey == 'free'
        ? 'forever'
        : _isAnnual
        ? '/year'
        : '/month';

    return Card(
      elevation: isCurrent ? 0 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (isCurrent)
                  Chip(
                    label: const Text('Current'),
                    backgroundColor: color.withValues(alpha: 0.1),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '₹$price',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  TextSpan(
                    text: period,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!isCurrent && planKey != 'free')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : () => _handleUpgrade(planKey),
                  style: FilledButton.styleFrom(backgroundColor: color),
                  icon: const Icon(Icons.upgrade, size: 18),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Upgrade to $name'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Handle subscription upgrade.
  /// On web/Windows: opens pricing page with auto sign-in token + prefilled details.
  /// On mobile: uses native Razorpay SDK.
  Future<void> _handleUpgrade(String planKey) async {
    setState(() => _isLoading = true);
    final cycle = _isAnnual ? 'annual' : 'monthly';

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to upgrade.')),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    // Web and Windows: open pricing page in browser with auto sign-in
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    if (kIsWeb || isWindows) {
      // Fetch phone from Firestore for prefill
      String phone = user.phoneNumber ?? '';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        phone = (data?['phone'] as String?) ??
            (data?['phoneNumber'] as String?) ??
            phone;
      } catch (_) {}
      phone = phone.replaceAll(RegExp(r'[^0-9]'), '');

      final email = user.email ?? '';

      // Get custom token for auto sign-in on the pricing page
      String? customToken;
      try {
        final result = await CloudFunctionHelper.call('createPaymentToken');
        customToken = result['token'] as String?;
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isLoading = false);

      final queryParams = <String, String>{'plan': planKey, 'cycle': cycle};
      if (customToken != null) queryParams['token'] = customToken;
      if (email.isNotEmpty) queryParams['email'] = email;
      if (phone.isNotEmpty) queryParams['phone'] = phone;
      final url = Uri(
        scheme: 'https',
        host: 'hotels.tulasierp.com',
        path: '/src/pages/pricing.html',
        queryParameters: queryParams,
      );
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }

    // Mobile: check phone verification before native Razorpay
    final phoneVerified = await _isPhoneVerified();
    if (!phoneVerified) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showPhoneRequiredDialog();
      }
      return;
    }

    final service = SubscriptionService();
    final result = await service.upgradePlan(
      plan: planKey,
      cycle: cycle,
      customerName: user.displayName ?? user.email?.split('@').first ?? 'User',
      customerEmail: user.email,
      customerPhone: user.phoneNumber,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Upgraded to ${result.plan ?? planKey}! Enjoy your new features.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Reload subscription state
      unawaited(_loadCurrentSubscription());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Payment failed. Please try again.'),
        ),
      );
    }
  }

  /// Check if the user's phone is verified in Firestore.
  Future<bool> _isPhoneVerified() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return (doc.data()?['phoneVerified'] as bool?) ?? false;
  }

  /// Show dialog telling user to verify phone before upgrading.
  void _showPhoneRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.phone_android, size: 40, color: Colors.orange),
        title: const Text('Phone Verification Required'),
        content: const Text(
          'Please verify your phone number before upgrading your plan.\n\n'
          'Go to Settings → Verification Status → Verify Phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              GoRouter.of(context).push('/settings');
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  static Color _planColor(String key) {
    switch (key) {
      case 'starter':
        return Colors.teal;
      case 'pro':
        return Colors.blue;
      case 'business':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
