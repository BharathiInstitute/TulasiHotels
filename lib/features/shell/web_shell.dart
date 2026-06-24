import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tulasihotels/core/constants/app_constants.dart';
import 'package:tulasihotels/features/notifications/providers/notification_provider.dart';
import 'package:tulasihotels/features/notifications/widgets/notification_bell.dart';
import 'package:tulasihotels/shared/widgets/global_sync_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/core/design/design_system.dart';
import 'package:tulasihotels/core/utils/website_url.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/auth/widgets/demo_mode_banner.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/services/staff_permissions.dart';
import 'package:tulasihotels/features/admin/providers/current_member_provider.dart';
import 'package:tulasihotels/features/admin/services/member_permission_guard.dart';
import 'package:tulasihotels/router/app_router.dart';
import 'package:tulasihotels/shared/widgets/shop_logo_widget.dart';
import 'package:tulasihotels/shared/widgets/web_safe_image.dart';
import 'package:tulasihotels/shared/widgets/offline_banner.dart';
import 'package:url_launcher/url_launcher.dart';

/// User-toggled sidebar collapse state. null = auto (follow screen width)
final sidebarCollapsedProvider = StateProvider<bool?>((ref) => null);

class WebShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final List<int> visibleIndices;
  final Function(int) onItemTapped;

  const WebShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.visibleIndices,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Current location for breadcrumbs/title
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Demo mode banner at the very top if active
          const DemoModeBanner(),
          const OfflineBanner(),

          Expanded(
            child: Row(
              children: [
                // Sidebar with edge collapse button
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _WebSidebar(
                      selectedIndex: selectedIndex,
                      visibleIndices: visibleIndices,
                      onItemTapped: onItemTapped,
                      currentPath: location,
                    ),
                    Positioned(
                      right: -12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _SidebarCollapseButton(),
                      ),
                    ),
                  ],
                ),

                // Main Content Area
                Expanded(
                  child: Column(
                    children: [
                      // Header (hide for screens that have their own header)
                      if (!location.startsWith(AppRoutes.billing) &&
                          !location.startsWith(AppRoutes.khata) &&
                          !location.startsWith(AppRoutes.products) &&
                          !location.startsWith(AppRoutes.bills) &&
                          !location.startsWith(AppRoutes.dashboard))
                        _WebHeader(currentPath: location),

                      // Content
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebSidebar extends ConsumerWidget {
  final int selectedIndex;
  final List<int> visibleIndices;
  final Function(int) onItemTapped;
  final String currentPath;

  const _WebSidebar({
    required this.selectedIndex,
    required this.visibleIndices,
    required this.onItemTapped,
    required this.currentPath,
  });

  static const Map<int, (IconData, String)> _navItems = {
    0: (Icons.point_of_sale_outlined, 'Walk-in'),
    1: (Icons.account_balance_wallet_outlined, 'Khata Ledger'),
    2: (Icons.restaurant_menu_outlined, 'Menu'),
    3: (Icons.dashboard_outlined, 'Dashboard'),
    4: (Icons.receipt_outlined, 'Bills'),
    5: (Icons.table_restaurant_outlined, 'Tables'),
    7: (Icons.kitchen_outlined, 'Kitchen'),
    8: (Icons.badge_outlined, 'Staff'),
    9: (Icons.access_time_outlined, 'Attendance'),
  };

  /// Build profile avatar that handles both URL and local file
  Widget _buildProfileAvatar(String? logoPath, double radius, bool isSelected) {
    final hasImage = logoPath != null && logoPath.isNotEmpty;

    if (!hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: isSelected ? AppColors.primary : Colors.grey,
        child: Icon(Icons.person, size: radius, color: Colors.white),
      );
    }

    if (logoPath.startsWith('http')) {
      if (kIsWeb) {
        return ClipOval(
          child: WebSafeImage(
            url: logoPath,
            width: radius * 2,
            height: radius * 2,
            errorWidget: CircleAvatar(
              radius: radius,
              backgroundColor: isSelected ? AppColors.primary : Colors.grey,
              child: Icon(Icons.person, size: radius, color: Colors.white),
            ),
          ),
        );
      }
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(logoPath),
        backgroundColor: isSelected ? AppColors.primary : Colors.grey,
        onBackgroundImageError: (e, _) {
          debugPrint('⚠️ Shell avatar image error: $e');
        },
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: isSelected ? AppColors.primary : Colors.grey,
      child: Icon(Icons.person, size: radius, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Identify if we are in settings (since it might be outside standard index)
    final isSettings = currentPath.startsWith(AppRoutes.settings);
    final userToggle = ref.watch(sidebarCollapsedProvider);
    final autoCollapsed = MediaQuery.of(context).size.width < 800;
    final isCollapsed = userToggle ?? autoCollapsed;
    final sidebarWidth = isCollapsed
        ? 72.0
        : (ResponsiveHelper.isDesktopLarge(context) ? 280.0 : 240.0);

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 24),
            alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
            child: isCollapsed
                ? ShopLogoWidget(logoPath: user?.shopLogoPath)
                : Row(
                    children: [
                      ShopLogoWidget(logoPath: user?.shopLogoPath),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          user?.shopName ?? AppConstants.defaultShopName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 8),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 16),
              children: [
                for (final idx in visibleIndices)
                  if (_navItems[idx] case final item?)
                    _SidebarItem(
                      icon: item.$1,
                      label: item.$2,
                      isSelected: selectedIndex == idx,
                      isCollapsed: isCollapsed,
                      onTap: () => onItemTapped(idx),
                    ),

                // More features — direct route links (permission-filtered)
                if (!isCollapsed) ...[
                  const Divider(height: 16),
                  Builder(
                    builder: (context) {
                      final staff = ref.watch(loggedInStaffProvider);
                      final member = ref.watch(currentMemberProvider).valueOrNull;
                      Widget? routeItem(
                        IconData icon,
                        String label,
                        String route,
                      ) {
                        if (!StaffPermissions.canViewRoute(staff, route)) {
                          return null;
                        }
                        if (staff == null && !MemberPermissionGuard.canViewRoute(member, route)) {
                          return null;
                        }
                        return _SidebarRouteItem(
                          icon: icon,
                          label: label,
                          route: route,
                          currentPath: currentPath,
                          isCollapsed: isCollapsed,
                        );
                      }

                      // Build sections, omit empty ones
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
                      return Column(
                        children: [
                          if (menuItems.isNotEmpty)
                            _SidebarSection(
                              title: 'Menu',
                              isCollapsed: isCollapsed,
                              children: menuItems,
                            ),
                          if (inventoryItems.isNotEmpty)
                            _SidebarSection(
                              title: 'Inventory',
                              isCollapsed: isCollapsed,
                              children: inventoryItems,
                            ),
                          if (hospitalityItems.isNotEmpty)
                            _SidebarSection(
                              title: 'Hospitality',
                              isCollapsed: isCollapsed,
                              children: hospitalityItems,
                            ),
                          if (reportsItems.isNotEmpty)
                            _SidebarSection(
                              title: 'Reports',
                              isCollapsed: isCollapsed,
                              children: reportsItems,
                            ),
                          if (complianceItems.isNotEmpty)
                            _SidebarSection(
                              title: 'Compliance',
                              isCollapsed: isCollapsed,
                              children: complianceItems,
                            ),
                        ],
                      );
                    },
                  ),
                ],

                const Divider(height: 32),

                // Notification bell — real-time unread badge
                if (isCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: NotificationBell(),
                  )
                else
                  Consumer(
                    builder: (context, ref, _) {
                      final unreadAsync = ref.watch(
                        unreadNotificationCountProvider,
                      );
                      final count = unreadAsync.valueOrNull ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                GoRouter.of(context).push('/notifications'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    count > 0
                                        ? Icons.notifications_active
                                        : Icons.notifications_outlined,
                                    size: 20,
                                    color: count > 0
                                        ? Colors.amber
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Notifications',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  if (count > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        count > 99 ? '99+' : '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // "Visit Website" — web only, hidden on Android/Windows
                if (showWebsiteLink)
                  _SidebarItem(
                    icon: Icons.language_rounded,
                    label: 'Visit Website',
                    isSelected: false,
                    isCollapsed: isCollapsed,
                    onTap: () {
                      launchUrl(
                        Uri.parse(websiteUrl),
                        webOnlyWindowName: '_self',
                      );
                    },
                  ),

                // Help & Support
                _SidebarItem(
                  icon: Icons.support_agent,
                  label: 'Help & Support',
                  isSelected: currentPath == '/support',
                  isCollapsed: isCollapsed,
                  onTap: () => GoRouter.of(context).push('/support'),
                ),

                // ── Admin section (scrollable with other items) ──
                Builder(
                  builder: (context) {
                    final staff = ref.watch(loggedInStaffProvider);
                    final member = ref.watch(currentMemberProvider).valueOrNull;

                    bool canSee(String route) {
                      if (!StaffPermissions.canViewRoute(staff, route)) return false;
                      if (staff == null &&
                          !MemberPermissionGuard.canViewRoute(member, route)) {
                        return false;
                      }
                      return true;
                    }

                    final showUsers = canSee(AppRoutes.members);
                    final showPerms = canSee(AppRoutes.permissionsOverview);
                    if (!showUsers && !showPerms) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 12),
                        if (!isCollapsed)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 4),
                            child: Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        if (showUsers)
                          _SidebarItem(
                            icon: Icons.group_outlined,
                            label: 'Users',
                            isSelected: currentPath.startsWith(AppRoutes.members),
                            isCollapsed: isCollapsed,
                            onTap: () =>
                                GoRouter.of(context).push(AppRoutes.members),
                          ),
                        if (showPerms)
                          _SidebarItem(
                            icon: Icons.admin_panel_settings_outlined,
                            label: 'Permissions',
                            isSelected: currentPath
                                .startsWith(AppRoutes.permissionsOverview),
                            isCollapsed: isCollapsed,
                            onTap: () => GoRouter.of(context)
                                .push(AppRoutes.permissionsOverview),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Staff mode banner (when a staff member is logged in)
          Consumer(
            builder: (context, ref, _) {
              final staff = ref.watch(loggedInStaffProvider);
              if (staff == null) return const SizedBox.shrink();
              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 8 : 16,
                  vertical: 4,
                ),
                padding: EdgeInsets.all(isCollapsed ? 8 : 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: isCollapsed
                    ? Tooltip(
                        message:
                            '${staff.name} (${staff.role.displayName}) — Tap to logout',
                        child: InkWell(
                          onTap: () {
                            ref.read(loggedInStaffProvider.notifier).state =
                                null;
                            GoRouter.of(context).go(AppRoutes.billing);
                          },
                          child: Icon(
                            Icons.badge,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Text(
                            staff.role.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  staff.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  staff.role.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              ref.read(loggedInStaffProvider.notifier).state =
                                  null;
                              GoRouter.of(context).go(AppRoutes.billing);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Tooltip(
                              message: 'Staff Logout',
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.logout,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),

          // User Profile Card (Bottom of Sidebar) - Navigates to Settings
          GestureDetector(
            onTap: () => context.go('/settings/general'),
            child: isCollapsed
                ? Tooltip(
                    message: 'Settings',
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSettings
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isSettings
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const GlobalSyncIndicator(),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.settings_outlined,
                            size: 18,
                            color: isSettings
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSettings
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isSettings
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        _buildProfileAvatar(
                          user?.profileImagePath,
                          14,
                          isSettings,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user?.ownerName ?? 'User',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Owner',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const GlobalSyncIndicator(),
                            const SizedBox(height: 2),
                            Icon(
                              Icons.settings_outlined,
                              size: 16,
                              color: isSettings
                                  ? AppColors.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),

          // App branding footer
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
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
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.isCollapsed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 12,
              vertical: isCollapsed ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: isSelected && !isCollapsed
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: isCollapsed
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(message: label, child: item);
    }
    return item;
  }
}

class _SidebarCollapseButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userToggle = ref.watch(sidebarCollapsedProvider);
    final autoCollapsed = MediaQuery.of(context).size.width < 800;
    final isCollapsed = userToggle ?? autoCollapsed;

    return GestureDetector(
      onTap: () {
        ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              isCollapsed
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final bool isCollapsed;
  final List<Widget> children;

  const _SidebarSection({
    required this.title,
    required this.isCollapsed,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SidebarRouteItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentPath;
  final bool isCollapsed;

  const _SidebarRouteItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentPath,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentPath == route;
    return _SidebarItem(
      icon: icon,
      label: label,
      isSelected: isSelected,
      isCollapsed: isCollapsed,
      onTap: () => GoRouter.of(context).push(route),
    );
  }
}

class _WebHeader extends StatelessWidget {
  final String currentPath;

  const _WebHeader({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    String title = 'Dashboard';
    String breadcrumb = 'Home';

    if (currentPath.startsWith(AppRoutes.billing)) {
      title = 'Walk-in Billing';
      breadcrumb = 'Billing';
    } else if (currentPath.startsWith(AppRoutes.products)) {
      title = 'Menu Management';
      breadcrumb = 'Menu';
    } else if (currentPath.startsWith(AppRoutes.dashboard)) {
      title = 'Dashboard';
      breadcrumb = 'Dashboard';
    } else if (currentPath.startsWith(AppRoutes.khata)) {
      title = 'Guest Ledger';
      breadcrumb = 'Khata';
    } else if (currentPath.startsWith(AppRoutes.bills)) {
      title = 'Billing History';
      breadcrumb = 'Bills';
    } else if (currentPath.startsWith(AppRoutes.settings)) {
      title = 'System Settings';
      breadcrumb = 'Settings';
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '/',
                        style: TextStyle(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    Text(
                      breadcrumb,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Header Actions — sync indicator and notification bell
          const GlobalSyncIndicator(),
          const SizedBox(width: 8),
          const NotificationBell(),
        ],
      ),
    );
  }
}
