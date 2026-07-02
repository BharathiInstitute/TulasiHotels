/// Wrapper widget that gates a screen behind a plan feature check.
/// If the user's plan doesn't include the feature, shows an upgrade screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';
import 'package:tulasihotels/features/subscription/providers/subscription_provider.dart';
import 'package:tulasihotels/features/subscription/widgets/upgrade_dialog.dart';

class PlanGatedScreen extends ConsumerWidget {
  final PlanFeature requiredFeature;
  final String featureName;
  final Widget child;

  const PlanGatedScreen({
    super.key,
    required this.requiredFeature,
    required this.featureName,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(hasFeatureProvider(requiredFeature));

    if (!hasAccess) {
      final config = ref.watch(planConfigProvider);
      return UpgradeRequiredScreen(
        featureName: featureName,
        message:
            '$featureName is not available on the ${config.name} plan. '
            'Upgrade your plan to unlock this feature.',
      );
    }

    return child;
  }
}
