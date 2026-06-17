import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/core/services/connectivity_service.dart';
import 'package:tulasihotels/core/services/sync_status_service.dart';
import 'package:tulasihotels/shared/widgets/global_sync_indicator.dart';

void main() {
  Widget buildIndicator({
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
        home: Scaffold(body: GlobalSyncIndicator()),
      ),
    );
  }

  group('GlobalSyncIndicator', () {
    testWidgets('shows cloud_done when online and fully synced',
        (tester) async {
      await tester.pumpWidget(buildIndicator(isOnline: true));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
      expect(find.byIcon(Icons.cloud_upload), findsNothing);
    });

    testWidgets('shows cloud_off when offline', (tester) async {
      await tester.pumpWidget(buildIndicator(isOnline: false));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsNothing);
    });

    testWidgets('shows cloud_upload when online with unsynced items',
        (tester) async {
      const status = GlobalSyncStatus(
        collections: {
          'bills': CollectionSyncStatus(
            name: 'bills',
            totalDocs: 10,
            unsyncedDocs: 3,
          ),
        },
        isOnline: true,
      );
      await tester.pumpWidget(
        buildIndicator(isOnline: true, syncStatus: status),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    });

    testWidgets('shows badge count for unsynced items', (tester) async {
      const status = GlobalSyncStatus(
        collections: {
          'bills': CollectionSyncStatus(
            name: 'bills',
            totalDocs: 10,
            unsyncedDocs: 5,
          ),
        },
        isOnline: true,
      );
      await tester.pumpWidget(
        buildIndicator(isOnline: true, syncStatus: status),
      );
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 9+ badge when unsynced count exceeds 9',
        (tester) async {
      const status = GlobalSyncStatus(
        collections: {
          'bills': CollectionSyncStatus(
            name: 'bills',
            totalDocs: 50,
            unsyncedDocs: 15,
          ),
        },
        isOnline: true,
      );
      await tester.pumpWidget(
        buildIndicator(isOnline: true, syncStatus: status),
      );
      await tester.pumpAndSettle();
      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('no badge when all items synced', (tester) async {
      const status = GlobalSyncStatus(
        collections: {
          'bills': CollectionSyncStatus(
            name: 'bills',
            totalDocs: 10,
          ),
        },
        isOnline: true,
      );
      await tester.pumpWidget(
        buildIndicator(isOnline: true, syncStatus: status),
      );
      await tester.pumpAndSettle();
      // Badge count text should not appear
      expect(find.text('0'), findsNothing);
      expect(find.text('9+'), findsNothing);
    });

    testWidgets('is tappable (GestureDetector exists)', (tester) async {
      await tester.pumpWidget(buildIndicator(isOnline: true));
      await tester.pumpAndSettle();
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
