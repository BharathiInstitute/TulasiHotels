/// Feedback summary report — avg ratings, trends
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/feedback/services/feedback_service.dart';
import 'package:tulasihotels/models/feedback_model.dart';

class FeedbackReportScreen extends ConsumerStatefulWidget {
  const FeedbackReportScreen({super.key});

  @override
  ConsumerState<FeedbackReportScreen> createState() =>
      _FeedbackReportScreenState();
}

class _FeedbackReportScreenState
    extends ConsumerState<FeedbackReportScreen> {
  Map<String, double>? _averages;
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    final avg = await FeedbackService.getAverageRatings();
    if (mounted) {
      setState(() {
      _averages = avg;
      _loading = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Report')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _averages == null
              ? Center(
                  child: FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.star),
                    label: const Text('Generate Report'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary cards
                    Text('Average Ratings', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _RatingBar(
                        label: 'Food', value: _averages!['food'] ?? 0),
                    _RatingBar(
                        label: 'Service', value: _averages!['service'] ?? 0),
                    _RatingBar(
                        label: 'Ambiance',
                        value: _averages!['ambiance'] ?? 0),
                    const Divider(height: 32),
                    _RatingBar(
                      label: 'Overall',
                      value: _averages!['overall'] ?? 0,
                      isBold: true,
                    ),
                    const SizedBox(height: 24),

                    // Recent low-rated feedback
                    Text('Low-Rated Feedback',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    StreamBuilder<List<FeedbackModel>>(
                      stream: FeedbackService.recentFeedbackStream(),
                      builder: (context, snapshot) {
                        final items = (snapshot.data ?? [])
                            .where((fb) => fb.averageRating < 3)
                            .toList();

                        if (items.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No low-rated feedback — great!'),
                            ),
                          );
                        }

                        return Column(
                          children: items.map((fb) => Card(
                                color: Colors.red.shade50,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    child: Text(
                                      fb.averageRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  title: Text(
                                      fb.customerName ?? 'Anonymous'),
                                  subtitle: Text(fb.comments ?? 'No comments'),
                                ),
                              )).toList(),
                        );
                      },
                    ),
                  ],
                ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;

  const _RatingBar({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: isBold
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 5,
              minHeight: isBold ? 12 : 8,
              backgroundColor: Colors.grey.shade200,
              color: value >= 4
                  ? Colors.green
                  : value >= 3
                      ? Colors.amber
                      : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(1),
              style: isBold
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
