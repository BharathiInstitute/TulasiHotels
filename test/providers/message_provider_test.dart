/// Tests for message providers — stream types and data flow
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/staff/providers/message_provider.dart';
import 'package:tulasihotels/models/message_model.dart';

void main() {
  group('recentMessagesProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          recentMessagesProvider.overrideWith(
            (_) => Stream.value(<MessageModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(recentMessagesProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          recentMessagesProvider.overrideWith(
            (_) => Stream.value(<MessageModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(recentMessagesProvider),
        isA<AsyncValue<List<MessageModel>>>(),
      );
    });
  });

  group('announcementsProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          announcementsProvider.overrideWith(
            (_) => Stream.value(<MessageModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(announcementsProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          announcementsProvider.overrideWith(
            (_) => Stream.value(<MessageModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(announcementsProvider),
        isA<AsyncValue<List<MessageModel>>>(),
      );
    });
  });
}
