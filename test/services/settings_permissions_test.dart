import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/models/store_role.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/permission_panel.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/router/app_router.dart';

void main() {
  group('Settings permission route mapping', () {
    test('general settings tabs map to settings module', () {
      expect(PermissionPanels.resolvePanelRoute('/settings/general'), AppRoutes.settings);
      expect(PermissionPanels.resolvePanelRoute('/settings/account'), AppRoutes.settings);
      expect(PermissionPanels.resolvePanelRoute('/settings/billing'), AppRoutes.settings);
      expect(PermissionPanels.resolvePanelRoute(AppRoutes.attendanceSettings), AppRoutes.settings);
      expect(PermissionPanels.resolvePanelRoute(AppRoutes.themeSettings), AppRoutes.settings);
    });

    test('hardware and subscription map to separate modules', () {
      expect(
        PermissionPanels.resolvePanelRoute(AppRoutes.settingsHardware),
        AppRoutes.settingsHardware,
      );
      expect(
        PermissionPanels.resolvePanelRoute('/settings/subscription'),
        AppRoutes.subscription,
      );
      expect(
        PermissionPanels.resolvePanelRoute(AppRoutes.subscription),
        AppRoutes.subscription,
      );
    });
  });

  group('Settings permission access', () {
    test('owner has full access to settings modules', () {
      expect(
        PermissionCenter.canView(route: AppRoutes.settings, isOwner: true),
        isTrue,
      );
      expect(
        PermissionCenter.hasAction(
          route: AppRoutes.settingsHardware,
          action: PermissionAction.update,
          isOwner: true,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.hasAction(
          route: AppRoutes.subscription,
          action: PermissionAction.update,
          isOwner: true,
        ),
        isTrue,
      );
    });

    test('legacy accountant member gets settings view fallback only', () {
      final member = StoreMember(
        uid: 'member-1',
        email: 'accountant@example.com',
        displayName: 'Accountant',
        role: StoreRole.accountant,
        permissions: null,
        joinedAt: DateTime(2024),
      );

      expect(
        PermissionCenter.canView(
          route: '/settings/general',
          isOwner: false,
          member: member,
        ),
        isTrue,
      );
      expect(
        PermissionCenter.hasAction(
          route: AppRoutes.settings,
          action: PermissionAction.update,
          isOwner: false,
          member: member,
        ),
        isFalse,
      );
      expect(
        PermissionCenter.canView(
          route: AppRoutes.subscription,
          isOwner: false,
          member: member,
        ),
        isFalse,
      );
    });
  });
}
