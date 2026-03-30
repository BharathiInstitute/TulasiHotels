/// Customer feedback screen — view and manage feedback
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/feedback/providers/feedback_provider.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(recentFeedbackProvider);
    final ratingsAsync = ref.watch(averageRatingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Feedback')),
      body: Column(
        children: [
          // Average ratings card
          ratingsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (ratings) => Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _RatingBadge(label: 'Food', value: ratings['food'] ?? 0),
                    _RatingBadge(
                      label: 'Service',
                      value: ratings['service'] ?? 0,
                    ),
                    _RatingBadge(
                      label: 'Ambiance',
                      value: ratings['ambiance'] ?? 0,
                    ),
                    _RatingBadge(
                      label: 'Overall',
                      value: ratings['overall'] ?? 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Feedback list
          Expanded(
            child: feedbackAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (feedbacks) {
                if (feedbacks.isEmpty) {
                  return const Center(child: Text('No feedback yet'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final fb = feedbacks[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(fb.averageRating.toStringAsFixed(0)),
                        ),
                        title: Text(fb.customerName ?? 'Anonymous'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _stars(fb.foodRating),
                                const SizedBox(width: 4),
                                Text('Food', style: theme.textTheme.bodySmall),
                                const SizedBox(width: 12),
                                _stars(fb.serviceRating),
                                const SizedBox(width: 4),
                                Text(
                                  'Service',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            if (fb.comments != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  fb.comments!,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 14,
          color: Colors.amber,
        );
      }),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final String label;
  final double value;

  const _RatingBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
