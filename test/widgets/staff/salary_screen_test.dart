import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/screens/salary_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('SalaryScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(
        tester,
        const SalaryScreen(),
        overrides: [staffStreamProvider.overrideWith((_) => Stream.value([]))],
      );
      expect(find.text('Salary Calculator'), findsOneWidget);
    });

    testWidgets('shows calculate button', (tester) async {
      final staff = [makeStaff(name: 'Ravi')];
      await pumpWidget(
        tester,
        const SalaryScreen(),
        overrides: [
          staffStreamProvider.overrideWith((_) => Stream.value(staff)),
        ],
      );
      expect(find.textContaining('Calculate'), findsOneWidget);
    });

    testWidgets('shows month navigator', (tester) async {
      await pumpWidget(
        tester,
        const SalaryScreen(),
        overrides: [staffStreamProvider.overrideWith((_) => Stream.value([]))],
      );
      // Should have chevron icons for month navigation
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows content when staff loaded', (tester) async {
      final staff = [
        makeStaff(name: 'Ravi'),
        makeStaff(id: 's2', name: 'Priya'),
      ];
      await pumpWidget(
        tester,
        const SalaryScreen(),
        overrides: [
          staffStreamProvider.overrideWith((_) => Stream.value(staff)),
        ],
      );
      // Screen renders with calculate button visible
      expect(find.textContaining('Calculate'), findsOneWidget);
    });
  });
}
