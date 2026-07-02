/// A reusable dialog shown when a feature or limit requires a plan upgrade.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/subscription/services/plan_enforcement_service.dart';

/// Shows an upgrade-required dialog. Returns `true` if user chose to upgrade.
Future<bool> showUpgradeDialog(
  BuildContext context,
  PlanCheckResult result,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.lock_outline, size: 40, color: Colors.orange),
      title: const Text('Upgrade Required'),
      content: Text(result.message ?? 'This feature requires a plan upgrade.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('View Plans'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await context.push('/subscription');
  }
  return confirmed == true;
}

/// A full-screen placeholder for gated feature screens.
/// Shows a lock icon with an upgrade message and a button to view plans.
class UpgradeRequiredScreen extends StatelessWidget {
  final String featureName;
  final String message;

  const UpgradeRequiredScreen({
    super.key,
    required this.featureName,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(featureName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.orange.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                featureName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/subscription'),
                icon: const Icon(Icons.upgrade),
                label: const Text('View Plans'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
