/// Tests for specials provider — day-of-week filtering logic
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/product_model.dart';

void main() {
  group('dailySpecials filtering logic', () {
    // Mock products with isSpecial and availableDays
    ProductModel makeProduct({
      required String id,
      required String name,
      bool isSpecial = false,
      List<int>? availableDays,
    }) {
      return ProductModel(
        id: id,
        name: name,
        price: 100,
        stock: 10,
        category: 'Food',
        isSpecial: isSpecial,
        availableDays: availableDays,
        createdAt: DateTime(2024),
      );
    }

    test('filters only isSpecial products', () {
      final products = [
        makeProduct(id: 'p1', name: 'Dosa', isSpecial: true),
        makeProduct(id: 'p2', name: 'Idli'),
        makeProduct(id: 'p3', name: 'Vada', isSpecial: true),
      ];

      final specials = products.where((p) => p.isSpecial).toList();
      expect(specials.length, 2);
    });

    test('availableDays null means available every day', () {
      final product = makeProduct(
        id: 'p1',
        name: 'Daily Special',
        isSpecial: true,
      );

      for (int day = 1; day <= 7; day++) {
        final available =
            product.availableDays == null || product.availableDays!.contains(day);
        expect(available, isTrue, reason: 'Should be available on day $day');
      }
    });

    test('availableDays restricts to specific days', () {
      final product = makeProduct(
        id: 'p1',
        name: 'Weekend Special',
        isSpecial: true,
        availableDays: [6, 7], // Sat, Sun
      );

      // Monday = 1
      expect(product.availableDays!.contains(1), isFalse);
      // Saturday = 6
      expect(product.availableDays!.contains(6), isTrue);
      // Sunday = 7
      expect(product.availableDays!.contains(7), isTrue);
    });

    test('combined filter: isSpecial AND matching day', () {
      const today = 3; // Wednesday
      final products = [
        makeProduct(
            id: 'p1', name: 'Daily', isSpecial: true),
        makeProduct(
            id: 'p2',
            name: 'Mon-Wed',
            isSpecial: true,
            availableDays: [1, 2, 3]),
        makeProduct(
            id: 'p3',
            name: 'Weekend',
            isSpecial: true,
            availableDays: [6, 7]),
        makeProduct(id: 'p4', name: 'Regular'),
      ];

      final specials = products
          .where((p) =>
              p.isSpecial &&
              (p.availableDays == null || p.availableDays!.contains(today)))
          .toList();

      expect(specials.length, 2);
      expect(specials.map((s) => s.name), containsAll(['Daily', 'Mon-Wed']));
    });

    test('empty products list returns empty specials', () {
      final products = <ProductModel>[];
      final specials = products.where((p) => p.isSpecial).toList();
      expect(specials, isEmpty);
    });
  });
}
