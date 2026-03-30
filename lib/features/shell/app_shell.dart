/// Main app shell with responsive navigation
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/core/constants/app_constants.dart';
import 'package:tulasihotels/core/design/design_system.dart';
import 'package:tulasihotels/core/utils/color_utils.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/services/staff_permissions.dart';
import 'package:tulasihotels/features/staff/widgets/staff_clock_widget.dart';
import 'package:tulasihotels/shared/widgets/logout_dialog.dart';
import 'package:tulasihotels/shared/widgets/offline_banner.dart';
import 'package:tulasihotels/features/auth/widgets/demo_mode_banner.dart';
import 'package:tulasihotels/features/notifications/widgets/notification_bell.dart';
import 'package:tulasihotels/shared/widgets/global_sync_indicator.dart';
import 'package:tulasihotels/features/shell/web_shell.dart';
import 'package:tulasihotels/l10n/app_localizations.dart';
import 'package:tulasihotels/models/user_model.dart';
import 'package:tulasihotels/router/app_router.dart';
import 'package:tulasihotels/shared/widgets/shop_logo_widget.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/billing')) return 0;
    if (location.startsWith('/khata')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/dashboard')) return 3;
    if (location.startsWith('/bills')) return 4;
    if (location.startsWith('/tables')) return 5;
    if (location.startsWith('/orders')) return 6;
    if (location.startsWith('/kitchen')) return 7;
    if (location.startsWith('/staff')) return 8;
    if (location.startsWith('/attendance') ||
        location.startsWith('/my-attendance')) {
      return 9;
    }
    if (location.startsWith('/settings')) return 10;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index, List<String> routes) {
    if (index >= 0 && index < routes.length) {
      context.go(routes[index]);
    }
  }

  /// Get routes list — staff sees /my-attendance at index 9, owner sees /attendance
  static List<String> _getRoutes(bool isStaff) {
    return [
      AppRoutes.billing,   // 0
      AppRoutes.khata,     // 1
      AppRoutes.products,  // 2
      AppRoutes.dashboard, // 3
      AppRoutes.bills,     // 4
      AppRoutes.tables,    // 5
      AppRoutes.orders,    // 6
      AppRoutes.kitchen,   // 7
      AppRoutes.staff,     // 8
      isStaff ? AppRoutes.myAttendance : AppRoutes.attendance, // 9
    ];
  }

  /// Get visible nav indices based on logged-in staff role
  List<int> _getVisibleIndices(WidgetRef ref) {
    final staff = ref.watch(loggedInStaffProvider);
    return StaffPermissions.visibleNavIndices(staff);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _getSelectedIndex(context);
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final visibleIndices = _getVisibleIndices(ref);
    final loggedInStaff = ref.watch(loggedInStaffProvider);
    final routes = _getRoutes(loggedInStaff != null);

    // Use WebShell for Desktop/Web view (desktop + desktopLarge)
    if (deviceType == DeviceType.desktop ||
        deviceType == DeviceType.desktopLarge) {
      return WebShell(
        selectedIndex: selectedIndex,
        visibleIndices: visibleIndices,
        onItemTapped: (index) => _onItemTapped(context, index, routes),
        child: child,
      );
    }

    final user = ref.watch(currentUserProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: deviceType == DeviceType.mobile
          ? AppBar(
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  ShopLogoWidget(
                    logoPath: user?.shopLogoPath,
                    size: 28,
                    borderRadius: 6,
                    iconSize: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: loggedInStaff != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                loggedInStaff.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${loggedInStaff.role.emoji} ${loggedInStaff.role.displayName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            user?.shopName ?? AppConstants.defaultShopName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ],
              ),
              actions: [
                if (loggedInStaff != null)
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20),
                    tooltip: 'Staff Logout',
                    onPressed: () {
                      ref.read(loggedInStaffProvider.notifier).state = null;
                      context.go(AppRoutes.billing);
                    },
                  ),
                const GlobalSyncIndicator(),
                const NotificationBell(),
                IconButton(
                  icon: _buildProfileAvatar(user?.profileImagePath, 16),
                  onPressed: () => _showProfileSheet(context, ref),
                ),
              ],
              elevation: 0.5,
              backgroundColor: Theme.of(context).cardColor,
              surfaceTintColor: Colors.transparent,
            )
          : null,
      body: Column(
        children: [
          // Demo mode banner
          const DemoModeBanner(),
          const OfflineBanner(),
          // Staff self-service clock-in/out widget
          if (loggedInStaff != null) const StaffClockWidget(),
          Expanded(
            child: Row(
              children: [
                // Side navigation for tablet (Desktop uses WebShell now)
                if (deviceType == DeviceType.tablet)
                  _buildSideNavigation(
                    context,
                    selectedIndex,
                    deviceType,
                    user,
                    visibleIndices,
                    routes,
                  ),

                // Main content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      // Bottom navigation for mobile
      bottomNavigationBar: deviceType == DeviceType.mobile
          ? _buildBottomNavigation(context, selectedIndex, visibleIndices, routes)
          : null,
    );
  }

  /// Build profile avatar that handles both URL and local file
  Widget _buildProfileAvatar(String? logoPath, double radius) {
    final hasImage = logoPath != null && logoPath.isNotEmpty;

    if (!hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(Icons.person, size: radius, color: AppColors.primary),
      );
    }

    if (logoPath.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(logoPath),
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        onBackgroundImageError: (e, _) {
          debugPrint('⚠️ Shell avatar image error: $e');
        },
      );
    }

    // Fallback to icon
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Icon(Icons.person, size: radius, color: AppColors.primary),
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // User info with edit button
              Stack(
                children: [
                  _buildProfileAvatar(user?.profileImagePath, 28),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/settings/account');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Shop name (prominent)
              if (user?.shopName != null && user!.shopName.isNotEmpty) ...[
                Text(
                  user.shopName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              // Owner name
              Text(
                user?.ownerName ?? 'User',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (user?.email != null) ...[
                const SizedBox(height: 2),
                Text(
                  user!.email!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1),

              // Settings
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/settings/general');
                },
              ),

              // Contact / Support
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact us at support@tulasihotels.app'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              // Logout
              ListTile(
                dense: true,
                leading: const Icon(Icons.logout, color: Colors.red, size: 22),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showLogoutDialog(context, ref);
                },
              ),

              const SizedBox(height: 16),
              Text(
                'Powered by ${AppConstants.appName}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    int selectedIndex,
    List<int> visibleIndices,
    List<String> routes,
  ) {
    final l10n = context.l10n;

    // All bottom nav items (indexed 0-9)
    final allItems = <int, BottomNavigationBarItem>{
      0: const BottomNavigationBarItem(
        icon: Icon(Icons.point_of_sale_outlined),
        activeIcon: Icon(Icons.point_of_sale),
        label: 'Walk-in',
      ),
      1: BottomNavigationBarItem(
        icon: const Icon(Icons.people_outline),
        activeIcon: const Icon(Icons.people),
        label: l10n.khata,
      ),
      2: BottomNavigationBarItem(
        icon: const Icon(Icons.restaurant_menu_outlined),
        activeIcon: const Icon(Icons.restaurant_menu),
        label: l10n.products,
      ),
      3: BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard_outlined),
        activeIcon: const Icon(Icons.dashboard),
        label: l10n.dashboard,
      ),
      4: const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_outlined),
        activeIcon: Icon(Icons.receipt),
        label: 'Bills',
      ),
      5: const BottomNavigationBarItem(
        icon: Icon(Icons.table_restaurant_outlined),
        activeIcon: Icon(Icons.table_restaurant),
        label: 'Tables',
      ),
      6: const BottomNavigationBarItem(
        icon: Icon(Icons.restaurant_menu_outlined),
        activeIcon: Icon(Icons.restaurant_menu),
        label: 'Orders',
      ),
      7: const BottomNavigationBarItem(
        icon: Icon(Icons.kitchen_outlined),
        activeIcon: Icon(Icons.kitchen),
        label: 'Kitchen',
      ),
      8: const BottomNavigationBarItem(
        icon: Icon(Icons.badge_outlined),
        activeIcon: Icon(Icons.badge),
        label: 'Staff',
      ),
      9: const BottomNavigationBarItem(
        icon: Icon(Icons.access_time_outlined),
        activeIcon: Icon(Icons.access_time_filled),
        label: 'Attendance',
      ),
    };

    // Filter to visible items only
    final filteredIndices = visibleIndices.where((i) => allItems.containsKey(i)).toList();
    final items = filteredIndices.map((i) => allItems[i]!).toList();

    // Map the logical selectedIndex to the filtered position
    final filteredSelectedIndex = filteredIndices.indexOf(selectedIndex);
    final clampedIndex = filteredSelectedIndex >= 0 ? filteredSelectedIndex : 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
            color: OpacityColors.black10,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: clampedIndex,
          onTap: (tappedFilteredIndex) {
            if (tappedFilteredIndex < filteredIndices.length) {
              _onItemTapped(context, filteredIndices[tappedFilteredIndex], routes);
            }
          },
          type: BottomNavigationBarType.fixed,
          items: items,
        ),
      ),
    );
  }

  Widget _buildSideNavigation(
    BuildContext context,
    int selectedIndex,
    DeviceType deviceType,
    UserModel? user,
    List<int> visibleIndices,
    List<String> routes,
  ) {
    final isExpanded = deviceType == DeviceType.desktop;
    final l10n = context.l10n;

    // All side nav items (indexed 0-9)
    final allNavItems = <int, ({IconData icon, String label})>{
      0: (icon: Icons.point_of_sale, label: 'Walk-in'),
      1: (icon: Icons.people, label: l10n.khata),
      2: (icon: Icons.restaurant_menu, label: l10n.products),
      3: (icon: Icons.dashboard, label: l10n.dashboard),
      4: (icon: Icons.receipt, label: 'Bills'),
      5: (icon: Icons.table_restaurant, label: 'Tables'),
      6: (icon: Icons.restaurant_menu, label: 'Orders'),
      7: (icon: Icons.kitchen, label: 'Kitchen'),
      8: (icon: Icons.badge, label: 'Staff'),
      9: (icon: Icons.access_time_filled, label: 'Attendance'),
    };

    return Container(
      width: AppSizes.sidebarWidth(context),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
            color: OpacityColors.black05,
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16 : 8,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                ShopLogoWidget(logoPath: user?.shopLogoPath),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      user?.shopName ?? l10n.appName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Navigation items (filtered by role)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final idx in visibleIndices)
                  if (allNavItems.containsKey(idx))
                    _NavItem(
                      icon: allNavItems[idx]!.icon,
                      label: allNavItems[idx]!.label,
                      isSelected: selectedIndex == idx,
                      isExpanded: isExpanded,
                      onTap: () => _onItemTapped(context, idx, routes),
                    ),
              ],
            ),
          ),

          // Sync indicator
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: GlobalSyncIndicator(),
          ),

          // Settings at bottom
          const Divider(height: 1),
          _NavItem(
            icon: Icons.settings,
            label: l10n.settings,
            isSelected: false,
            isExpanded: isExpanded,
            onTap: () => context.go('/settings/general'),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Powered by ${AppConstants.appName}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 8 : 4,
        vertical: 2,
      ),
      child: Material(
        color: isSelected ? OpacityColors.primary10 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 0),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
