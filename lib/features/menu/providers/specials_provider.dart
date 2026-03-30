/// Daily specials provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/products/providers/products_provider.dart';
import 'package:tulasihotels/models/product_model.dart';

/// Filtered list of today's specials
final dailySpecialsProvider =
    Provider.autoDispose<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final today = DateTime.now().weekday; // 1=Mon..7=Sun

  return productsAsync.whenData(
    (products) => products
        .where((p) =>
            p.isSpecial &&
            (p.availableDays == null || p.availableDays!.contains(today)))
        .toList(),
  );
});
