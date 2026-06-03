import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/billing/screens/gst_export_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('GstExportScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await pumpWidget(tester, const GstExportScreen());
      expect(find.text('GST Reports'), findsOneWidget);
    });

    testWidgets('shows month picker', (tester) async {
      await pumpWidget(tester, const GstExportScreen());
      // Month picker uses calendar_month icon
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    testWidgets('shows generate button', (tester) async {
      await pumpWidget(tester, const GstExportScreen());
      expect(find.text('Generate GST Summary'), findsOneWidget);
    });
  });
}
