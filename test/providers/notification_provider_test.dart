/// Tests for notification providers — auth-dependent conditional streams
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/notifications/models/notification_model.dart';
import 'package:tulasihotels/features/notifications/providers/notification_provider.dart';

void main() {
  group('notificationsStreamProvider', () {
    test('starts as loading when overridden with stream', () {
      final container = ProviderContainer(
        overrides: [
          notificationsStreamProvider.overrideWith(
            (_) => Stream.value(<NotificationModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(notificationsStreamProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          notificationsStreamProvider.overrideWith(
            (_) => Stream.value(<NotificationModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(notificationsStreamProvider),
        isA<AsyncValue<List<NotificationModel>>>(),
      );
    });
  });

  group('unreadNotificationCountProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          unreadNotificationCountProvider.overrideWith((_) => Stream.value(0)),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(unreadNotificationCountProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of int', () {
      final container = ProviderContainer(
        overrides: [
          unreadNotificationCountProvider.overrideWith((_) => Stream.value(5)),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(unreadNotificationCountProvider),
        isA<AsyncValue<int>>(),
      );
    });
  });
}
