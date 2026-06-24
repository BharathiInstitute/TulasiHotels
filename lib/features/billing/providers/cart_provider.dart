/// Cart provider for billing
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/product_model.dart';

/// Cart state
class CartState {
  final List<CartItem> items;
  final String? customerId;
  final String? customerName;
  final String? couponId;
  final String? couponCode;
  final double couponDiscount;

  const CartState({
    this.items = const [],
    this.customerId,
    this.customerName,
    this.couponId,
    this.couponCode,
    this.couponDiscount = 0,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get total => (subtotal - couponDiscount).clamp(0, double.infinity);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get hasCoupon => couponId != null;

  CartState copyWith({
    List<CartItem>? items,
    String? customerId,
    String? customerName,
    String? couponId,
    String? couponCode,
    double? couponDiscount,
  }) {
    return CartState(
      items: items ?? this.items,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      couponId: couponId ?? this.couponId,
      couponCode: couponCode ?? this.couponCode,
      couponDiscount: couponDiscount ?? this.couponDiscount,
    );
  }

  CartState clearCustomer() {
    return CartState(
      items: items,
      couponId: couponId,
      couponCode: couponCode,
      couponDiscount: couponDiscount,
    );
  }

  CartState clearCoupon() {
    return CartState(
      items: items,
      customerId: customerId,
      customerName: customerName,
    );
  }
}

/// Cart notifier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// Max quantity per cart item
  static const int _maxQuantity = 9999;

  /// Add product to cart
  void addProduct(ProductModel product, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex >= 0) {
      // Update existing item quantity (capped)
      final updatedItems = [...state.items];
      final existing = updatedItems[existingIndex];
      final newQty = (existing.quantity + quantity).clamp(1, _maxQuantity);
      updatedItems[existingIndex] = existing.copyWith(quantity: newQty);
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = CartItem(
        productId: product.id,
        name: product.name,
        price: product.price,
        quantity: quantity,
        unit: product.unit.shortName,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  /// Update item quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final capped = quantity.clamp(1, _maxQuantity);
    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: capped);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Increment item quantity
  void incrementQuantity(String productId) {
    final idx = state.items.indexWhere((item) => item.productId == productId);
    if (idx < 0) return;
    updateQuantity(productId, state.items[idx].quantity + 1);
  }

  /// Decrement item quantity
  void decrementQuantity(String productId) {
    final idx = state.items.indexWhere((item) => item.productId == productId);
    if (idx < 0) return;
    updateQuantity(productId, state.items[idx].quantity - 1);
  }

  /// Add a raw CartItem (e.g. combo)
  void addCartItem(CartItem item) {
    final existingIndex = state.items.indexWhere(
      (i) => i.productId == item.productId,
    );
    if (existingIndex >= 0) {
      final updatedItems = [...state.items];
      final existing = updatedItems[existingIndex];
      final newQty = (existing.quantity + item.quantity).clamp(1, _maxQuantity);
      updatedItems[existingIndex] = existing.copyWith(quantity: newQty);
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  /// Remove item from cart
  void removeItem(String productId) {
    final updatedItems = state.items
        .where((item) => item.productId != productId)
        .toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Set customer for the bill
  void setCustomer(String customerId, String customerName) {
    state = state.copyWith(customerId: customerId, customerName: customerName);
  }

  /// Clear customer
  void clearCustomer() {
    state = state.clearCustomer();
  }

  /// Apply a validated coupon
  void applyCoupon({
    required String couponId,
    required String couponCode,
    required double discount,
  }) {
    state = state.copyWith(
      couponId: couponId,
      couponCode: couponCode,
      couponDiscount: discount,
    );
  }

  /// Remove applied coupon
  void removeCoupon() {
    state = state.clearCoupon();
  }

  /// Clear entire cart
  void clearCart() {
    state = const CartState();
  }

  /// Populate cart from an existing bill (reorder feature)
  void populateFromBill(BillModel bill) {
    state = CartState(
      items: List.from(bill.items),
      customerId: bill.customerId,
      customerName: bill.customerName,
    );
  }
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
