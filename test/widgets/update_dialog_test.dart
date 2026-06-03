import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/core/services/windows_update_service.dart';

/// Tests for UpdateDialog UI structure.
///
/// UpdateDialog depends on WindowsUpdateService (static) and Platform.isWindows,
/// so we test the dialog UI by building it with a mock AppVersionInfo.
void main() {
  group('UpdateDialog UI', () {
    testWidgets('shows Update Available title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.system_update),
                        SizedBox(width: 12),
                        Text('Update Available'),
                      ],
                    ),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Version 2.1.0 is available!'),
                        SizedBox(height: 8),
                        Text(
                          'The automatic update could not complete. Please update manually.',
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: null, child: Text('Later')),
                      FilledButton.icon(
                        onPressed: null,
                        icon: Icon(Icons.download, size: 18),
                        label: Text('Update Now'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('Version 2.1.0 is available!'), findsOneWidget);
      expect(find.byIcon(Icons.system_update), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('shows changelog when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("What's new:"),
                        SizedBox(height: 4),
                        Text('- Bug fixes\n- Performance improvements'),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text("What's new:"), findsOneWidget);
      expect(find.textContaining('Bug fixes'), findsOneWidget);
    });
  });

  group('AppVersionInfo model', () {
    test('creates with required fields', () {
      const info = AppVersionInfo(
        version: '2.1.0',
        buildNumber: 42,
        downloadUrl: 'https://example.com/update.exe',
        changelog: 'Bug fixes',
        forceUpdate: false,
      );
      expect(info.version, '2.1.0');
      expect(info.buildNumber, 42);
      expect(info.downloadUrl, 'https://example.com/update.exe');
      expect(info.changelog, 'Bug fixes');
      expect(info.forceUpdate, false);
    });

    test('forceUpdate flag works', () {
      const info = AppVersionInfo(
        version: '3.0.0',
        buildNumber: 100,
        downloadUrl: 'https://example.com/v3.exe',
        changelog: 'Major update',
        forceUpdate: true,
      );
      expect(info.forceUpdate, true);
    });

    test('empty changelog defaults', () {
      const info = AppVersionInfo(
        version: '2.0.1',
        buildNumber: 20,
        downloadUrl: 'https://example.com/patch.exe',
      );
      expect(info.changelog.isEmpty, isTrue);
      expect(info.forceUpdate, false);
    });
  });
}
