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
import 'package:tulasihotels/features/admin/providers/current_member_provider.dart';
import 'package:tulasihotels/features/admin/services/member_permission_guard.dart';
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

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Bottom nav shows only these 4 popular indices + a "More" entry
  static const _bottomNavIndices = [
    0,
    2,
    5,
  ]; // Walk-in, Menu, Tables

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/billing')) return 0;
    if (location.startsWith('/khata')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/dashboard')) return 3;
    if (location.startsWith('/bills')) return 4;
    if (location.startsWith('/tables')) return 5;
    if (location.startsWith('/kitchen')) return 6;
    if (location.startsWith('/staff')) return 7;
    if (location.startsWith('/attendance') ||
        location.startsWith('/my-attendance')) {
      return 8;
    }
    if (location.startsWith('/settings')) return 10;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index, List<String> routes) {
    if (index >= 0 && index < routes.length) {
      context.go(routes[index]);
    }
  }

  /// Get routes list — staff sees /my-attendance at index 8, owner sees /attendance
  static List<String> _getRoutes(bool isStaff) {
    return [
      AppRoutes.billing, // 0
      AppRoutes.khata, // 1
      AppRoutes.products, // 2
      AppRoutes.dashboard, // 3
      AppRoutes.bills, // 4
      AppRoutes.tables, // 5
      AppRoutes.kitchen, // 6
      AppRoutes.staff, // 7
      isStaff ? AppRoutes.myAttendance : AppRoutes.attendance, // 8
    ];
  }

  /// Get visible nav indices based on logged-in staff role or member permissions
  List<int> _getVisibleIndices() {
    final staff = ref.watch(loggedInStaffProvider);
    if (staff != null) {
      return StaffPermissions.visibleNavIndices(staff);
    }
    // No staff logged in → check member permissions
    final member = ref.watch(currentMemberProvider).valueOrNull;
    return MemberPermissionGuard.visibleNavIndices(member);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final visibleIndices = _getVisibleIndices();
    final loggedInStaff = ref.watch(loggedInStaffProvider);
    final routes = _getRoutes(loggedInStaff != null);

    // Use WebShell for Desktop/Web view (desktop + desktopLarge)
    if (deviceType == DeviceType.desktop ||
        deviceType == DeviceType.desktopLarge) {
      return WebShell(
        selectedIndex: selectedIndex,
        visibleIndices: visibleIndices,
        onItemTapped: (index) => _onItemTapped(context, index, routes),
        child: widget.child,
      );
    }

    final user = ref.watch(currentUserProvider);

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      drawer: deviceType == DeviceType.mobile
          ? _buildDrawer(
              context,
              selectedIndex,
              visibleIndices,
              routes,
              user,
              loggedInStaff,
            )
          : null,
      appBar: deviceType == DeviceType.mobile
          ? AppBar(
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${loggedInStaff.role.emoji} ${loggedInStaff.role.displayName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                  onPressed: () => _showProfileSheet(context),
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
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      // Bottom navigation for mobile
      bottomNavigationBar: deviceType == DeviceType.mobile
          ? _buildBottomNavigation(
              context,
              selectedIndex,
              visibleIndices,
              routes,
            )
          : null,
    );
  }

  /// Build the navigation drawer with all panels
  Widget _buildDrawer(
    BuildContext context,
    int selectedIndex,
    List<int> visibleIndices,
    List<String> routes,
    UserModel? user,
    dynamic loggedInStaff,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final allNavItems =
        <int, ({IconData icon, IconData activeIcon, String label})>{
          0: (
            icon: Icons.point_of_sale_outlined,
            activeIcon: Icons.point_of_sale,
            label: 'Walk-in',
          ),
          1: (
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: l10n.khata,
          ),
          2: (
            icon: Icons.restaurant_menu_outlined,
            activeIcon: Icons.restaurant_menu,
            label: l10n.products,
          ),
          3: (
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: l10n.dashboard,
          ),
          4: (
            icon: Icons.receipt_outlined,
            activeIcon: Icons.receipt,
            label: 'Bills',
          ),
          5: (
            icon: Icons.table_restaurant_outlined,
            activeIcon: Icons.table_restaurant,
            label: 'Tables',
          ),
          6: (
            icon: Icons.kitchen_outlined,
            activeIcon: Icons.kitchen,
            label: 'Kitchen',
          ),
          7: (
            icon: Icons.badge_outlined,
            activeIcon: Icons.badge,
            label: 'Staff',
          ),
          8: (
            icon: Icons.access_time_outlined,
            activeIcon: Icons.access_time_filled,
            label: 'Attendance',
          ),
        };

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShopLogoWidget(
                        logoPath: user?.shopLogoPath,
                        size: 40,
                        borderRadius: 10,
                        iconSize: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.shopName ?? AppConstants.defaultShopName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (loggedInStaff != null)
                              Text(
                                '${loggedInStaff.role.emoji} ${loggedInStaff.name}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Nav items + More Features sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  // Core nav items (Walk-in, Khata, Menu, etc.)
                  for (final idx in visibleIndices)
                    if (allNavItems.containsKey(idx))
                      _DrawerNavItem(
                        icon: selectedIndex == idx
                            ? allNavItems[idx]!.activeIcon
                            : allNavItems[idx]!.icon,
                        label: allNavItems[idx]!.label,
                        isSelected: selectedIndex == idx,
                        onTap: () {
                          Navigator.pop(context);
                          _onItemTapped(context, idx, routes);
                        },
                      ),

                  // More Features sections (matching web shell)
                  ..._buildMoreFeaturesSections(context, ref),

                  const Divider(height: 1),
                  // Settings
                  _DrawerNavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isSelected: selectedIndex == 10,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings/general');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build "More Features" sections for the drawer (Inventory, Hospitality, Reports, Compliance)
  List<Widget> _buildMoreFeaturesSections(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(loggedInStaffProvider);
    final member = ref.watch(currentMemberProvider).valueOrNull;
    final currentPath = GoRouterState.of(context).matchedLocation;

    Widget? routeItem(IconData icon, String label, String route) {
      if (!StaffPermissions.canViewRoute(staff, route)) return null;
      if (staff == null && !MemberPermissionGuard.canViewRoute(member, route)) {
        return null;
      }
      final isActive = currentPath.startsWith(route);
      return _DrawerNavItem(
        icon: icon,
        label: label,
        isSelected: isActive,
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
      );
    }

    final menuItems = [
      routeItem(Icons.star, 'Daily Specials', AppRoutes.dailySpecials),
      routeItem(Icons.lunch_dining, 'Combos', AppRoutes.combos),
    ].whereType<Widget>().toList();

    final inventoryItems = [
      routeItem(Icons.egg, 'Ingredients', AppRoutes.ingredients),
      routeItem(Icons.local_shipping, 'Vendors', AppRoutes.vendors),
      routeItem(Icons.delete_sweep, 'Wastage', AppRoutes.wastage),
    ].whereType<Widget>().toList();

    final hospitalityItems = [
      routeItem(Icons.event_seat, 'Reservations', AppRoutes.reservations),
      routeItem(Icons.local_offer, 'Coupons', AppRoutes.coupons),
      routeItem(Icons.celebration, 'Events', AppRoutes.events),
      routeItem(Icons.feedback, 'Feedback', AppRoutes.feedbackDashboard),
    ].whereType<Widget>().toList();

    final reportsItems = [
      routeItem(Icons.bar_chart, 'Advanced Reports', AppRoutes.advancedReports),
      routeItem(Icons.description, 'GST Export', AppRoutes.gstExport),
    ].whereType<Widget>().toList();

    final complianceItems = [
      routeItem(Icons.build, 'Equipment', AppRoutes.equipment),
      routeItem(Icons.badge, 'Licenses', AppRoutes.licenses),
      routeItem(Icons.report_problem, 'Complaints', AppRoutes.complaints),
    ].whereType<Widget>().toList();

    final managementItems = [
      routeItem(Icons.group, 'Users', AppRoutes.members),
      routeItem(Icons.security, 'Permissions', AppRoutes.permissionsOverview),
    ].whereType<Widget>().toList();

    final sections = <Widget>[];

    if (inventoryItems.isNotEmpty ||
        hospitalityItems.isNotEmpty ||
        reportsItems.isNotEmpty ||
        complianceItems.isNotEmpty ||
        managementItems.isNotEmpty ||
        menuItems.isNotEmpty) {
      sections.add(const Divider(height: 16));
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            'More Features',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    if (menuItems.isNotEmpty) {
      sections.add(
        _DrawerSection(title: 'Menu', children: menuItems),
      );
    }
    if (inventoryItems.isNotEmpty) {
      sections.add(
        _DrawerSection(title: 'Inventory', children: inventoryItems),
      );
    }
    if (hospitalityItems.isNotEmpty) {
      sections.add(
        _DrawerSection(title: 'Hospitality', children: hospitalityItems),
      );
    }
    if (reportsItems.isNotEmpty) {
      sections.add(_DrawerSection(title: 'Reports', children: reportsItems));
    }
    if (complianceItems.isNotEmpty) {
      sections.add(
        _DrawerSection(title: 'Compliance', children: complianceItems),
      );
    }
    if (managementItems.isNotEmpty) {
      sections.add(
        _DrawerSection(title: 'Admin', children: managementItems),
      );
    }

    return sections;
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

  void _showProfileSheet(BuildContext context) {
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
        icon: Icon(Icons.kitchen_outlined),
        activeIcon: Icon(Icons.kitchen),
        label: 'Kitchen',
      ),
      7: const BottomNavigationBarItem(
        icon: Icon(Icons.badge_outlined),
        activeIcon: Icon(Icons.badge),
        label: 'Staff',
      ),
      8: const BottomNavigationBarItem(
        icon: Icon(Icons.access_time_outlined),
        activeIcon: Icon(Icons.access_time_filled),
        label: 'Attendance',
      ),
    };

    // Show only the top 4 popular panels that the user is allowed to see + "More"
    final popularIndices = _bottomNavIndices
        .where((i) => visibleIndices.contains(i) && allItems.containsKey(i))
        .toList();

    final items = popularIndices.map((i) => allItems[i]!).toList();
    // Add "More" as the 5th item
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.more_horiz_outlined),
        activeIcon: Icon(Icons.more_horiz),
        label: 'More',
      ),
    );

    // Check if the current page is one of the popular ones
    final filteredSelectedIndex = popularIndices.indexOf(selectedIndex);
    // If current page is not in bottom nav, don't highlight any (show More as active)
    final clampedIndex = filteredSelectedIndex >= 0
        ? filteredSelectedIndex
        : items.length - 1; // "More" index

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
          onTap: (tappedIndex) {
            if (tappedIndex == items.length - 1) {
              // "More" tapped — open drawer
              _scaffoldKey.currentState?.openDrawer();
            } else if (tappedIndex < popularIndices.length) {
              _onItemTapped(context, popularIndices[tappedIndex], routes);
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
      6: (icon: Icons.kitchen, label: 'Kitchen'),
      7: (icon: Icons.badge, label: 'Staff'),
      8: (icon: Icons.access_time_filled, label: 'Attendance'),
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

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppColors.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: OpacityColors.primary10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DrawerSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
        ),
        ...children,
      ],
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
