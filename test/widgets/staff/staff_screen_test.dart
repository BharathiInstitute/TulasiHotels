import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/admin/models/store_member.dart';
import 'package:tulasihotels/features/admin/providers/members_provider.dart';
import 'package:tulasihotels/features/hotels/providers/hotel_provider.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/screens/staff_screen.dart';
import 'package:tulasihotels/models/staff_model.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('StaffScreen', () {
    List<Override> baseOverrides() => [
      currentHotelProvider.overrideWith((ref) => null),
      membersStreamProvider.overrideWith(
        (ref) => Stream.value(const <StoreMember>[]),
      ),
      routePermissionProvider.overrideWith(
        (ref, route) => const RoutePermissionState(
          isResolved: true,
          canView: true,
          canCreate: true,
          canUpdate: true,
          canDelete: true,
        ),
      ),
    ];

    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const StaffScreen(), overrides: [
        ...baseOverrides(),
        filteredStaffProvider.overrideWithValue(
          const AsyncValue.data(<StaffModel>[]),
        ),
      ]);
      expect(find.text('Staff Management'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            filteredStaffProvider.overrideWithValue(
              const AsyncValue<List<StaffModel>>.loading(),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: StaffScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders when data loaded', (tester) async {
      await pumpWidget(tester, const StaffScreen(), overrides: [
        ...baseOverrides(),
        filteredStaffProvider.overrideWithValue(
          const AsyncValue.data(<StaffModel>[]),
        ),
      ]);
      expect(find.byType(StaffScreen), findsOneWidget);
    });
  });
}
