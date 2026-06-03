import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/providers/attendance_provider.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/screens/attendance_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('AttendanceScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(
        tester,
        const AttendanceScreen(),
        overrides: [
          todayAttendanceProvider.overrideWith((_) => Stream.value([])),
          activeStaffStreamProvider.overrideWith((_) => Stream.value([])),
        ],
      );
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('shows Today and History tabs', (tester) async {
      await pumpWidget(
        tester,
        const AttendanceScreen(),
        overrides: [
          todayAttendanceProvider.overrideWith((_) => Stream.value([])),
          activeStaffStreamProvider.overrideWith((_) => Stream.value([])),
        ],
      );
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('shows staff names in attendance list', (tester) async {
      final staff = [
        makeStaff(name: 'Ravi Kumar'),
        makeStaff(id: 's2', name: 'Sunita Devi'),
      ];
      final attendance = [
        makeAttendance(staffId: 'staff-1', staffName: 'Ravi Kumar'),
      ];
      await pumpWidget(
        tester,
        const AttendanceScreen(),
        overrides: [
          todayAttendanceProvider.overrideWith((_) => Stream.value(attendance)),
          activeStaffStreamProvider.overrideWith((_) => Stream.value(staff)),
        ],
      );
      expect(find.text('Ravi Kumar'), findsWidgets);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayAttendanceProvider.overrideWith((_) => const Stream.empty()),
            activeStaffStreamProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: AttendanceScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
