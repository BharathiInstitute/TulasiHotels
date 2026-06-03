import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/core/widgets/force_update_screen.dart';

void main() {
  group('ForceUpdateScreen', () {
    testWidgets('renders update required title', (tester) async {
      await tester.pumpWidget(
        const ForceUpdateScreen(
          currentVersion: '1.0.0',
          requiredVersion: '2.0.0',
        ),
      );
      expect(find.text('Update Required'), findsOneWidget);
    });

    testWidgets('shows current and required version in message',
        (tester) async {
      await tester.pumpWidget(
        const ForceUpdateScreen(
          currentVersion: '1.2.3',
          requiredVersion: '3.0.0',
        ),
      );
      expect(find.textContaining('3.0.0'), findsOneWidget);
      expect(find.textContaining('1.2.3'), findsOneWidget);
    });

    testWidgets('shows system_update icon', (tester) async {
      await tester.pumpWidget(
        const ForceUpdateScreen(
          currentVersion: '1.0.0',
          requiredVersion: '2.0.0',
        ),
      );
      expect(find.byIcon(Icons.system_update_rounded), findsOneWidget);
    });

    testWidgets('shows Update Now button', (tester) async {
      await tester.pumpWidget(
        const ForceUpdateScreen(
          currentVersion: '1.0.0',
          requiredVersion: '2.0.0',
        ),
      );
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('no progress indicator initially', (tester) async {
      await tester.pumpWidget(
        const ForceUpdateScreen(
          currentVersion: '1.0.0',
          requiredVersion: '2.0.0',
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
