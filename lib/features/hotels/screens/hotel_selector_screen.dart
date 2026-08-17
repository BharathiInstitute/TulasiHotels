/// Hotel selector screen â€” shown after login to pick or create a hotel
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/providers/current_member_provider.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/hotels/models/hotel_info.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';
import 'package:tulasihotels/features/hotels/services/hotel_service.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';
import 'package:tulasihotels/features/subscription/providers/subscription_provider.dart';
import 'package:tulasihotels/core/services/subscription_navigation_service.dart';
import 'package:tulasihotels/core/services/active_store_manager.dart';
import 'package:tulasihotels/core/services/offline_storage_service.dart';

class HotelSelectorScreen extends ConsumerStatefulWidget {
  const HotelSelectorScreen({super.key});

  @override
  ConsumerState<HotelSelectorScreen> createState() =>
      _HotelSelectorScreenState();
}

class _HotelSelectorScreenState extends ConsumerState<HotelSelectorScreen> {
  bool _initialized = false;
  String? _openingHotelId;

  @override
  void initState() {
    super.initState();
    _ensureDefaultHotel();
  }

  Future<void> _ensureDefaultHotel() async {
    try {
      // Repair the user's hotel index before deciding whether they are an owner.
      // An empty index otherwise prevents recovery from ever running.
      await HotelService.ensureDefaultHotel();
      await HotelService.recoverOwnedHotels();

      final authUser = ref.read(authNotifierProvider).user;
      final isOwner = (authUser?.shopName ?? '').isNotEmpty;
      await HotelService.resolvePendingInvites();
      await HotelService.pruneInvalidHotels();

      // Auto-suspend extra stores that exceed the plan limit on every app open.
      if (isOwner) {
        final hotels = await HotelService.hotelsStream().first;
        await _enforcePlanLimits(hotels);
      }
    } catch (e) {
      debugPrint('⚠️ ensureDefaultHotel error: $e');
    }
    if (mounted) setState(() => _initialized = true);
  }

  static const _planRank = {'business': 4, 'pro': 3, 'starter': 2, 'free': 1};

  static String _effectivePlanKey(List<HotelInfo> owned) {
    if (owned.isEmpty) return 'free';
    return owned.map((h) => h.planKey).reduce(
      (a, b) => (_planRank[a] ?? 0) >= (_planRank[b] ?? 0) ? a : b,
    );
  }

  static int _planActiveLimit(String planKey) => planKey == 'business' ? 3 : 1;

  // Suspends owned stores beyond the plan limit, keeping the last-used one active.
  Future<void> _enforcePlanLimits(List<HotelInfo> hotels) async {
    final owned = hotels.where((h) => h.isOwner).toList();
    final planKey = _effectivePlanKey(owned);
    final limit = _planActiveLimit(planKey);
    final active = owned.where((h) => h.status == HotelStatus.active).toList();
    if (active.length <= limit) return;

    final lastId = OfflineStorageService.prefs?.getString('last_hotel_id');
    active.sort((a, b) {
      if (a.id == lastId) return -1;
      if (b.id == lastId) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    for (int i = limit; i < active.length; i++) {
      await HotelService.setHotelStatus(active[i].id, 'suspended');
      debugPrint('🔒 Auto-suspended "${active[i].name}" (plan=$planKey limit=$limit)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelsAsync = ref.watch(hotelsStreamProvider);
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    // Determine if the current user owns any hotel.
    // Default to false (not true) during loading so non-owners never see
    // a "My Restaurants" flicker before the data arrives.
    final isOwner =
        hotelsAsync.whenOrNull(
          data: (hotels) => hotels.any((h) => h.isOwner),
        ) ??
        false;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 860;

                  final profileBlock = Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          (() {
                            final s = user?.displayName ?? user?.email ?? '';
                            return s.isNotEmpty ? s[0].toUpperCase() : 'U';
                          })(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOwner
                                  ? 'My Restaurants'
                                  : 'Accessible Restaurants',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final actionsWrap = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isOwner)
                        FilledButton.icon(
                          icon: const Icon(Icons.hotel, size: 18),
                          label: const Text('Create Restaurant'),
                          onPressed: () => _showCreateHotelDialog(context),
                        ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                        ),
                        onPressed: () => _logout(context),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileBlock,
                        const SizedBox(height: 12),
                        actionsWrap,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: profileBlock),
                      const SizedBox(width: 12),
                      Flexible(child: actionsWrap),
                    ],
                  );
                },
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isOwner
                      ? 'Select a restaurant to manage or create a new one'
                      : 'Restaurants you have been given access to',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Hotels list
            Expanded(
              child: !_initialized
                  ? const Center(child: CircularProgressIndicator())
                  : hotelsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (hotels) {
                        if (hotels.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.hotel_outlined,
                                  size: 64,
                                  color: theme.disabledColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No restaurants yet',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Your First Restaurant'),
                                  onPressed: () =>
                                      _showCreateHotelDialog(context),
                                ),
                              ],
                            ),
                          );
                        }

                        final ownedHotels = hotels.where((h) => h.isOwner).toList();
                        final effectivePlanKey = _effectivePlanKey(ownedHotels);
                        final planLimit = _planActiveLimit(effectivePlanKey);

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: hotels.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final hotel = hotels[index];
                            return _HotelCard(
                              hotel: hotel,
                              allOwnedHotels: ownedHotels,
                              activeOwnedCount: ownedHotels
                                  .where((h) => h.status == HotelStatus.active)
                                  .length,
                              isOpening: _openingHotelId == hotel.id,
                              onOpen: _openingHotelId != null
                                  ? null
                                  : () => _openHotel(context, hotel),
                              onToggleStatus: hotel.isOwner
                                  ? () => _toggleHotelStatus(
                                      context,
                                      hotel,
                                      ownedHotels,
                                      planLimit,
                                    )
                                  : null,
                              onActivate: hotel.isOwner &&
                                      hotel.status != HotelStatus.active
                                  ? () => _activateHotel(context, hotel, ownedHotels, planLimit)
                                  : null,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activateHotel(
    BuildContext context,
    HotelInfo hotel,
    List<HotelInfo> ownedHotels,
    int limit,
  ) async {
    final activeOwned =
        ownedHotels.where((h) => h.status == HotelStatus.active).toList();

    if (activeOwned.length < limit) {
      await HotelService.setHotelStatus(hotel.id, 'active');
      return;
    }

    if (!context.mounted) return;
    final planKey = _effectivePlanKey(ownedHotels);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.swap_horiz, color: Colors.orange),
          SizedBox(width: 8),
          Text('Switch Active Store'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${planKey.toUpperCase()} plan allows only $limit active store(s).\n'
              'Choose a store to deactivate so "${hotel.name.isNotEmpty ? hotel.name : 'this store'}" can be activated:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...activeOwned.map((h) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.store_rounded, size: 20),
                  title: Text(h.name.isNotEmpty ? h.name : 'Unknown Shop'),
                  subtitle: const Text('Currently active — tap to swap'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await HotelService.setHotelStatus(h.id, 'suspended');
                    await HotelService.setHotelStatus(hotel.id, 'active');
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleHotelStatus(
    BuildContext context,
    HotelInfo hotel,
    List<HotelInfo> ownedHotels,
    int limit,
  ) async {
    try {
      if (hotel.status == HotelStatus.active) {
        await HotelService.setHotelStatus(hotel.id, 'suspended');
        return;
      }
      await _activateHotel(context, hotel, ownedHotels, limit);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _showCreateHotelDialog(BuildContext context) async {
    // Check plan cap before showing the name input dialog
    final plan = ref.read(planConfigProvider);
    final hotels = ref.read(hotelsStreamProvider).valueOrNull ?? [];
    final ownedCount = hotels.where((h) => h.isOwner).length;
    final maxRestaurants = plan.key == 'business' ? 3 : 1;

    if (ownedCount >= maxRestaurants) {
      if (context.mounted) {
        final message = plan.key == 'business'
            ? 'Business plan allows only 3 restaurants'
            : 'Free, Starter, and Pro plans allow only 1 restaurant. Upgrade to Business plan to add more.';
        await _showCreateHotelErrorDialog(context, Exception(message));
      }
      return;
    }

    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Restaurant'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Restaurant Name',
            hintText: 'e.g. Grand Palace',
            prefixIcon: Icon(Icons.restaurant_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final name = nameController.text.trim();
      if (name.isEmpty) return;
      try {
        await HotelService.createHotel(name: name);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hotel "$name" created')));
        }
      } catch (e) {
        if (context.mounted) {
          await _showCreateHotelErrorDialog(context, e);
        }
      }
    }
    nameController.dispose();
  }

  String _extractReadableError(Object error) {
    final raw = error.toString().trim();
    final bracketIndex = raw.lastIndexOf(']');
    if (bracketIndex != -1 && bracketIndex + 1 < raw.length) {
      return raw.substring(bracketIndex + 1).trim();
    }
    if (raw.startsWith('Exception:')) {
      return raw.replaceFirst('Exception:', '').trim();
    }
    return raw;
  }

  Future<void> _showCreateHotelErrorDialog(
    BuildContext context,
    Object error,
  ) async {
    final message = _extractReadableError(error);
    final lower = message.toLowerCase();
    final isRestaurantCapError =
        lower.contains('business plan allows only 3 restaurants') ||
        lower.contains('allow only 1 restaurant');
    final isBusinessCapError =
        lower.contains('business plan allows only 3 restaurants');
    final ctaLabel = isBusinessCapError
        ? 'View Plan Usage'
        : 'Upgrade Plan';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unable to Create Restaurant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.isEmpty ? 'Something went wrong. Please try again.' : message),
            if (isRestaurantCapError) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    SubscriptionNavigationService.navigateToSubscription(context);
                  },
                  icon: const Icon(Icons.upgrade),
                  label: Text(ctaLabel),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openHotel(BuildContext context, HotelInfo hotel) async {
    if (_openingHotelId != null) return;
    setState(() => _openingHotelId = hotel.id);

    try {
      // Set the current hotel and persist for page refresh
      ref.read(currentHotelIdProvider.notifier).state = hotel.id;
      ActiveStoreManager.setActiveStore(hotel.id);
      unawaited(OfflineStorageService.prefs?.setString('last_hotel_id', hotel.id) ??
          Future.value());

      // Pre-warm Firestore offline cache in the background so products,
      // customers, and menu items are available when the device goes offline.
      _prewarmOfflineCache(hotel.id);
      unawaited(_syncPlanLimits(hotel.id));

      // Non-owners must have their member doc loaded before navigating —
      // otherwise homeRoute falls back to /billing and the router bounces
      // straight back to this screen, making "Open" look frozen.
      StoreMember? member;
      if (!hotel.isOwner) {
        member = await _resolveMember();
        if (!mounted) return;
        if (member == null) {
          ref.read(currentHotelIdProvider.notifier).state = null;
          ActiveStoreManager.clear();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not load your access for this restaurant. Please try again.',
              ),
            ),
          );
          return;
        }
      }

      if (!context.mounted) return;
      final home = PermissionCenter.homeRoute(
        isOwner: hotel.isOwner,
        member: member,
      );
      context.go(home);
    } finally {
      if (mounted) setState(() => _openingHotelId = null);
    }
  }

  /// Waits for the member doc of the newly selected store to arrive.
  Future<StoreMember?> _resolveMember() async {
    try {
      return await ref
          .read(currentMemberProvider.future)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('⚠️ _resolveMember failed: $e');
      return null;
    }
  }

  /// Ensures Firestore limits (tablesLimit, staffLimit, etc.) match the
  /// current plan. Runs once per hotel open — fixes stale free-plan values
  /// that cause Cloud Functions to incorrectly delete newly created items.
  Future<void> _syncPlanLimits(String hotelId) async {
    await HotelService.syncPlanLimits(hotelId);
  }

  /// Triggers background Firestore reads so collections are cached locally.
  /// Runs fire-and-forget — never blocks navigation.
  void _prewarmOfflineCache(String hotelId) {
    final fs = FirebaseFirestore.instance;
    final base = 'users/$hotelId';
    // All collections needed across every panel
    unawaited(fs.collection('$base/products').limit(500).get());
    unawaited(fs.collection('$base/customers').limit(500).get());
    unawaited(fs.collection('$base/bills').orderBy('createdAt', descending: true).limit(200).get());
    unawaited(fs.collection('$base/expenses').limit(100).get());
    unawaited(fs.collection('$base/tables').get());
    unawaited(fs.collection('$base/members').get());
    unawaited(fs.collection('$base/staff').get());
    unawaited(fs.doc('$base/counters/billing').get());
    unawaited(fs.doc(base).get()); // user/shop doc (limits, subscription)
    debugPrint('📦 Offline cache pre-warm started for hotel $hotelId');
  }

  Future<void> _logout(BuildContext context) async {
    ref.read(currentHotelIdProvider.notifier).state = null;
    ActiveStoreManager.clear();
    await OfflineStorageService.prefs?.remove('last_hotel_id');
    await ref.read(authNotifierProvider.notifier).signOut();
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Hotel card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HotelCard extends ConsumerWidget {
  final HotelInfo hotel;
  final List<HotelInfo> allOwnedHotels;
  final int activeOwnedCount;
  final bool isOpening;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onActivate;

  const _HotelCard({
    required this.hotel,
    required this.allOwnedHotels,
    required this.activeOwnedCount,
    required this.onOpen,
    this.isOpening = false,
    this.onToggleStatus,
    this.onActivate,
  });

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.amber.shade700;
      case 'manager':
        return Colors.blue;
      case 'accountant':
        return Colors.teal;
      case 'cashier':
        return Colors.green;
      case 'staff':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final roleColor = _roleColor(hotel.role);
    final roleLabel = hotel.roleLabel;
    final planAsync = ref.watch(hotelSubscriptionPlanProvider(hotel.id));
    final livePlanLabel = planAsync.when(
      data: (planKey) => PlanConfig.fromKey(planKey).name,
      loading: () => PlanConfig.fromKey(hotel.planKey).name,
      error: (_, _) => PlanConfig.fromKey(hotel.planKey).name,
    );
    final ownerPlanLabel = ref.watch(planConfigProvider).name;
    final planLabel =
        livePlanLabel == 'Free' && ownerPlanLabel != 'Free'
            ? ownerPlanLabel
            : livePlanLabel;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hotel.isOwner
              ? Colors.amber.shade700.withValues(alpha: 0.4)
              : theme.dividerColor,
          width: hotel.isOwner ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Hotel icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hotel.isOwner
                    ? Icons.store_rounded
                    : Icons.meeting_room_outlined,
                color: roleColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Hotel name + role badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      // Role badge — prominent
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hotel.isOwner
                                  ? Icons.shield_rounded
                                  : Icons.badge_outlined,
                              size: 12,
                              color: roleColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Badge(
                        icon: Icons.workspace_premium_rounded,
                        iconSize: 12,
                        iconColor: theme.colorScheme.primary,
                        label: 'Plan: $planLabel',
                      ),
                      // Active / Inactive chip — owner can tap to toggle status.
                      if (hotel.isOwner)
                        _StatusChip(
                          active: hotel.status == HotelStatus.active,
                          onTap: onToggleStatus,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            if (hotel.status == HotelStatus.active)
              FilledButton.tonal(
                onPressed: isOpening ? null : onOpen,
                child: isOpening
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Open'),
              )
            else if (hotel.isOwner && onActivate != null)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade400),
                ),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Set Active'),
                onPressed: onActivate,
              )
            else
              const FilledButton.tonal(
                onPressed: null,
                child: Text('Disabled'),
              ),
          ],
        ),
      ),
    );
  }
}

// Matches the Active/Locked chip style used in the super admin panel.
class _StatusChip extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;

  const _StatusChip({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.red.shade500;
    return Tooltip(
      message: onTap == null
          ? (active ? 'Active' : 'Inactive')
          : (active ? 'Click to deactivate' : 'Click to activate'),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: active
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.check_circle_outline : Icons.remove_circle_outline,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                active ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final String label;

  const _Badge({
    required this.icon,
    required this.iconSize,
    this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor ?? theme.hintColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
