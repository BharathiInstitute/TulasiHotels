/// Owner-facing feedback analytics dashboard
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/feedback/services/feedback_service.dart';
import 'package:tulasihotels/models/feedback_model.dart';

class FeedbackDashboardScreen extends ConsumerStatefulWidget {
  const FeedbackDashboardScreen({super.key});

  @override
  ConsumerState<FeedbackDashboardScreen> createState() =>
      _FeedbackDashboardScreenState();
}

class _FeedbackDashboardScreenState
    extends ConsumerState<FeedbackDashboardScreen> {
  Map<String, double>? _averages;
  bool _loadingAverages = true;

  @override
  void initState() {
    super.initState();
    _loadAverages();
  }

  Future<void> _loadAverages() async {
    final avg = await FeedbackService.getAverageRatings();
    if (mounted) {
      setState(() {
      _averages = avg;
      _loadingAverages = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Average ratings summary
          if (_loadingAverages)
            const Center(child: CircularProgressIndicator())
          else if (_averages != null) ...[
            Text('Average Ratings', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                _RatingCard(label: 'Food', value: _averages!['food'] ?? 0),
                const SizedBox(width: 8),
                _RatingCard(
                    label: 'Service', value: _averages!['service'] ?? 0),
                const SizedBox(width: 8),
                _RatingCard(
                    label: 'Ambiance', value: _averages!['ambiance'] ?? 0),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Overall',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(
                          (_averages!['overall'] ?? 0).toStringAsFixed(1),
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(' / 5', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Recent feedback
          Text('Recent Feedback', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          StreamBuilder<List<FeedbackModel>>(
            stream: FeedbackService.recentFeedbackStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No feedback yet')),
                  ),
                );
              }

              return Column(
                children: items.map((fb) {
                  final isNegative = fb.averageRating < 3;
                  return Card(
                    color: isNegative
                        ? Colors.red.shade50
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isNegative ? Colors.red : Colors.green,
                        child: Text(
                          fb.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(fb.customerName ?? 'Anonymous'),
                      subtitle: fb.comments != null
                          ? Text(fb.comments!,
                              maxLines: 2, overflow: TextOverflow.ellipsis)
                          : Text(
                              'Food: ${fb.foodRating} · Service: ${fb.serviceRating} · Ambiance: ${fb.ambianceRating}'),
                      trailing: isNegative
                          ? const Icon(Icons.warning, color: Colors.red)
                          : null,
                      isThreeLine: fb.comments != null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final String label;
  final double value;

  const _RatingCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value.toStringAsFixed(1),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Icon(Icons.star, size: 16, color: Colors.amber.shade700),
            ],
          ),
        ),
      ),
    );
  }
}
