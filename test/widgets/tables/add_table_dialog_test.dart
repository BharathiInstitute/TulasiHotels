import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/tables/widgets/add_table_dialog.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('AddTableDialog', () {
    List<Override> overrides() => [
      routePermissionProvider.overrideWith(
        (ref, route) => const RoutePermissionState.fullAccess(),
      ),
    ];

    testWidgets('shows Add Table title in add mode', (tester) async {
      await pumpWidget(
        tester,
        const AddTableDialog(),
        overrides: overrides(),
      );
      expect(find.text('Add Table'), findsOneWidget);
    });

    testWidgets('shows Edit Table title in edit mode', (tester) async {
      await pumpWidget(
        tester,
        AddTableDialog(editTable: makeTable(label: 'Window Seat')),
        overrides: overrides(),
      );
      expect(find.text('Edit Table'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows form fields for table properties', (tester) async {
      await pumpWidget(
        tester,
        const AddTableDialog(),
        overrides: overrides(),
      );
      expect(find.textContaining('Capacity'), findsOneWidget);
      expect(find.textContaining('Floor'), findsOneWidget);
      expect(find.textContaining('Table Number'), findsOneWidget);
    });

    testWidgets('shows bulk add toggle', (tester) async {
      await pumpWidget(
        tester,
        const AddTableDialog(),
        overrides: overrides(),
      );
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('validates empty fields', (tester) async {
      await pumpWidget(
        tester,
        const AddTableDialog(),
        overrides: overrides(),
      );
      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsWidgets);
    });
  });
}
