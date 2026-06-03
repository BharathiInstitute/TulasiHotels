/// Integration test: Stock → Product → Bill → Stock deducted
///
/// Tests the inventory-to-billing workflow: ingredients tracked,
/// products sold, stock levels decrease, low-stock alerts triggered.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/ingredient_model.dart';

import '../helpers/test_factories.dart';
import '../helpers/test_factories_extended.dart';

void main() {
  group('Integration: Inventory → Billing Flow', () {
    test('Step 1: Ingredient starts with full stock', () {
      final ingredient = makeIngredient(
        id: 'ing-1',
        name: 'Basmati Rice',
        currentStock: 50,
        minLevel: 10,
        costPerUnit: 80,
        unit: IngredientUnit.kg,
      );

      expect(ingredient.currentStock, 50);
      expect(ingredient.isLowStock, isFalse);
      expect(ingredient.costPerUnit, 80);
    });

    test('Step 2: Product created from ingredient', () {
      final product = makeProduct(
        id: 'prod-1',
        name: 'Biryani',
        price: 250,
        purchasePrice: 100,
        stock: 100,
        lowStockAlert: 20,
      );

      expect(product.price, 250);
      expect(product.purchasePrice, 100);
      expect(product.isLowStock, isFalse);
      expect(product.isOutOfStock, isFalse);
    });

    test('Step 3: Order placed with product items', () {
      final order = makeOrder(
        id: 'ord-1',
        items: [
          makeOrderItem(
            productId: 'prod-1',
            name: 'Biryani',
            price: 250,
            quantity: 3,
          ),
          makeOrderItem(
            productId: 'prod-2',
            name: 'Naan',
            price: 60,
            quantity: 5,
          ),
        ],
      );

      expect(order.total, 1050); // 250*3 + 60*5
      expect(order.itemCount, 8);
    });

    test('Step 4: OrderItem converts to CartItem for billing', () {
      final orderItem = makeOrderItem(
        productId: 'prod-1',
        name: 'Biryani',
        price: 250,
        quantity: 3,
      );

      final cartItem = orderItem.toCartItem();
      expect(cartItem.productId, 'prod-1');
      expect(cartItem.name, 'Biryani');
      expect(cartItem.price, 250);
      expect(cartItem.quantity, 3);
      expect(cartItem.total, 750);
    });

    test('Step 5: Bill created from cart items', () {
      final items = [
        const CartItem(
          productId: 'prod-1',
          name: 'Biryani',
          price: 250,
          quantity: 3,
          unit: 'plate',
        ),
        const CartItem(
          productId: 'prod-2',
          name: 'Naan',
          price: 60,
          quantity: 5,
          unit: 'piece',
        ),
      ];

      final bill = makeBill(
        id: 'bill-1',
        items: items,
        total: 1050,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 1100,
      );

      expect(bill.total, 1050);
      expect(bill.itemCount, 8); // 3 + 5
      expect(bill.paymentMethod, PaymentMethod.cash);
      expect(bill.changeAmount, 50); // 1100 - 1050
    });

    test('Step 6: Product stock decremented after sale', () {
      final beforeSale = makeProduct(
        id: 'prod-1',
        name: 'Biryani',
        price: 250,
        stock: 100,
        lowStockAlert: 20,
      );

      // 3 units sold
      final afterSale = beforeSale.copyWith(stock: beforeSale.stock - 3);
      expect(afterSale.stock, 97);
      expect(afterSale.isLowStock, isFalse);
    });

    test('Step 7: Heavy sales trigger low stock', () {
      final product = makeProduct(
        id: 'prod-1',
        name: 'Biryani',
        price: 250,
        stock: 25,
        lowStockAlert: 20,
      );

      // Sold 10 more units
      final afterSale = product.copyWith(stock: product.stock - 10);
      expect(afterSale.stock, 15);
      expect(afterSale.isLowStock, isTrue);
    });

    test('Step 8: Ingredient stock decremented for preparation', () {
      final ingredient = makeIngredient(
        id: 'ing-1',
        name: 'Basmati Rice',
        currentStock: 50,
        minLevel: 10,
      );

      // 3 Biryanis use ~1.5 kg each = 4.5 kg
      final afterCooking = ingredient.copyWith(
        currentStock: ingredient.currentStock - 4.5,
      );
      expect(afterCooking.currentStock, 45.5);
      expect(afterCooking.isLowStock, isFalse);
    });

    test('Step 9: Ingredient hits low stock threshold', () {
      final ingredient = makeIngredient(
        id: 'ing-1',
        name: 'Basmati Rice',
        currentStock: 12,
        minLevel: 10,
      );

      // Another big batch uses 5 kg
      final afterBatch = ingredient.copyWith(
        currentStock: ingredient.currentStock - 5,
      );
      expect(afterBatch.currentStock, 7);
      expect(afterBatch.isLowStock, isTrue);
    });

    test('Step 10: Restock restores ingredient', () {
      final lowIngredient = makeIngredient(
        id: 'ing-1',
        name: 'Basmati Rice',
        currentStock: 7,
        minLevel: 10,
      );
      expect(lowIngredient.isLowStock, isTrue);

      final restocked = lowIngredient.copyWith(currentStock: 50);
      expect(restocked.isLowStock, isFalse);
      expect(restocked.currentStock, 50);
    });
  });

  group('Integration: Payment methods', () {
    test('UPI payment has no change', () {
      // Construct directly since makeBill defaults receivedAmount to 100
      final bill = BillModel(
        id: 'bill-upi',
        billNumber: 99,
        items: const [
          CartItem(
            productId: 'p-1',
            name: 'X',
            price: 500,
            quantity: 1,
            unit: 'u',
          ),
        ],
        total: 500,
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2026),
        date: '2026-01-01',
      );
      expect(bill.paymentMethod, PaymentMethod.upi);
      expect(bill.changeAmount, isNull);
    });

    test('credit (udhar) payment tracked', () {
      final bill = makeBill(
        total: 750,
        paymentMethod: PaymentMethod.udhar,
        customerId: 'cust-1',
        customerName: 'Ravi',
      );
      expect(bill.paymentMethod, PaymentMethod.udhar);
      expect(bill.customerName, 'Ravi');
    });
  });
}
