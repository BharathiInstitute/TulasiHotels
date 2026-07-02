/// Bottom sheet for confirming subscription cancellation.
/// Shows what features will be lost and what the user will get on Free.
library;

import 'package:flutter/material.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';

class CancelSubscriptionSheet extends StatelessWidget {
  final PlanConfig currentPlan;
  final DateTime? expiresAt;

  const CancelSubscriptionSheet({
    super.key,
    required this.currentPlan,
    this.expiresAt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expiryLabel = expiresAt != null
        ? '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}'
        : 'your current billing period ends';

    // Features user will lose (current plan features not in Free)
    final lostFeatures = <String>[];
    for (final feature in PlanFeature.values) {
      if (currentPlan.has(feature) && !PlanConfig.free.has(feature)) {
        lostFeatures.add(_featureLabel(feature));
      }
    }

    // Numeric downgrades
    final downgrades = <String>[];
    if (currentPlan.maxStaff == null || (currentPlan.maxStaff ?? 0) > 0) {
      downgrades.add('Staff users → ${PlanConfig.free.maxStaff} (Owner only)');
    }
    if (currentPlan.maxProducts != PlanConfig.free.maxProducts) {
      downgrades.add('Products → max ${PlanConfig.free.maxProducts}');
    }
    if (currentPlan.maxTables != PlanConfig.free.maxTables) {
      downgrades.add('Tables → max ${PlanConfig.free.maxTables}');
    }
    if (currentPlan.maxCustomers != PlanConfig.free.maxCustomers) {
      downgrades.add('Customers → max ${PlanConfig.free.maxCustomers}');
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.error, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Cancel Subscription?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Your ${currentPlan.name} plan will remain active until $expiryLabel.',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            // Features you'll lose
            if (lostFeatures.isNotEmpty) ...[
              Text(
                'After expiry, you\'ll lose:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...lostFeatures.map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.remove_circle_outline,
                        size: 16,
                        color: cs.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Limits downgrade
            if (downgrades.isNotEmpty) ...[
              Text(
                'You\'ll move to the Free plan:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...downgrades.map(
                (d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, size: 14, color: cs.outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(d, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${PlanConfig.free.billsPerMonth} bills/month',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],

            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                      ),
                      child: const Text('Keep Plan'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error),
                      ),
                      child: const Text('Cancel Plan'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _featureLabel(PlanFeature feature) {
    switch (feature) {
      case PlanFeature.kitchenDisplay:
        return 'Kitchen Display System';
      case PlanFeature.inventoryBasic:
        return 'Inventory tracking';
      case PlanFeature.inventoryFull:
        return 'Full inventory & ingredients';
      case PlanFeature.cashRegister:
        return 'Cash register';
      case PlanFeature.gstExport:
        return 'GST export';
      case PlanFeature.reservations:
        return 'Reservations';
      case PlanFeature.coupons:
        return 'Coupons & discounts';
      case PlanFeature.reportsBasic:
        return 'Basic reports';
      case PlanFeature.reports3:
        return '3 analytics dashboards';
      case PlanFeature.reports9:
        return '9 analytics dashboards';
      case PlanFeature.reportsCustom:
        return 'Custom report builder';
      case PlanFeature.multiLocation:
        return 'Multi-location management';
    }
  }
}
