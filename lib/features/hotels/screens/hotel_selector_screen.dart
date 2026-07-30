/// Hotel selector screen â€” shown after login to pick or create a hotel
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/admin/providers/current_member_provider.dart';
import 'package:tulasihotels/features/admin/services/member_permission_guard.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/hotels/models/hotel_info.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';
import 'package:tulasihotels/features/hotels/services/hotel_service.dart';
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

  @override
  void initState() {
    super.initState();
    _ensureDefaultHotel();
  }

  Future<void> _ensureDefaultHotel() async {
    try {
      // Team members (staff) have shopName == '' in auth state.
      // Only run ensureDefaultHotel / recoverOwnedHotels for real owners —
      // otherwise a ghost users/{uid} doc would trigger auto-creation of a
      // fake "Owner" hotel entry for the staff member.
      final authUser = ref.read(authNotifierProvider).user;
      final isOwner = (authUser?.shopName ?? '').isNotEmpty;

      if (isOwner) {
        await HotelService.ensureDefaultHotel();
        await HotelService.recoverOwnedHotels();
      }
      // Always resolve pending invites and prune for everyone
      await HotelService.resolvePendingInvites();
      await HotelService.pruneInvalidHotels();
    } catch (e) {
      debugPrint('⚠️ ensureDefaultHotel error: $e');
    }
    if (mounted) setState(() => _initialized = true);
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

    final deleteHotelButton = isOwner
        ? (hotelsAsync.whenOrNull(
                data: (hotels) {
                  final ownedHotels = hotels.where((h) => h.isOwner).toList();
                  if (ownedHotels.length < 2) {
                    return const SizedBox.shrink();
                  }
                  return OutlinedButton.icon(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      'Delete Restaurant',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    onPressed: () => _showDeleteHotelDialog(context, ownedHotels),
                  );
                },
              ) ??
              const SizedBox.shrink())
        : const SizedBox.shrink();

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
                      if (isOwner) deleteHotelButton,
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

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: hotels.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final hotel = hotels[index];
                            return _HotelCard(
                              hotel: hotel,
                              onOpen: () => _openHotel(context, hotel),
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

  Future<void> _showDeleteHotelDialog(
      BuildContext context, List<HotelInfo> hotels) async {
    HotelInfo? selected = hotels.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Delete Restaurant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select the restaurant to permanently delete:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<HotelInfo>(
                initialValue: selected,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.hotel_outlined),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: hotels
                    .map(
                      (h) => DropdownMenuItem(
                        value: h,
                        child: Text(h.name),
                      ),
                    )
                    .toList(),
                onChanged: (h) => setDialogState(() => selected = h),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This cannot be undone. All data for this hotel will be permanently removed.',
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selected != null && context.mounted) {
      final hotelName = selected!.name;
      try {
        await HotelService.deleteHotel(selected!.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"$hotelName" deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showCreateHotelDialog(BuildContext context) async {
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
    nameController.dispose();
  }

  void _openHotel(BuildContext context, HotelInfo hotel) {
    // Set the current hotel and persist for page refresh
    ref.read(currentHotelIdProvider.notifier).state = hotel.id;
    ActiveStoreManager.setActiveStore(hotel.id);
    OfflineStorageService.prefs?.setString('last_hotel_id', hotel.id);

    // Pre-warm Firestore offline cache in the background so products,
    // customers, and menu items are available when the device goes offline.
    _prewarmOfflineCache(hotel.id);
    unawaited(_syncPlanLimits(hotel.id));

    // Determine starting route based on member permissions.
    // Read the member doc synchronously (may be null on first load — router
    // redirect will correct the route once the stream resolves).
    final member = ref.read(currentMemberProvider).valueOrNull;
    final home = MemberPermissionGuard.homeRoute(member);
    context.go(home);
  }

  /// Ensures Firestore limits (tablesLimit, staffLimit, etc.) match the
  /// current plan. Runs once per hotel open — fixes stale free-plan values
  /// that cause Cloud Functions to incorrectly delete newly created items.
  Future<void> _syncPlanLimits(String hotelId) async {
    try {
      final fs = FirebaseFirestore.instance;
      final doc = await fs.collection('users').doc(hotelId).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final sub = data['subscription'] as Map<String, dynamic>? ?? {};
      final limits = data['limits'] as Map<String, dynamic>? ?? {};
      final plan = (sub['plan'] as String?) ?? 'free';
      final tablesDefault = plan == 'business' ? 999999 : plan == 'pro' ? 50 : plan == 'starter' ? 15 : 5;
      final staffDefault  = plan == 'business' ? 999999 : plan == 'pro' ? 10 : plan == 'starter' ? 3  : 0;
      final productsDefault = plan == 'business' ? 999999 : plan == 'pro' ? 999999 : plan == 'starter' ? 200 : 50;
      final customersDefault = plan == 'business' ? 999999 : plan == 'pro' ? 999999 : plan == 'starter' ? 100 : 10;
      final updates = <String, dynamic>{};
      if ((limits['tablesLimit']  as int? ?? 0) < tablesDefault)   updates['limits.tablesLimit']   = tablesDefault;
      if ((limits['staffLimit']   as int? ?? 0) < staffDefault)    updates['limits.staffLimit']    = staffDefault;
      if ((limits['productsLimit'] as int? ?? 0) < productsDefault) updates['limits.productsLimit'] = productsDefault;
      if ((limits['customersLimit'] as int? ?? 0) < customersDefault) updates['limits.customersLimit'] = customersDefault;
      if (updates.isNotEmpty) {
        await fs.collection('users').doc(hotelId).update(updates);
        debugPrint('✅ Plan limits synced for $hotelId: $updates');
      }
    } catch (e) {
      debugPrint('⚠️ _syncPlanLimits error: $e');
    }
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

class _HotelCard extends StatelessWidget {
  final HotelInfo hotel;
  final VoidCallback onOpen;

  const _HotelCard({required this.hotel, required this.onOpen});

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _roleColor(hotel.role);
    final roleLabel = hotel.roleLabel;

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
                  Row(
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
                      const SizedBox(width: 8),
                      // Status badge
                      if (hotel.status != HotelStatus.active)
                        _Badge(
                          icon: Icons.warning_amber_rounded,
                          iconSize: 12,
                          iconColor: Colors.orange,
                          label: hotel.status.displayName.toLowerCase(),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Open button
            FilledButton.tonal(onPressed: onOpen, child: const Text('Open')),
          ],
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
