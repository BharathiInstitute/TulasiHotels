import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/screens/staff_screen.dart';
import 'package:tulasihotels/models/staff_model.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('StaffScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const StaffScreen(), overrides: [
        filteredStaffProvider
            .overrideWithValue(const AsyncValue.data(<StaffModel>[])),
      ]);
      expect(find.text('Staff Management'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredStaffProvider
                .overrideWithValue(const AsyncValue<List<StaffModel>>.loading()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: StaffScreen()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders when data loaded', (tester) async {
      await pumpWidget(tester, const StaffScreen(), overrides: [
        filteredStaffProvider
            .overrideWithValue(const AsyncValue.data(<StaffModel>[])),
      ]);
      expect(find.byType(StaffScreen), findsOneWidget);
    });
  });
}
