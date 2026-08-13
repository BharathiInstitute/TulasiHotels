/// Enhanced service for navigating to subscription settings from any gated feature.
/// Provides consistent navigation with analytics tracking and feature context.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';
import 'package:tulasihotels/router/app_router.dart';

class SubscriptionNavigationService {
  SubscriptionNavigationService._();

  /// Navigate to subscription settings screen.
  /// Use this for "View Plans" buttons in upgrade screens.
  /// showPlans=true will show the plan selection directly
  static Future<void> navigateToSubscription(
    BuildContext context, {
    PlanFeature? sourceFeature,
    String? analyticsSource,
  }) {
    // Future analytics hook for feature-based subscription navigation.
    // Analytics.trackFeatureNavigationToSubscription(
    //   feature: sourceFeature?.name,
    //   source: analyticsSource,
    // );
    return context.push('${AppRoutes.settingsSubscription}?showPlans=true');
  }

  /// Navigate using replace (doesn't add to navigation stack).
  /// Use this when you want to replace current screen with subscription.
  static void replaceWithSubscription(
    BuildContext context, {
    PlanFeature? sourceFeature,
  }) {
    context.go('${AppRoutes.settingsSubscription}?showPlans=true');
  }

  /// Check if subscription route is accessible and navigate.
  static Future<bool> canNavigateToSubscription(BuildContext context) async {
    try {
      await navigateToSubscription(context);
      return true;
    } catch (e) {
      debugPrint('Failed to navigate to subscription: $e');
      return false;
    }
  }
}
