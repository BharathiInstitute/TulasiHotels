/// Hotel selector screen â€” shown after login to pick or create a hotel
library;

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

    // Determine if the current user owns any hotel
    final isOwner =
        hotelsAsync.whenOrNull(
          data: (hotels) => hotels.any((h) => h.isOwner),
        ) ??
        true; // default true while loading to avoid flicker

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (user?.displayName ?? user?.email ?? 'U')[0]
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOwner ? 'My Hotels' : 'Accessible Hotels',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Create Hotel button — owners only
                  if (isOwner) ...[
                    FilledButton.icon(
                      icon: const Icon(Icons.hotel, size: 18),
                      label: const Text('Create Hotel'),
                      onPressed: () => _showCreateHotelDialog(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Logout button
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
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isOwner
                      ? 'Select a hotel to manage or create a new one'
                      : 'Hotels you have been given access to',
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
                                  'No hotels yet',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Your First Hotel'),
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

  Future<void> _showCreateHotelDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Hotel'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Hotel Name',
            hintText: 'e.g. Grand Palace',
            prefixIcon: Icon(Icons.hotel_outlined),
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

    // Determine starting route based on member permissions.
    // Read the member doc synchronously (may be null on first load — router
    // redirect will correct the route once the stream resolves).
    final member = ref.read(currentMemberProvider).valueOrNull;
    final home = MemberPermissionGuard.homeRoute(member);
    context.go(home);
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
