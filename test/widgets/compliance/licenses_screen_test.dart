import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/compliance/providers/compliance_provider.dart';
import 'package:tulasihotels/features/compliance/screens/licenses_screen.dart';
import 'package:tulasihotels/models/license_model.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_factories_extended.dart';

void main() {
  group('LicensesScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const LicensesScreen(), overrides: [
        licensesProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.text('Licenses & Permits'), findsOneWidget);
    });

    testWidgets('shows FAB for adding license', (tester) async {
      await pumpWidget(tester, const LicensesScreen(), overrides: [
        licensesProvider.overrideWith((_) => Stream.value([])),
      ]);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add License'), findsOneWidget);
    });

    testWidgets('shows license number in list', (tester) async {
      final licenses = [
        makeLicense(
          licenseNumber: 'FSSAI-9876',
        ),
      ];
      await pumpWidget(tester, const LicensesScreen(), overrides: [
        licensesProvider.overrideWith((_) => Stream.value(licenses)),
      ]);
      expect(find.textContaining('FSSAI-9876'), findsOneWidget);
    });

    testWidgets('shows expired chip for past expiry', (tester) async {
      final licenses = [
        makeLicense(
          type: LicenseType.liquor,
          expiryDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];
      await pumpWidget(tester, const LicensesScreen(), overrides: [
        licensesProvider.overrideWith((_) => Stream.value(licenses)),
      ]);
      // Should show "Expired" or red urgency chip
      expect(
        find.textContaining('Expired').evaluate().isNotEmpty ||
            find.textContaining('EXPIRED').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            licensesProvider.overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(home: Scaffold(body: LicensesScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows multiple licenses', (tester) async {
      final licenses = [
        makeLicense(licenseNumber: 'LIC-001'),
        makeLicense(
          id: 'lic-2',
          type: LicenseType.fireNoc,
          licenseNumber: 'FIRE-002',
        ),
      ];
      await pumpWidget(tester, const LicensesScreen(), overrides: [
        licensesProvider.overrideWith((_) => Stream.value(licenses)),
      ]);
      expect(find.textContaining('LIC-001'), findsOneWidget);
      expect(find.textContaining('FIRE-002'), findsOneWidget);
    });
  });
}
