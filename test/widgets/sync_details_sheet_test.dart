import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/core/services/connectivity_service.dart';
import 'package:tulasihotels/core/services/sync_status_service.dart';
import 'package:tulasihotels/shared/widgets/sync_details_sheet.dart';

void main() {
  Widget buildSheet({
    required bool isOnline,
    GlobalSyncStatus? syncStatus,
  }) {
    final status = syncStatus ?? GlobalSyncStatus.empty;
    return ProviderScope(
      overrides: [
        isOnlineProvider.overrideWithValue(isOnline),
        globalSyncStatusProvider.overrideWith(
          (ref) => Stream.value(status),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: SyncDetailsSheet())),
      ),
    );
  }

  group('SyncDetailsSheet', () {
    testWidgets('shows "Sync Status" header', (tester) async {
      await tester.pumpWidget(buildSheet(isOnline: true));
      await tester.pumpAndSettle();
      expect(find.text('Sync Status'), findsOneWidget);
    });

    testWidgets('shows Online chip when online', (tester) async {
      await tester.pumpWidget(buildSheet(isOnline: true));
      await tester.pumpAndSettle();
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('shows Offline chip when offline', (tester) async {
      await tester.pumpWidget(buildSheet(isOnline: false));
      await tester.pumpAndSettle();
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Online'), findsNothing);
    });

    testWidgets('shows cloud_done icon when online', (tester) async {
      await tester.pumpWidget(buildSheet(isOnline: true));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_done), findsWidgets);
    });

    testWidgets('shows cloud_off icon when offline', (tester) async {
      await tester.pumpWidget(buildSheet(isOnline: false));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('shows "No data loaded yet" for empty collections',
        (tester) async {
      await tester.pumpWidget(buildSheet(isOnline: true));
      await tester.pumpAndSettle();
      expect(find.text('No data loaded yet'), findsOneWidget);
    });

    testWidgets('shows collection rows with display names', (tester) async {
      const status = GlobalSyncStatus(
        collections: {
          'products': CollectionSyncStatus(
            name: 'products',
            totalDocs: 25,
          ),
          'bills': CollectionSyncStatus(
            name: 'bills',
            totalDocs: 100,
            unsyncedDocs: 3,
          ),
          'customers': CollectionSyncStatus(
            name: 'customers',
            totalDocs: 50,
          ),
        },
        isOnline: true,
      );
      await tester.pumpWidget(buildSheet(isOnline: true, syncStatus: status));
      await tester.pumpAndSettle();
      // Mapped display names
      expect(find.text('Menu Items'), findsOneWidget);
      expect(find.text('Bills'), findsOneWidget);
      expect(find.text('Guests'), findsOneWidget);
    });

    testWidgets('shows doc counts per collection', (tester) async {
      const status = GlobalSyncStatus(
        collections: {
          'bills': CollectionSyncStatus(
            name: 'bills',
            totalDocs: 42,
          ),
        },
        isOnline: true,
      );
      await tester.pumpWidget(buildSheet(isOnline: true, syncStatus: status));
      await tester.pumpAndSettle();
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows unsynced count next to collection', (tester) async {
      const status = GlobalSyncStatus(
        collections: {
          'bills': CollectionSyncStatus(
            name: 'bills',
            totalDocs: 50,
            unsyncedDocs: 7,
          ),
        },
        isOnline: true,
      );
      await tester.pumpWidget(buildSheet(isOnline: true, syncStatus: status));
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('shows "All data synced" when totalUnsynced is 0',
        (tester) async {
      const status = GlobalSyncStatus(
        collections: {
          'bills': CollectionSyncStatus(
            name: 'bills',
            totalDocs: 10,
          ),
        },
        isOnline: true,
      );
      await tester.pumpWidget(buildSheet(isOnline: true, syncStatus: status));
      await tester.pumpAndSettle();
      expect(find.text('All data synced to cloud'), findsOneWidget);
    });

    testWidgets('shows unsynced summary with plural', (tester) async {
      const status = GlobalSyncStatus(
        collections: {
          'bills': CollectionSyncStatus(
            name: 'bills',
            totalDocs: 50,
            unsyncedDocs: 4,
          ),
          'products': CollectionSyncStatus(
            name: 'products',
            totalDocs: 20,
            unsyncedDocs: 1,
          ),
        },
        isOnline: true,
      );
      await tester.pumpWidget(buildSheet(isOnline: true, syncStatus: status));
      await tester.pumpAndSettle();
      expect(find.text('5 items not synced'), findsOneWidget);
    });

    testWidgets('shows unsynced summary with singular', (tester) async {
      const status = GlobalSyncStatus(
        collections: {
          'bills': CollectionSyncStatus(
            name: 'bills',
            totalDocs: 50,
            unsyncedDocs: 1,
          ),
        },
        isOnline: true,
      );
      await tester.pumpWidget(buildSheet(isOnline: true, syncStatus: status));
      await tester.pumpAndSettle();
      expect(find.text('1 item not synced'), findsOneWidget);
    });

    testWidgets('unknown collection uses name as-is', (tester) async {
      const status = GlobalSyncStatus(
        collections: {
          'myCustomColl': CollectionSyncStatus(
            name: 'myCustomColl',
            totalDocs: 5,
          ),
        },
        isOnline: true,
      );
      await tester.pumpWidget(buildSheet(isOnline: true, syncStatus: status));
      await tester.pumpAndSettle();
      expect(find.text('myCustomColl'), findsOneWidget);
    });
  });
}
