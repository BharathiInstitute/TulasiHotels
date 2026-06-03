import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/notifications/providers/notification_provider.dart';
import 'package:tulasihotels/features/notifications/widgets/notification_bell.dart';

void main() {
  Widget buildBell({required int unreadCount}) {
    return ProviderScope(
      overrides: [
        unreadNotificationCountProvider.overrideWith(
          (_) => Stream.value(unreadCount),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(appBar: AppBar(actions: const [NotificationBell()])),
      ),
    );
  }

  group('NotificationBell', () {
    testWidgets('shows active icon when there are unread notifications', (
      tester,
    ) async {
      await tester.pumpWidget(buildBell(unreadCount: 3));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('shows outlined icon when no unread notifications', (
      tester,
    ) async {
      await tester.pumpWidget(buildBell(unreadCount: 0));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('shows badge with count', (tester) async {
      await tester.pumpWidget(buildBell(unreadCount: 5));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 99+ for large counts', (tester) async {
      await tester.pumpWidget(buildBell(unreadCount: 150));
      await tester.pumpAndSettle();
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('hides badge when count is 0', (tester) async {
      await tester.pumpWidget(buildBell(unreadCount: 0));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsNothing);
    });

    testWidgets('is an IconButton', (tester) async {
      await tester.pumpWidget(buildBell(unreadCount: 0));
      await tester.pumpAndSettle();
      expect(find.byType(IconButton), findsOneWidget);
    });
  });
}
