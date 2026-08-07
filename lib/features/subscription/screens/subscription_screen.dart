import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/permissions/widgets/permission_denied_view.dart';
import 'package:tulasihotels/router/app_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tulasihotels/core/services/cloud_function_helper.dart';
import 'package:tulasihotels/features/hotels/models/hotel_info.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';
import 'package:tulasihotels/features/subscription/providers/subscription_provider.dart';
import 'package:tulasihotels/features/subscription/services/subscription_service.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';

final _activeSubscriptionMetaProvider =
    StreamProvider<Map<String, dynamic>?>((ref) {
      final hotelId = ref.watch(currentHotelIdProvider);
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      final storeId = hotelId ?? ActiveStoreManager.storeId ?? authUid;
      if (storeId == null || storeId.isEmpty) {
        return Stream.value(null);
      }

      return FirebaseFirestore.instance
          .collection('users')
          .doc(storeId)
          .snapshots()
          .map((doc) => doc.data()?['subscription'] as Map<String, dynamic>?);
    });

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
    final restaurantId =
        ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;
    if (restaurantId == null || restaurantId.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
      .doc(restaurantId)
        .get();
    final sub = doc.data()?['subscription'] as Map<String, dynamic>?;
    if (sub != null && mounted) {
      setState(() {
        _currentPlan = _planFromSubscription(sub);
        _subscriptionStatus = _statusFromSubscription(sub);
        _expiresAt = (sub['expiresAt'] as Timestamp?)?.toDate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionPermissions = ref.watch(
      routePermissionProvider(AppRoutes.subscription),
    );
    if (!subscriptionPermissions.isResolved) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Watch real-time subscription plan from Firestore
    final planAsync = ref.watch(subscriptionPlanProvider);
    planAsync.whenData((plan) {
      if (plan != _currentPlan) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _currentPlan = plan);
        });
      }
    });

    // Keep status/expiry in sync when plan is changed from any platform.
    final metaAsync = ref.watch(_activeSubscriptionMetaProvider);
    metaAsync.whenData((sub) {
      final nextStatus = _statusFromSubscription(sub);
      final nextExpiresAt = (sub?['expiresAt'] as Timestamp?)?.toDate();
      final changedStatus = nextStatus != _subscriptionStatus;
      final changedExpiry =
          nextExpiresAt?.millisecondsSinceEpoch !=
          _expiresAt?.millisecondsSinceEpoch;
      if (changedStatus || changedExpiry) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _subscriptionStatus = nextStatus;
            _expiresAt = nextExpiresAt;
          });
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
      body: !subscriptionPermissions.canView
          ? PermissionDeniedView(
              message: PermissionCenter.deniedViewMessage(
                AppRoutes.subscription,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!subscriptionPermissions.canUpdate)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'Read-only access: you can view plans but cannot change subscription.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
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
                        canUpdate: subscriptionPermissions.canUpdate,
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
    required bool canUpdate,
    required String planKey,
    required String name,
    required int monthlyPrice,
    required int annualPrice,
    required List<String> features,
    required Color color,
  }) {
    final isCurrent = _currentPlan == planKey;
    final isDowngrade = _isDowngrade(planKey);
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
                child: isDowngrade
                    ? OutlinedButton.icon(
                        onPressed: _isLoading || !canUpdate
                            ? null
                            : () => _handleDowngrade(planKey, name),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                        ),
                        icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                        label: Text('Downgrade to $name'),
                      )
                    : FilledButton.icon(
                        onPressed: _isLoading || !canUpdate
                            ? null
                            : () => _handleUpgrade(planKey),
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
    final restaurantId =
        ref.read(currentHotelIdProvider) ??
        ActiveStoreManager.storeId ??
        user?.uid;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to upgrade.')),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    // Web, Windows and Android: open pricing page in browser with auto sign-in
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (kIsWeb || isWindows || isAndroid) {
      // Fetch phone — try Firebase Auth first, then Firestore
      // Note: ?? only skips null, not empty strings, so use explicit fallback
      String phone = user.phoneNumber ?? '';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        final stored =
            ((data?['phone'] as String?) ?? '').trim().isNotEmpty
                ? (data!['phone'] as String)
                : ((data?['phoneNumber'] as String?) ?? '').trim().isNotEmpty
                ? (data!['phoneNumber'] as String)
                : phone;
        if (stored.isNotEmpty) phone = stored;
      } catch (_) {}
      phone = phone.replaceAll(RegExp(r'[^0-9]'), '');

      final email = user.email ?? '';
      final name = user.displayName ?? user.email?.split('@').first ?? '';

      // Get custom token for auto sign-in on the pricing page
      String? customToken;
      try {
        final result = await CloudFunctionHelper.call('createPaymentToken');
        customToken = result['token'] as String?;
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isLoading = false);

      final platform = kIsWeb ? 'web' : isWindows ? 'windows' : 'android';
      final queryParams = <String, String>{'plan': planKey, 'cycle': cycle, 'platform': platform};
      if (restaurantId != null && restaurantId.isNotEmpty) {
        queryParams['restaurantId'] = restaurantId;
      }
      if (customToken != null) queryParams['token'] = customToken;
      if (email.isNotEmpty) queryParams['email'] = email;
      if (phone.isNotEmpty) queryParams['phone'] = phone;
      if (name.isNotEmpty) queryParams['name'] = name;
      final url = Uri(
        scheme: 'https',
        host: 'restaurants.tulasierp.com',
        path: '/src/pages/pricing.html',
        queryParameters: queryParams,
      );
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Other platforms: native Razorpay SDK fallback
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

  bool _isDowngrade(String targetPlanKey) {
    const order = ['free', 'starter', 'pro', 'business'];
    final currentIndex = order.indexOf(_currentPlan);
    final targetIndex = order.indexOf(targetPlanKey);
    return targetIndex >= 0 && currentIndex >= 0 && targetIndex < currentIndex;
  }

  Future<void> _handleDowngrade(String planKey, String planName) async {
    String? keepRestaurantId;
    if (_currentPlan == 'business' && planKey != 'free') {
      keepRestaurantId = await _pickDowngradeRestaurant();
      if (keepRestaurantId == null || keepRestaurantId.isEmpty) {
        return;
      }
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Downgrade to $planName?'),
        content: Text(
          _currentPlan == 'business' && planKey != 'free'
              ? 'Only the selected restaurant will keep the paid plan after leaving Business coverage.'
              : 'Some features and limits will be reduced immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Downgrade'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final success = await SubscriptionService().changePlan(
      planKey,
      keepRestaurantId: keepRestaurantId,
      cycle: _isAnnual ? 'annual' : 'monthly',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Plan changed to $planName.'
              : 'Failed to downgrade. Please try again.',
        ),
      ),
    );
    if (success) {
      unawaited(_loadCurrentSubscription());
    }
  }

  Future<String?> _pickDowngradeRestaurant() async {
    final hotels = ref.read(hotelsStreamProvider).valueOrNull ?? const <HotelInfo>[];
    final ownerHotels = hotels.where((hotel) => hotel.isOwner && hotel.planKey == 'business').toList();
    if (ownerHotels.isEmpty) {
      return ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;
    }

    var selectedId = ActiveStoreManager.storeId ?? ownerHotels.first.id;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Choose Pro Restaurant'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedId,
            items: ownerHotels
                .map(
                  (hotel) => DropdownMenuItem<String>(
                    value: hotel.id,
                    child: Text(hotel.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setModalState(() => selectedId = value);
            },
            decoration: const InputDecoration(
              labelText: 'Restaurant to keep on paid plan',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selectedId),
              child: const Text('Continue'),
            ),
          ],
        ),
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

  String _planFromSubscription(Map<String, dynamic>? sub) {
    final effective = (sub?['effectivePlan'] as String?)?.trim();
    if (effective != null && effective.isNotEmpty) return effective;
    return ((sub?['plan'] as String?)?.trim().isNotEmpty ?? false)
        ? (sub!['plan'] as String)
        : 'free';
  }

  String _statusFromSubscription(Map<String, dynamic>? sub) {
    final effective = (sub?['effectiveStatus'] as String?)?.trim();
    if (effective != null && effective.isNotEmpty) return effective;
    return ((sub?['status'] as String?)?.trim().isNotEmpty ?? false)
        ? (sub!['status'] as String)
        : 'active';
  }
}
