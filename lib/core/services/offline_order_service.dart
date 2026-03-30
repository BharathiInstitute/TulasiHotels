/// Offline order queue for connectivity resilience
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineOrderService {
  static const _key = 'offline_orders';

  /// Save an order locally when offline
  static Future<void> saveOfflineOrder(Map<String, dynamic> orderData) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    existing.add(jsonEncode({
      ...orderData,
      '_offlineSavedAt': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(_key, existing);
  }

  /// Get all pending offline orders
  static Future<List<Map<String, dynamic>>> getPendingOfflineOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .toList();
  }

  /// Remove a synced order from the offline queue
  static Future<void> removeOrder(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    if (index >= 0 && index < existing.length) {
      existing.removeAt(index);
      await prefs.setStringList(_key, existing);
    }
  }

  /// Clear all offline orders after sync
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Check if there are pending offline orders
  static Future<bool> hasPendingOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.isNotEmpty;
  }
}
