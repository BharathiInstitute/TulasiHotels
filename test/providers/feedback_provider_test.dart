/// Tests for feedback providers — provider types and data flow
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/features/feedback/providers/feedback_provider.dart';
import 'package:tulasihotels/models/feedback_model.dart';

void main() {
  group('recentFeedbackProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          recentFeedbackProvider.overrideWith(
            (_) => Stream.value(<FeedbackModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(recentFeedbackProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          recentFeedbackProvider.overrideWith(
            (_) => Stream.value(<FeedbackModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(recentFeedbackProvider),
        isA<AsyncValue<List<FeedbackModel>>>(),
      );
    });
  });

  group('averageRatingsProvider', () {
    test('starts as loading', () {
      final container = ProviderContainer(
        overrides: [
          averageRatingsProvider.overrideWith(
            (_) => Future.value(<String, double>{}),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(averageRatingsProvider).isLoading, isTrue);
    });

    test('returns AsyncValue of correct type', () {
      final container = ProviderContainer(
        overrides: [
          averageRatingsProvider.overrideWith(
            (_) => Future.value(<String, double>{}),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(averageRatingsProvider),
        isA<AsyncValue<Map<String, double>>>(),
      );
    });
  });
}
