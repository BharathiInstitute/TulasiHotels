/// Customer feedback providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/feedback/services/feedback_service.dart';
import 'package:tulasihotels/models/feedback_model.dart';

/// Stream recent feedback
final recentFeedbackProvider =
    StreamProvider.autoDispose<List<FeedbackModel>>((ref) {
  return FeedbackService.recentFeedbackStream();
});

/// Average ratings
final averageRatingsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) {
  return FeedbackService.getAverageRatings();
});
