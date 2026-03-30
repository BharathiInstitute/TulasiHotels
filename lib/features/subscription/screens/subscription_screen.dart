import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/subscription/services/subscription_service.dart';

/// Screen for viewing and managing subscription plans.
///
/// **Google Play Billing Policy Compliance:**
/// Digital subscriptions on Android MUST use Google Play Billing (IAP).
/// Razorpay / external payment gateways can only be used for:
///   - Web platform subscriptions
///   - Server-side renewals (outside Google Play)
/// Using external gateways for in-app digital purchases on Android
/// will cause rejection from the Play Store.
///
/// Implementation plan:
///   - Android: Use `in_app_purchase` package with Google Play Billing
///   - Web: Use Razorpay or Stripe payment links
///   - Windows: Use Razorpay or direct bank transfer
///   - iOS (future): Use StoreKit via `in_app_purchase`
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final _service = SubscriptionService();
  bool _upgrading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

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
      body: FutureBuilder(
        future: _service.getCurrentSubscription(),
        builder: (context, snapshot) {
          final currentPlan = snapshot.data?.plan.name ?? 'free';
          final isActive = snapshot.data?.isActive ?? true;
          final expiresAt = snapshot.data?.expiresAt;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose the right plan for your business',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (!isActive && expiresAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Your plan expired. Upgrade to continue using premium features.',
                          style: TextStyle(color: Colors.red.shade800),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildPlanCard(
                  context,
                  name: 'Free',
                  planKey: 'free',
                  price: '₹0',
                  period: 'forever',
                  features: [
                    '50 bills/month',
                    '100 menu items',
                    '10 customers',
                    'Basic reports',
                  ],
                  color: Colors.grey,
                  isCurrent: currentPlan == 'free',
                  userName: user?.ownerName ?? '',
                  userEmail: user?.email,
                  userPhone: user?.phone,
                ),
                const SizedBox(height: 16),
                _buildPlanCard(
                  context,
                  name: 'Pro',
                  planKey: 'pro',
                  price: '₹299',
                  period: '/month',
                  features: [
                    '500 bills/month',
                    '1,000 menu items',
                    '100 customers',
                    'Advanced reports',
                    'Priority support',
                  ],
                  color: Colors.blue,
                  isCurrent: currentPlan == 'pro',
                  userName: user?.ownerName ?? '',
                  userEmail: user?.email,
                  userPhone: user?.phone,
                ),
                const SizedBox(height: 16),
                _buildPlanCard(
                  context,
                  name: 'Business',
                  planKey: 'business',
                  price: '₹999',
                  period: '/month',
                  features: [
                    'Unlimited bills',
                    'Unlimited menu items',
                    'Unlimited customers',
                    'All reports',
                    'Dedicated support',
                    'Multi-device sync',
                  ],
                  color: Colors.purple,
                  isCurrent: currentPlan == 'business',
                  userName: user?.ownerName ?? '',
                  userEmail: user?.email,
                  userPhone: user?.phone,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String name,
    required String planKey,
    required String price,
    required String period,
    required List<String> features,
    required Color color,
    required bool isCurrent,
    required String userName,
    String? userEmail,
    String? userPhone,
  }) {
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
                    text: price,
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
                child: FilledButton(
                  onPressed: _upgrading
                      ? null
                      : () => _handleUpgrade(
                          context,
                          planKey,
                          userName,
                          userEmail,
                          userPhone,
                        ),
                  style: FilledButton.styleFrom(backgroundColor: color),
                  child: _upgrading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Upgrade to $name'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Handle subscription upgrade with platform-aware payment flow.
  ///
  /// - **Android**: Must use Google Play Billing (IAP) per Play Store policy.
  /// - **Web / Windows**: Can use Razorpay, Stripe, or direct payment links.
  /// - **iOS**: Must use StoreKit (Apple IAP) per App Store policy.
  Future<void> _handleUpgrade(
    BuildContext context,
    String planKey,
    String userName,
    String? userEmail,
    String? userPhone,
  ) async {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    if (isAndroid || isIOS) {
      // Google Play / App Store IAP — requires in_app_purchase package setup
      // When Play Console products are configured, replace this with IAP flow
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upgrade via ${isAndroid ? "Google Play" : "App Store"} coming soon!',
          ),
        ),
      );
      return;
    }

    // Web / Desktop: Use Razorpay checkout → activateSubscription Cloud Function
    setState(() => _upgrading = true);

    try {
      final result = await _service.upgradePlan(
        plan: planKey,
        cycle: 'monthly',
        customerName: userName,
        customerEmail: userEmail,
        customerPhone: userPhone,
      );

      if (!mounted) return;

      if (result.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${planKey[0].toUpperCase()}${planKey.substring(1)} plan activated!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Refresh the screen to show updated plan
        setState(() {});
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Upgrade failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _upgrading = false);
    }
  }
}
