/// Shared helper for opening the subscription/plan center from anywhere.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/subscription/models/plan_config.dart';
import 'package:tulasihotels/router/app_router.dart';

class PlanNavigationService {
  PlanNavigationService._();

  static void goToSubscription(BuildContext context) {
    context.go(AppRoutes.subscription);
  }

  static Future<void> pushToSubscription(BuildContext context) {
    return context.push(AppRoutes.subscription);
  }

  static String planLabel(String key) => PlanConfig.labelForKey(key);

  static int maxRestaurants(String key) => PlanConfig.maxRestaurantsForKey(key);
}
