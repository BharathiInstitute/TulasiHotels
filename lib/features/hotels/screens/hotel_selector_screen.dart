/// Hotel selector screen — shown after login to pick or create a hotel
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/hotels/models/hotel_info.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';
import 'package:tulasihotels/features/hotels/services/hotel_service.dart';
import 'package:tulasihotels/router/app_router.dart';

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
      await HotelService.ensureDefaultHotel();
      await HotelService.resolvePendingInvites();
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
                      (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
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
                          'My Hotels',
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
                  // Create Hotel button
                  FilledButton.icon(
                    icon: const Icon(Icons.hotel, size: 18),
                    label: const Text('Create Hotel'),
                    onPressed: () => _showCreateHotelDialog(context),
                  ),
                  const SizedBox(width: 8),
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
                  'Select a hotel to manage or create a new one',
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hotel "$name" created')),
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
    nameController.dispose();
  }

  void _openHotel(BuildContext context, HotelInfo hotel) {
    // Set the current hotel and navigate to billing
    ref.read(currentHotelIdProvider.notifier).state = hotel.id;
    context.go(AppRoutes.billing);
  }

  Future<void> _logout(BuildContext context) async {
    ref.read(currentHotelIdProvider.notifier).state = null;
    await ref.read(authNotifierProvider.notifier).signOut();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hotel card
// ─────────────────────────────────────────────────────────────────────────────

class _HotelCard extends StatelessWidget {
  final HotelInfo hotel;
  final VoidCallback onOpen;

  const _HotelCard({required this.hotel, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Hotel icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.store_rounded,
                color: theme.colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Hotel name + badges
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
                    spacing: 6,
                    children: [
                      _Badge(
                        icon: Icons.circle,
                        iconSize: 8,
                        iconColor: hotel.isOwner
                            ? Colors.green
                            : Colors.blue,
                        label: hotel.role,
                      ),
                      _Badge(
                        icon: Icons.tag,
                        iconSize: 12,
                        label: hotel.slug,
                      ),
                      _Badge(
                        icon: Icons.check_circle_outline,
                        iconSize: 12,
                        iconColor: hotel.status == HotelStatus.active
                            ? Colors.green
                            : Colors.orange,
                        label: hotel.status.displayName.toLowerCase(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Open button
            FilledButton.tonal(
              onPressed: onOpen,
              child: const Text('Open'),
            ),
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
