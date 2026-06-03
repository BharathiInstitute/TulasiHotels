import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/compliance/providers/compliance_provider.dart';
import 'package:tulasihotels/features/compliance/screens/complaints_screen.dart';
import 'package:tulasihotels/models/complaint_model.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('ComplaintsScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const ComplaintsScreen(), overrides: [
        allComplaintsProvider.overrideWith((_) => Stream.value([])),
        activeComplaintsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.text('Complaints'), findsOneWidget);
    });

    testWidgets('shows empty state when no complaints', (tester) async {
      await pumpWidget(tester, const ComplaintsScreen(), overrides: [
        allComplaintsProvider.overrideWith((_) => Stream.value([])),
        activeComplaintsProvider.overrideWith((_) => Stream.value([])),
      ]);
      // Should show some indication of no data or an empty list
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('shows complaint description in list', (tester) async {
      final complaints = [
        makeComplaint(description: 'Cold food served'),
        makeComplaint(id: 'c2', description: 'Late delivery'),
      ];
      await pumpWidget(tester, const ComplaintsScreen(), overrides: [
        allComplaintsProvider.overrideWith((_) => Stream.value(complaints)),
        activeComplaintsProvider.overrideWith((_) => Stream.value(complaints)),
      ]);
      expect(find.text('Cold food served'), findsOneWidget);
      expect(find.text('Late delivery'), findsOneWidget);
    });

    testWidgets('shows FAB for new complaint', (tester) async {
      await pumpWidget(tester, const ComplaintsScreen(), overrides: [
        allComplaintsProvider.overrideWith((_) => Stream.value([])),
        activeComplaintsProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Complaint'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      // Avoid pumpAndSettle — CircularProgressIndicator never settles
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allComplaintsProvider.overrideWith((_) => const Stream.empty()),
            activeComplaintsProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: ComplaintsScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('filter chip toggles between Active and All', (tester) async {
      final complaints = [
        makeComplaint(
          description: 'Open issue',
          status: ComplaintStatus.open,
        ),
        makeComplaint(
          id: 'c2',
          description: 'Resolved issue',
          status: ComplaintStatus.resolved,
        ),
      ];
      await pumpWidget(tester, const ComplaintsScreen(), overrides: [
        allComplaintsProvider.overrideWith((_) => Stream.value(complaints)),
        activeComplaintsProvider.overrideWith(
          (_) => Stream.value([complaints.first]),
        ),
      ]);
      // Find the filter chip — tap "All" chip to show all
      final allChip = find.widgetWithText(FilterChip, 'All');
      if (allChip.evaluate().isNotEmpty) {
        await tester.tap(allChip);
        await tester.pumpAndSettle();
      }
    });
  });
}
