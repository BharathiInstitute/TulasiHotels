/// Compact usage bar shown at the top of limit-enforced screens.
/// Shows current / max with a color-coded progress bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/core/services/user_metrics_service.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';
import 'package:tulasihotels/features/subscription/providers/subscription_provider.dart';
import 'package:tulasihotels/features/subscription/providers/usage_limits_provider.dart';
import 'package:tulasihotels/router/app_router.dart';

/// Shows a slim usage bar for a single resource type.
/// Hides itself completely when under 50% usage (non-intrusive).
class PlanUsageBar extends ConsumerWidget {
  final String label;
  final int Function(UserLimits) getCurrent;
  final int Function(PlanConfig) getLimit;

  const PlanUsageBar({
    super.key,
    required this.label,
    required this.getCurrent,
    required this.getLimit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limits = ref.watch(currentLimitsProvider);
    final config = ref.watch(planConfigProvider);
    final theme = Theme.of(context);

    final current = getCurrent(limits);
    final max = getLimit(config);
    final isUnlimited = max >= 999999;

    // Hide when unlimited or under 50% — only show when approaching limit
    if (isUnlimited) return const SizedBox.shrink();
    final fraction = max > 0 ? current / max : 0.0;
    if (fraction < 0.5) return const SizedBox.shrink();

    final isAtLimit = current >= max;
    final color = isAtLimit
        ? Colors.red
        : fraction >= 0.8
            ? Colors.orange
            : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: color.withValues(alpha: 0.06),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$label: $current / $max',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isAtLimit)
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.subscription),
                        child: Text(
                          'Upgrade →',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
