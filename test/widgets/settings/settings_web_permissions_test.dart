import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/settings/screens/settings_web_screen.dart';
import 'package:tulasihotels/models/user_model.dart';
import 'package:tulasihotels/router/app_router.dart';

import '../../helpers/pump_app.dart';

UserModel _testUser() {
  return UserModel(
    id: 'owner-1',
    shopName: 'Kirana',
    ownerName: 'Uma',
    phone: '9999999999',
    settings: const UserSettings(),
    createdAt: DateTime(2024),
  );
}

RoutePermissionState _permission({bool view = false, bool update = false}) {
  return RoutePermissionState(
    isResolved: true,
    canView: view,
    canCreate: false,
    canUpdate: update,
    canDelete: false,
  );
}

void main() {
  group('SettingsWebScreen permissions', () {
    testWidgets('shows only settings tabs when hardware and subscription are denied', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        const SettingsWebScreen(initialTab: 'general'),
        overrides: [
          currentUserProvider.overrideWith((ref) => _testUser()),
          routePermissionProvider.overrideWith((ref, route) {
            switch (route) {
              case AppRoutes.settings:
                return _permission(view: true, update: true);
              case AppRoutes.settingsHardware:
              case AppRoutes.subscription:
                return _permission();
              default:
                return _permission(view: true, update: true);
            }
          }),
        ],
      );

      expect(find.text('General'), findsWidgets);
      expect(find.text('Account'), findsWidgets);
      expect(find.text('Billing'), findsWidgets);
      expect(find.text('Geo-Fence'), findsWidgets);
      expect(find.text('Hardware'), findsNothing);
      expect(find.text('Subscription'), findsNothing);
    });

    testWidgets('shows all settings tabs when all modules are allowed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        const SettingsWebScreen(initialTab: 'general'),
        overrides: [
          currentUserProvider.overrideWith((ref) => _testUser()),
          routePermissionProvider.overrideWith(
            (ref, route) => _permission(view: true, update: true),
          ),
        ],
      );

      expect(find.text('General'), findsWidgets);
      expect(find.text('Account'), findsWidgets);
      expect(find.text('Billing'), findsWidgets);
      expect(find.text('Geo-Fence'), findsWidgets);
      expect(find.text('Hardware'), findsWidgets);
      expect(find.text('Subscription'), findsWidgets);
    });

    testWidgets('shows denied message for blocked hardware tab', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        const SettingsWebScreen(initialTab: 'hardware'),
        overrides: [
          currentUserProvider.overrideWith((ref) => _testUser()),
          routePermissionProvider.overrideWith((ref, route) {
            if (route == AppRoutes.settingsHardware) {
              return _permission();
            }
            return _permission(view: true, update: true);
          }),
        ],
      );

      expect(
        find.text('You do not have permission to view Hardware.'),
        findsOneWidget,
      );
    });
  });
}
