import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/compliance/providers/compliance_provider.dart';
import 'package:tulasihotels/features/compliance/screens/equipment_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('EquipmentScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(
        tester,
        const EquipmentScreen(),
        overrides: [equipmentProvider.overrideWith((_) => Stream.value([]))],
      );
      expect(find.text('Equipment'), findsOneWidget);
    });

    testWidgets('shows FAB for adding equipment', (tester) async {
      await pumpWidget(
        tester,
        const EquipmentScreen(),
        overrides: [equipmentProvider.overrideWith((_) => Stream.value([]))],
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Equipment'), findsOneWidget);
    });

    testWidgets('shows equipment name in list', (tester) async {
      final items = [
        makeEquipment(name: 'Industrial Mixer'),
        makeEquipment(id: 'e2', name: 'Walk-in Cooler'),
      ];
      await pumpWidget(
        tester,
        const EquipmentScreen(),
        overrides: [equipmentProvider.overrideWith((_) => Stream.value(items))],
      );
      expect(find.text('Industrial Mixer'), findsOneWidget);
      expect(find.text('Walk-in Cooler'), findsOneWidget);
    });

    testWidgets('shows brand and serial number', (tester) async {
      final items = [
        makeEquipment(
          name: 'Oven',
          brand: 'Bakers Pride',
          serialNumber: 'SN-12345',
        ),
      ];
      await pumpWidget(
        tester,
        const EquipmentScreen(),
        overrides: [equipmentProvider.overrideWith((_) => Stream.value(items))],
      );
      expect(find.textContaining('Bakers Pride'), findsOneWidget);
      expect(find.textContaining('SN-12345'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            equipmentProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: EquipmentScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows service due chip for overdue equipment', (tester) async {
      final items = [
        makeEquipment(
          name: 'Fryer',
          nextServiceDue: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];
      await pumpWidget(
        tester,
        const EquipmentScreen(),
        overrides: [equipmentProvider.overrideWith((_) => Stream.value(items))],
      );
      expect(find.textContaining('SERVICE DUE'), findsOneWidget);
    });
  });
}
