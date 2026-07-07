/// Manage Subscription panel — shows current plan, usage overview,
/// and actions (change plan, cancel, resume).
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:tulasihotels/core/services/cloud_function_helper.dart';
import 'package:tulasihotels/core/services/user_metrics_service.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';
import 'package:tulasihotels/features/subscription/providers/subscription_provider.dart';
import 'package:tulasihotels/features/subscription/services/active_items_service.dart';
import 'package:tulasihotels/features/subscription/services/subscription_service.dart';
import 'package:tulasihotels/features/subscription/widgets/active_item_selection_modal.dart';
import 'package:tulasihotels/features/subscription/widgets/cancel_subscription_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full manage-subscription panel designed to be embedded in a settings tab.
class ManageSubscriptionPanel extends ConsumerStatefulWidget {
  const ManageSubscriptionPanel({super.key});

  @override
  ConsumerState<ManageSubscriptionPanel> createState() =>
      _ManageSubscriptionPanelState();
}

class _ManageSubscriptionPanelState
    extends ConsumerState<ManageSubscriptionPanel> {
  String _currentPlan = 'free';
  String _status = 'active';
  DateTime? _expiresAt;
  UserLimits _limits = UserLimits();
  bool _loading = true;
  bool _showPlans = false;
  bool _isUpgrading = false;
  String? _userEmail;
  String? _userPhone;
  DateTime? _lastResync;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userEmail = user?.email;
    _userPhone = user?.phoneNumber;
    _subscribeToLimits();
    _resyncCounts();
  }

  /// Resync counts from Firestore (runs on every panel open, debounced to 30s).
  Future<void> _resyncCounts() async {
    final now = DateTime.now();
    if (_lastResync != null && now.difference(_lastResync!).inSeconds < 30) return;
    _lastResync = now;

    final storeId =
        ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;
    if (storeId == null) return;
    try {
      final base = 'users/$storeId';
      final db = FirebaseFirestore.instance;

      // Get current user doc to check if limits are properly set
      final userDoc = await db.collection('users').doc(storeId).get();
      final currentLimits = userDoc.data()?['limits'] as Map<String, dynamic>? ?? {};
      final currentPlan = (userDoc.data()?['subscription'] as Map<String, dynamic>?)?['plan'] as String? ?? 'free';

      final results = await Future.wait([
        db.collection('$base/tables').count().get(),
        db.collection('$base/members').count().get(), // Firebase team members
        db.collection('$base/staff').count().get(),   // local PIN-based staff
        db.collection('$base/products').count().get(),
        db.collection('$base/customers').count().get(),
      ]);
      final tablesCount = results[0].count ?? 0;
      final membersCount = results[1].count ?? 0;
      final localStaffCount = results[2].count ?? 0;
      final staffCount = membersCount + localStaffCount; // combined total
      final productsCount = results[3].count ?? 0;
      final customersCount = results[4].count ?? 0;

      final updates = <String, dynamic>{
        'limits.tablesCount': tablesCount,
        'limits.staffCount': staffCount,
        'limits.productsCount': productsCount,
        'limits.customersCount': customersCount,
      };

      // Fix missing limits based on current plan (ensures CFs don't use wrong defaults)
      final config = PlanConfig.fromKey(currentPlan);
      if (currentLimits['staffLimit'] == null) {
        updates['limits.staffLimit'] = config.staffLimitFirestore;
      }
      if (currentLimits['tablesLimit'] == null) {
        updates['limits.tablesLimit'] = config.tablesLimitFirestore;
      }
      if (currentLimits['billsLimit'] == null) {
        updates['limits.billsLimit'] = config.billsLimitFirestore;
      }
      if (currentLimits['productsLimit'] == null) {
        updates['limits.productsLimit'] = config.productsLimitFirestore;
      }
      if (currentLimits['customersLimit'] == null) {
        updates['limits.customersLimit'] = config.customersLimitFirestore;
      }

      await db.collection('users').doc(storeId).update(updates);

      // Also update the UI immediately without waiting for Firestore stream
      if (mounted) {
        setState(() {
          _limits = _limits.copyWith(
            tablesCount: tablesCount,
            staffCount: staffCount,
            productsCount: productsCount,
            customersCount: customersCount,
          );
        });
      }
    } catch (_) {
      // Best-effort — ignore errors
    }
  }

  /// Real-time listener on the user/store document so Usage Overview
  /// updates instantly whenever Cloud Functions write new counts.
  void _subscribeToLimits() {
    final storeId =
        ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;
    if (storeId == null) {
      setState(() => _loading = false);
      return;
    }

    _docSub = FirebaseFirestore.instance
        .collection('users')
        .doc(storeId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data()!;
      final sub = data['subscription'] as Map<String, dynamic>?;
      final limitsMap = data['limits'] as Map<String, dynamic>?;
      setState(() {
        _currentPlan = (sub?['plan'] as String?) ?? 'free';
        _status = (sub?['status'] as String?) ?? 'active';
        _expiresAt = (sub?['expiresAt'] as Timestamp?)?.toDate();
        _limits = UserLimits.fromMap(limitsMap);
        _userPhone ??= (data['phone'] as String?) ?? (data['phoneNumber'] as String?);
        _loading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  // kept for compatibility with plan-change reload in build()
  Future<void> _loadData() async {
    // no-op: real-time stream handles all updates
  }

  @override
  void dispose() {
    _docSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch real-time plan changes
    final planAsync = ref.watch(subscriptionPlanProvider);
    planAsync.whenData((plan) {
      if (plan != _currentPlan) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _currentPlan = plan);
            _loadData();
          }
        });
      }
    });

    final cs = Theme.of(context).colorScheme;
    final config = PlanConfig.fromKey(_currentPlan);
    final isFree = _currentPlan == 'free';
    final isCancelled = _status == 'cancelled';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_showPlans) {
      return _buildPlansView(context, cs);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Subscription',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // ── Current Plan Card ──
          _buildCurrentPlanCard(context, cs, config, isCancelled),
          const SizedBox(height: 24),

          // ── Usage Overview ──
          _buildUsageCard(context, cs, config),
          const SizedBox(height: 24),

          // ── Plan Actions ──
          _buildActionsCard(context, cs, isFree, isCancelled),

          // ── Cancel Section ──
          if (!isFree) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            _buildCancelSection(context, cs, config, isCancelled),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(
    BuildContext context,
    ColorScheme cs,
    PlanConfig config,
    bool isCancelled,
  ) {
    final statusColor = isCancelled ? cs.error : cs.primary;
    final statusLabel = isCancelled ? 'Cancelling' : 'Active';

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.workspace_premium, color: cs.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${config.name} Plan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentPlan == 'free'
                        ? 'Free forever'
                        : _expiresAt != null
                        ? isCancelled
                              ? 'Active until ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                              : 'Renews ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                        : 'Active',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                  ),
                  if (_userEmail != null) ...[  
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _userEmail!,
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (_userPhone != null) ...[  
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _userPhone!,
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard(
    BuildContext context,
    ColorScheme cs,
    PlanConfig config,
  ) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _usageRow(
              cs,
              'Bills this month',
              _limits.billsThisMonth,
              config.billsLimitFirestore,
            ),
            const SizedBox(height: 12),
            _usageRow(
              cs,
              'Products',
              _limits.productsCount,
              config.productsLimitFirestore,
            ),
            const SizedBox(height: 12),
            _usageRow(
              cs,
              'Customers',
              _limits.customersCount,
              config.customersLimitFirestore,
            ),
            const SizedBox(height: 12),
            _usageRow(
              cs,
              'Staff',
              _limits.staffCount,
              config.staffLimitFirestore,
            ),
            const SizedBox(height: 12),
            _usageRow(
              cs,
              'Tables',
              _limits.tablesCount,
              config.tablesLimitFirestore,
            ),
          ],
        ),
      ),
    );
  }

  Widget _usageRow(ColorScheme cs, String label, int used, int limit) {
    final isUnlimited = limit >= 999999;
    final fraction = isUnlimited ? 0.0 : (limit > 0 ? used / limit : 0.0);
    final limitLabel = isUnlimited ? '∞' : '$limit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            Text(
              '$used / $limitLabel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isUnlimited ? 0.05 : fraction.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              fraction > 0.9 ? cs.error : cs.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard(
    BuildContext context,
    ColorScheme cs,
    bool isFree,
    bool isCancelled,
  ) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => setState(() {
                  _showPlans = true;
                }),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  textStyle: const TextStyle(fontSize: 16),
                ),
                icon: const Icon(Icons.swap_horiz, size: 20),
                label: Text(isFree ? 'Upgrade Plan' : 'Change Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelSection(
    BuildContext context,
    ColorScheme cs,
    PlanConfig config,
    bool isCancelled,
  ) {
    if (isCancelled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your plan will remain active until expiry, then you\'ll move to Free.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _handleResume,
              style: OutlinedButton.styleFrom(foregroundColor: cs.primary),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Resume Plan'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => _showCancelSheet(config),
          style: TextButton.styleFrom(foregroundColor: cs.error),
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('Cancel Subscription'),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'Cancelling will keep your plan active until expiry. '
            'After that, you\'ll move to the Free plan.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Future<void> _showCancelSheet(PlanConfig config) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) =>
          CancelSubscriptionSheet(currentPlan: config, expiresAt: _expiresAt),
    );

    if (confirmed == true) {
      final service = SubscriptionService();
      final success = await service.cancelSubscription();
      if (mounted) {
        if (success) {
          setState(() => _status = 'cancelled');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Subscription cancelled. Plan remains active until expiry.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel. Please try again.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleResume() async {
    final service = SubscriptionService();
    final success = await service.resumeSubscription();
    if (mounted) {
      if (success) {
        setState(() => _status = 'active');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription resumed!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resume. Please try again.')),
        );
      }
    }
  }

  // ── Plans Sub-View (inline, with breadcrumb) ──

  Widget _buildPlansView(BuildContext context, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() => _showPlans = false);
                  _resyncCounts();
                },
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  'Manage Subscription',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right, size: 18, color: cs.outline),
              ),
              Text(
                'Subscription Plans',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Choose a Plan',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the plan that best fits your business needs.',
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // Plan Cards
          ...PlanConfig.allPlans.map((plan) {
            final isCurrent = plan.key == _currentPlan;
            final color = _planColor(plan.key);
            final price = SubscriptionPricing.getPrice(plan.key, 'monthly');

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: isCurrent ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isCurrent
                      ? BorderSide(color: color, width: 2)
                      : BorderSide.none,
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
                            plan.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Current',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price > 0 ? '₹${price.toInt()}/month' : '₹0 forever',
                        style: TextStyle(
                          fontSize: 16,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...plan.featureDescriptions.map(
                        (f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: color,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  f,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isCurrent && plan.key != 'free') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: _isDowngrade(plan.key)
                              ? OutlinedButton(
                                  onPressed: () =>
                                      _handleDowngrade(plan.key, plan.name),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: color,
                                    side: BorderSide(color: color),
                                  ),
                                  child: Text('Downgrade to ${plan.name}'),
                                )
                              : FilledButton(
                                  onPressed: _isUpgrading
                                      ? null
                                      : () => _handleUpgradeFromPanel(plan.key),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: color,
                                  ),
                                  child: _isUpgrading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text('Upgrade to ${plan.name}'),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _handleUpgradeFromPanel(String planKey) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upgrade.')),
      );
      return;
    }

    // Check phone verification before allowing payment
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final phoneVerified = (doc.data()?['phoneVerified'] as bool?) ?? false;
    if (!phoneVerified) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.phone_android, size: 40, color: Colors.orange),
            title: const Text('Phone Verification Required'),
            content: const Text(
              'Please verify your phone number before upgrading.\n\n'
              'Go to Verification Status section and verify your phone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // On web, Windows, and Android: open pricing page in Chrome with auto sign-in.
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    if (kIsWeb || isWindows || defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      setState(() => _isUpgrading = true);
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? _userEmail ?? '';
      // Use non-empty phone: Firebase Auth first, then stored _userPhone
      final rawPhone = (user?.phoneNumber?.trim().isNotEmpty == true
          ? user!.phoneNumber!
          : (_userPhone?.trim().isNotEmpty == true ? _userPhone! : ''));
      final phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

      // Get a short-lived custom token so the pricing page auto-signs in
      // without showing the login modal.
      String? customToken;
      try {
        final result = await CloudFunctionHelper.call('createPaymentToken');
        customToken = result['token'] as String?;
      } catch (_) {
        // Fall back gracefully — user will see sign-in on the page
      }

      final queryParams = <String, String>{'plan': planKey};
      if (customToken != null) queryParams['token'] = customToken;
      if (email.isNotEmpty) queryParams['email'] = email;
      if (phone.isNotEmpty) queryParams['phone'] = phone;
      final name = user?.displayName ?? user?.email?.split('@').first ?? '';
      if (name.isNotEmpty) queryParams['name'] = name;
      final url = Uri(
        scheme: 'https',
        host: 'hotels.tulasierp.com',
        path: '/src/pages/pricing.html',
        queryParameters: queryParams,
      );
      await launchUrl(url, mode: LaunchMode.externalApplication);
      // Give a moment then reset — the stream will pick up changes
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isUpgrading = false);
      return;
    }

    // On mobile, use the native Razorpay Flutter SDK
    setState(() => _isUpgrading = true);
    const cycle = 'monthly';

    final service = SubscriptionService();
    final result = await service.upgradePlan(
      plan: planKey,
      cycle: cycle,
      customerName:
          user.displayName ?? user.email?.split('@').first ?? 'User',
      customerEmail: user.email,
      customerPhone: user.phoneNumber,
    );

    if (!mounted) return;
    setState(() => _isUpgrading = false);

    if (result.success) {
      setState(() {
        _currentPlan = planKey;
        _showPlans = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upgraded to ${result.plan ?? planKey}! Enjoy your new features.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Payment failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isDowngrade(String targetPlanKey) {
    const planOrder = ['free', 'starter', 'pro', 'business'];
    final currentIndex = planOrder.indexOf(_currentPlan);
    final targetIndex = planOrder.indexOf(targetPlanKey);
    return targetIndex < currentIndex;
  }

  Future<void> _handleDowngrade(String planKey, String planName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Downgrade to $planName?'),
        content: Text(
          'Your plan will be changed to $planName. '
          'Some features and limits will be reduced. '
          'This change takes effect immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Downgrade'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = SubscriptionService();
      final success = await service.changePlan(planKey);
      if (mounted) {
        if (success) {
          setState(() {
            _currentPlan = planKey;
            _showPlans = false;
          });
          unawaited(_loadData());

          // Check if user needs to select active items
          await _promptActiveItemSelection(planKey);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downgraded to $planName successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to downgrade. Please try again.'),
            ),
          );
        }
      }
    }
  }

  /// Show item selection modal if user has more items than the new plan allows.
  Future<void> _promptActiveItemSelection(String planKey) async {
    final config = PlanConfig.fromKey(planKey);
    final storeId =
        ActiveStoreManager.storeId ?? FirebaseAuth.instance.currentUser?.uid;
    if (storeId == null) return;

    final db = FirebaseFirestore.instance;
    final base = 'users/$storeId';

    // Check products
    if (config.maxProducts != null) {
      final productsSnap = await db.collection('$base/products').get();
      if (productsSnap.docs.length > config.maxProducts!) {
        if (!mounted) return;
        final selectedIds = await Navigator.push<List<String>>(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveItemSelectionModal<QueryDocumentSnapshot>(
              title: 'Select Active Products',
              subtitle:
                  'Your new plan allows ${config.maxProducts} products.\n'
                  'Choose which ones to keep active for billing.',
              maxSelection: config.maxProducts!,
              items: productsSnap.docs,
              getName: (doc) => ((doc.data() as Map)['name'] as String?) ?? 'Unnamed',
              getId: (doc) => doc.id,
              getSubtitle: (doc) {
                final data = doc.data() as Map;
                final price = data['price'] ?? 0;
                return '₹$price';
              },
            ),
          ),
        );
        if (selectedIds != null) {
          await ActiveItemsService.setActiveProducts(selectedIds);
        }
      }
    }

    // Check tables
    if (config.maxTables != null) {
      final tablesSnap = await db.collection('$base/tables').get();
      if (tablesSnap.docs.length > config.maxTables!) {
        if (!mounted) return;
        final selectedIds = await Navigator.push<List<String>>(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveItemSelectionModal<QueryDocumentSnapshot>(
              title: 'Select Active Tables',
              subtitle:
                  'Your new plan allows ${config.maxTables} tables.\n'
                  'Choose which ones to keep active.',
              maxSelection: config.maxTables!,
              items: tablesSnap.docs,
              getName: (doc) =>
                  ((doc.data() as Map)['name'] as String?) ?? 'Table ${doc.id}',
              getId: (doc) => doc.id,
            ),
          ),
        );
        if (selectedIds != null) {
          await ActiveItemsService.setActiveTables(selectedIds);
        }
      }
    }
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
