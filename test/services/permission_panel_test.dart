library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/permissions/permission_panel.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/router/app_router.dart';

void main() {
  group('PermissionPanels.normalizeToPanelPermissions', () {
    test('merges child and parent routes into a single panel key', () {
      final normalized = PermissionPanels.normalizeToPanelPermissions({
        AppRoutes.orders: [PermissionAction.view.key],
        AppRoutes.orderDetail: [PermissionAction.update.key],
        AppRoutes.newOrder: [PermissionAction.create.key],
      });

      expect(normalized.keys, contains(AppRoutes.tables));
      expect(
        normalized[AppRoutes.tables],
        containsAll([
          PermissionAction.view.key,
          PermissionAction.update.key,
          PermissionAction.create.key,
        ]),
      );
      expect(normalized.keys, isNot(contains(AppRoutes.orders)));
      expect(normalized.keys, isNot(contains(AppRoutes.orderDetail)));
      expect(normalized.keys, isNot(contains(AppRoutes.newOrder)));
    });

    test('merges aliases and keeps unknown routes intact', () {
      final normalized = PermissionPanels.normalizeToPanelPermissions({
        AppRoutes.billing: [PermissionAction.view.key],
        AppRoutes.splitBill: [PermissionAction.delete.key],
        '/custom-route': [PermissionAction.view.key],
      });

      expect(normalized[AppRoutes.billing], containsAll(['view', 'delete']));
      expect(normalized['/custom-route'], ['view']);
    });
  });

  group('PermissionPanels metadata helpers', () {
    test('panel label resolves from alias route', () {
      expect(
        PermissionPanels.panelLabelForRoute(AppRoutes.combos),
        'Products Panel',
      );
    });

    test('panel category resolves from alias route', () {
      expect(
        PermissionPanels.panelCategoryForRoute(AppRoutes.menuPerformance),
        PermissionConfig.reportsCategory,
      );
    });
  });
}
