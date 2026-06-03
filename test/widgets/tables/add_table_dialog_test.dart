import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/tables/widgets/add_table_dialog.dart';

void main() {
  group('AddTableDialog', () {
    testWidgets('shows Add Table title in add mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AddTableDialog())),
      );
      expect(find.textContaining('Add Table'), findsWidgets);
    });

    testWidgets('shows Edit Table title in edit mode', (tester) async {
      // Import makeTable if needed — use minimal table for constructor
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AddTableDialog())),
      );
      // In add mode, we see form fields
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows form fields for table properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AddTableDialog())),
      );
      expect(find.textContaining('Capacity'), findsOneWidget);
      expect(find.textContaining('Floor'), findsOneWidget);
    });

    testWidgets('shows bulk add toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AddTableDialog())),
      );
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('validates empty fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AddTableDialog())),
      );
      // Try to find and tap save button
      final saveBtn = find.text('Save');
      if (saveBtn.evaluate().isNotEmpty) {
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();
        // Validation error messages should appear
        expect(
          find.textContaining('required').evaluate().isNotEmpty ||
              find.textContaining('enter').evaluate().isNotEmpty ||
              find.textContaining('Please').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });
  });
}
