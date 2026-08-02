import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/staff/screens/permission_manager_screen.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

import '../../helpers/pump_app.dart';

StaffModel _staff() {
  return StaffModel(
    id: 'staff-1',
    name: 'Asha',
    email: 'asha@example.com',
    phone: '9999999999',
    role: StaffRole.manager,
    pin: '1234',
    createdAt: DateTime(2024),
    permissions: const <String, List<String>>{},
  );
}

RoutePermissionState _fullAccess(String route) {
  return const RoutePermissionState(
    isResolved: true,
    canView: true,
    canCreate: true,
    canUpdate: true,
    canDelete: true,
  );
}

Finder _panelRow(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
}

Color? _chipColor(WidgetTester tester, Finder row, String label) {
  final textFinder = find.descendant(of: row, matching: find.text(label)).first;
  final containerFinder = find.ancestor(of: textFinder, matching: find.byType(Container)).first;
  final container = tester.widget<Container>(containerFinder);
  final decoration = container.decoration;
  if (decoration is BoxDecoration) {
    return decoration.color;
  }
  return null;
}

void main() {
  group('PermissionManagerScreen', () {
    testWidgets('keeps View selected when Update is toggled on a settings panel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWidget(
        tester,
        PermissionManagerScreen(staff: _staff()),
        overrides: [
          routePermissionProvider.overrideWith((ref, route) => _fullAccess(route)),
        ],
      );

      final hardwareRow = _panelRow('Hardware Panel');
      await tester.ensureVisible(hardwareRow);
      await tester.tap(
        find.descendant(of: hardwareRow, matching: find.text('Update')).first,
      );
      await tester.pumpAndSettle();

      expect(_chipColor(tester, hardwareRow, 'View'), isNot(equals(Colors.transparent)));
    });

    testWidgets('keeps View selected when Delete is toggled on a CRUD panel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWidget(
        tester,
        PermissionManagerScreen(staff: _staff()),
        overrides: [
          routePermissionProvider.overrideWith((ref, route) => _fullAccess(route)),
        ],
      );

      final billingRow = _panelRow('Billing Panel');
      await tester.ensureVisible(billingRow);
      await tester.tap(
        find.descendant(of: billingRow, matching: find.text('Delete')).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(of: billingRow, matching: find.text('View')).first,
      );
      await tester.pumpAndSettle();

      expect(_chipColor(tester, billingRow, 'View'), isNot(equals(Colors.transparent)));
    });
  });
}
