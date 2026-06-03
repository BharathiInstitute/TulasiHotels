import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/providers/shift_provider.dart';
import 'package:tulasihotels/features/staff/screens/shift_schedule_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('ShiftScheduleScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(
        tester,
        const ShiftScheduleScreen(),
        overrides: [todayShiftsProvider.overrideWith((_) => Stream.value([]))],
      );
      expect(find.text('Shift Schedule'), findsOneWidget);
    });

    testWidgets('shows shift staff names in list', (tester) async {
      final shifts = [
        makeShift(staffName: 'Ravi'),
        makeShift(id: 's2', staffName: 'Priya'),
      ];
      await pumpWidget(
        tester,
        const ShiftScheduleScreen(),
        overrides: [
          todayShiftsProvider.overrideWith((_) => Stream.value(shifts)),
        ],
      );
      expect(find.text('Ravi'), findsOneWidget);
      expect(find.text('Priya'), findsOneWidget);
    });

    testWidgets('shows FAB for adding shift', (tester) async {
      await pumpWidget(
        tester,
        const ShiftScheduleScreen(),
        overrides: [todayShiftsProvider.overrideWith((_) => Stream.value([]))],
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayShiftsProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: ShiftScheduleScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
