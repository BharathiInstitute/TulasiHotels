/// NPS Survey Results Screen for Super Admin
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/super_admin/providers/super_admin_provider.dart';
import 'package:tulasihotels/features/super_admin/screens/admin_shell_screen.dart';

class NpsScreen extends ConsumerWidget {
  const NpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final npsAsync = ref.watch(npsResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NPS Survey Results'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: MediaQuery.of(context).size.width >= 1024
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    adminShellScaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(npsResultsProvider),
          ),
        ],
      ),
      body: npsAsync.when(
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading NPS data: $e')),
        data: (results) {
          if (results.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_neutral, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No NPS responses yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Responses appear after eligible users submit the survey.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final summary = _computeSummary(results);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(summary: summary, total: results.length),
                const SizedBox(height: 24),
                _ScoreDistributionCard(results: results),
                const SizedBox(height: 24),
                _ResponsesCard(results: results),
              ],
            ),
          );
        },
      ),
    );
  }

  _NpsSummary _computeSummary(List<Map<String, dynamic>> results) {
    int promoters = 0, passives = 0, detractors = 0;
    int total = 0;
    double scoreSum = 0;

    for (final r in results) {
      final score = r['score'] as int;
      scoreSum += score;
      total++;
      if (score >= 9) {
        promoters++;
      } else if (score >= 7) {
        passives++;
      } else {
        detractors++;
      }
    }

    final promoterPct = total > 0 ? (promoters / total) * 100 : 0.0;
    final detractorPct = total > 0 ? (detractors / total) * 100 : 0.0;
    final npsScore = promoterPct - detractorPct;
    final avg = total > 0 ? scoreSum / total : 0.0;

    return _NpsSummary(
      npsScore: npsScore,
      avg: avg,
      promoters: promoters,
      passives: passives,
      detractors: detractors,
    );
  }
}

class _NpsSummary {
  final double npsScore;
  final double avg;
  final int promoters;
  final int passives;
  final int detractors;

  const _NpsSummary({
    required this.npsScore,
    required this.avg,
    required this.promoters,
    required this.passives,
    required this.detractors,
  });
}

class _SummaryRow extends StatelessWidget {
  final _NpsSummary summary;
  final int total;

  const _SummaryRow({required this.summary, required this.total});

  @override
  Widget build(BuildContext context) {
    final nps = summary.npsScore;
    final npsColor = nps >= 50
        ? Colors.green
        : nps >= 0
        ? Colors.orange
        : Colors.red;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'NPS Score',
            value: nps.toStringAsFixed(0),
            subtitle: nps >= 50
                ? 'Excellent'
                : nps >= 0
                ? 'Good'
                : 'Needs Work',
            color: npsColor,
            icon: Icons.star,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'Avg Score',
            value: summary.avg.toStringAsFixed(1),
            subtitle: 'out of 10',
            color: Colors.blue,
            icon: Icons.bar_chart,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'Responses',
            value: '$total',
            subtitle: 'total submitted',
            color: Colors.purple,
            icon: Icons.people,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreDistributionCard extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const _ScoreDistributionCard({required this.results});

  @override
  Widget build(BuildContext context) {
    // Count each score 0–10
    final counts = List.filled(11, 0);
    for (final r in results) {
      final score = (r['score'] as int).clamp(0, 10);
      counts[score]++;
    }
    final maxCount = counts.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Score Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 12, height: 12, color: Colors.red.shade300),
                const SizedBox(width: 4),
                const Text('Detractors (0–6)', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(width: 12, height: 12, color: Colors.orange.shade300),
                const SizedBox(width: 4),
                const Text('Passives (7–8)', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(width: 12, height: 12, color: Colors.green.shade400),
                const SizedBox(width: 4),
                const Text('Promoters (9–10)', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(11, (i) {
                final count = counts[i];
                final barHeight = maxCount > 0
                    ? (count / maxCount) * 100.0
                    : 0.0;
                final color = i >= 9
                    ? Colors.green.shade400
                    : i >= 7
                    ? Colors.orange.shade300
                    : Colors.red.shade300;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: barHeight.clamp(4.0, 100.0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$i',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsesCard extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const _ResponsesCard({required this.results});

  @override
  Widget build(BuildContext context) {
    // Sort by date descending
    final sorted = [...results]
      ..sort((a, b) {
        final aDate = a['completedAt'] as DateTime?;
        final bDate = b['completedAt'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Responses (${sorted.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...sorted.map((r) {
              final score = r['score'] as int;
              final userId = r['userId'] as String;
              final date = r['completedAt'] as DateTime?;
              final color = score >= 9
                  ? Colors.green
                  : score >= 7
                  ? Colors.orange
                  : Colors.red;
              final label = score >= 9
                  ? 'Promoter'
                  : score >= 7
                  ? 'Passive'
                  : 'Detractor';
              final dateStr = date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Unknown date';

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(
                    '$score',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  userId.length > 20 ? '${userId.substring(0, 20)}...' : userId,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(dateStr, style: const TextStyle(fontSize: 11)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
