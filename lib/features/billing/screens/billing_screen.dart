/// Main billing screen
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/core/services/barcode_scanner_service.dart';
import 'package:tulasihotels/core/theme/responsive_helper.dart';
import 'package:tulasihotels/core/utils/formatters.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/billing/providers/cart_provider.dart';
import 'package:tulasihotels/features/billing/widgets/payment_modal.dart';
import 'package:tulasihotels/features/billing/screens/pos_web_screen.dart';
import 'package:tulasihotels/features/products/providers/products_provider.dart';
import 'package:tulasihotels/features/menu/providers/combo_provider.dart';
import 'package:tulasihotels/models/combo_model.dart';
import 'package:tulasihotels/l10n/app_localizations.dart';
import 'package:tulasihotels/models/bill_model.dart';
import 'package:tulasihotels/models/product_model.dart';
import 'package:tulasihotels/router/app_router.dart';
import 'package:tulasihotels/shared/widgets/loading_states.dart';
import 'package:tulasihotels/shared/widgets/nps_survey_dialog.dart';
import 'package:tulasihotels/shared/widgets/onboarding_checklist.dart';
import 'package:tulasihotels/features/coupons/providers/coupon_provider.dart';
import 'package:tulasihotels/features/coupons/services/coupon_service.dart';
import 'package:tulasihotels/models/coupon_model.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Check NPS survey eligibility once after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowNps());
  }

  Future<void> _maybeShowNps() async {
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await NpsSurveyDialog.showIfEligible(
      context,
      uid: user.id,
      accountCreatedAt: user.createdAt,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaymentModal(),
    );
  }

  Future<void> _showCouponPicker() async {
    final cart = ref.read(cartProvider);
    if (cart.hasCoupon) {
      ref.read(cartProvider.notifier).removeCoupon();
      return;
    }
    final coupons = await ref.read(activeCouponsProvider.future);
    if (!mounted) return;
    if (coupons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active coupons available')),
      );
      return;
    }
    final selected = await showModalBottomSheet<CouponModel>(
      context: context,
      builder: (ctx) => _CouponPickerSheet(coupons: coupons),
    );
    if (selected == null || !mounted) return;
    final validated = await CouponService.validateCoupon(
      selected.code, cart.subtotal,
    );
    if (!mounted) return;
    if (validated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon is invalid or expired')),
      );
    } else {
      ref.read(cartProvider.notifier).applyCoupon(
        couponId: validated.id,
        couponCode: validated.code,
        discount: validated.calculateDiscount(cart.subtotal),
      );
    }
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Consumer(
            builder: (context, ref, _) =>
                _buildCartSheetContent(scrollController, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildCartSheetContent(
    ScrollController scrollController,
    WidgetRef ref,
  ) {
    final l10n = context.l10n;
    final cart = ref.watch(cartProvider);

    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cart (${cart.itemCount} items)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (cart.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).clearCart();
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n.clear,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        // Cart items
        Expanded(
          child: cart.isEmpty
              ? Center(child: Text(l10n.emptyCart))
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Dismissible(
                      key: ValueKey(item.productId),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => ref
                          .read(cartProvider.notifier)
                          .removeItem(item.productId),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      child: _buildCartItem(item, ref),
                    );
                  },
                ),
        ),
        // Footer
        if (cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coupon row
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 16,
                        color: cart.hasCoupon
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cart.hasCoupon
                              ? '${cart.couponCode} • -${Formatters.currency(cart.couponDiscount)}'
                              : 'Apply coupon',
                          style: TextStyle(
                            fontSize: 12,
                            color: cart.hasCoupon
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: cart.hasCoupon
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _showCouponPicker,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 28),
                        ),
                        child: Text(
                          cart.hasCoupon ? 'Remove' : 'Select',
                          style: TextStyle(
                            fontSize: 12,
                            color: cart.hasCoupon
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.total,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            Formatters.currency(cart.total),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showPaymentModal();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(l10n.pay.toUpperCase()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCartItem(CartItem item, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.currency(item.price)} x ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(item.total),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .decrementQuantity(item.productId),
                  icon: const Icon(Icons.remove, size: 16),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .incrementQuantity(item.productId),
                  icon: const Icon(Icons.add, size: 16),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () =>
                ref.read(cartProvider.notifier).removeItem(item.productId),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final l10n = context.l10n;
    final code = await BarcodeScannerService.scanBarcode(context);
    if (code == null) return;

    // Search for product by barcode
    final products = ref.read(productsProvider).value ?? [];
    ProductModel? foundProduct;

    for (final p in products) {
      if (p.barcode == code) {
        foundProduct = p;
        break;
      }
    }

    if (foundProduct != null) {
      ref.read(cartProvider.notifier).addProduct(foundProduct);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.add} ${foundProduct.name}')),
        );
      }
    } else {
      // Product not found, offer to add
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.barcode} "$code" ${l10n.noData}'),
            action: SnackBarAction(
              label: l10n.add.toUpperCase(),
              onPressed: () =>
                  context.push('${AppRoutes.products}?barcode=$code'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // l10n is declared in each sub-layout method
    final cart = ref.watch(cartProvider);
    final productsAsync = ref.watch(productsProvider);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // At narrow tablet (< 768px), the 320px cart panel leaves too little
    // space for product cards. Use mobile layout instead.
    final useTabletLayout = isTablet && screenWidth >= 768;
    final useMobileLayout = !isDesktop && !useTabletLayout;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // Dismiss keyboard on back press
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: isDesktop
                  ? const PosWebScreen()
                  : useTabletLayout
                  ? _buildTabletLayout(productsAsync, cart)
                  : _buildMobileLayout(productsAsync, cart),
            ),
            // Onboarding checklist overlay on desktop / tablet
            if (isDesktop || useTabletLayout)
              const Positioned(
                top: 16,
                right: 16,
                child: OnboardingChecklist(),
              ),
          ],
        ),
        // Mobile + narrow tablet: sticky cart bar at bottom
        bottomNavigationBar: useMobileLayout && cart.isNotEmpty
            ? _MobileCartBar(
                itemCount: cart.itemCount,
                total: cart.total,
                onTap: _showCartSheet,
                onPay: _showPaymentModal,
              )
            : null,
      ),
    );
  }

  Widget _buildTabletLayout(
    AsyncValue<List<ProductModel>> productsAsync,
    CartState cart,
  ) {
    final l10n = context.l10n;

    return Row(
      children: [
        // Products section (60%)
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final filtered = _filterProducts(products);
                    final spacing = ResponsiveHelper.spacing(context);
                    final cols = ResponsiveHelper.gridColumns(context);
                    return GridView.builder(
                      padding: EdgeInsets.all(
                        ResponsiveHelper.pagePadding(context),
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: 0.7,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _buildProductCard(product);
                      },
                    );
                  },
                  loading: () => const LoadingIndicator(),
                  error: (error, _) => ErrorState(
                    message: l10n.somethingWentWrong,
                    onRetry: () => ref.invalidate(productsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Cart section (40%)
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined),
                    const SizedBox(width: 8),
                    Text(
                      'Cart (${cart.itemCount})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (cart.isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            ref.read(cartProvider.notifier).clearCart(),
                        child: Text(l10n.clear),
                      ),
                  ],
                ),
              ),
              // Cart items
              Expanded(
                child: cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.emptyCart,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          Formatters.currency(item.price),
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Semantics(
                                        label:
                                            'Decrease quantity of ${item.name}',
                                        button: true,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20,
                                          ),
                                          onPressed: () => ref
                                              .read(cartProvider.notifier)
                                              .decrementQuantity(
                                                item.productId,
                                              ),
                                        ),
                                      ),
                                      Semantics(
                                        label: 'Quantity: ${item.quantity}',
                                        child: Text('${item.quantity}'),
                                      ),
                                      Semantics(
                                        label:
                                            'Increase quantity of ${item.name}',
                                        button: true,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 20,
                                          ),
                                          onPressed: () => ref
                                              .read(cartProvider.notifier)
                                              .incrementQuantity(
                                                item.productId,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Footer with total and pay button
              if (cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.total,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            Formatters.currency(cart.total),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: ResponsiveHelper.buttonHeight(context),
                        child: Semantics(
                          label: 'Pay ${Formatters.currency(cart.total)}',
                          button: true,
                          child: ElevatedButton.icon(
                            onPressed: _showPaymentModal,
                            icon: const Icon(Icons.payment),
                            label: Text(l10n.pay.toUpperCase()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Semantics(
      label:
          '${product.name}, ${Formatters.currency(product.price)}'
          '${product.isOutOfStock ? ', out of stock' : ''}'
          '${product.isLowStock ? ', low stock' : ''}',
      button: true,
      hint: 'Double tap to add to cart',
      child: Opacity(
        opacity: product.isAvailable ? 1.0 : 0.45,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => ref.read(cartProvider.notifier).addProduct(product),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: product.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, url, error) => const Center(
                                  child: Icon(Icons.broken_image_outlined, size: 40),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.inventory_2_outlined, size: 40),
                              ),
                      ),
                      // Dietary badge
                      if (product.dietaryTag != DietaryTag.none)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: product.dietaryTag == DietaryTag.veg || product.dietaryTag == DietaryTag.jain
                                    ? Colors.green
                                    : (product.dietaryTag == DietaryTag.egg ? Colors.orange : Colors.red),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.white,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: product.dietaryTag == DietaryTag.veg || product.dietaryTag == DietaryTag.jain
                                    ? Colors.green
                                    : (product.dietaryTag == DietaryTag.egg ? Colors.orange : Colors.red),
                              ),
                            ),
                          ),
                        ),
                      // Special badge
                      if (product.isSpecial)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: Text('\u2b50', style: TextStyle(fontSize: 14)),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.currency(product.price),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    AsyncValue<List<ProductModel>> productsAsync,
    CartState cart,
  ) {
    final l10n = context.l10n;

    return Column(
      children: [
        // Search bar
        _buildSearchBar(),

        // Products only (cart is now in sticky bottom bar)
        Expanded(
          child: productsAsync.when(
            data: (products) {
              final filtered = _filterProducts(products);
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  80,
                ), // 80 for cart bar
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final product = filtered[index];
                  return _buildMobileProductCard(product);
                },
              );
            },
            loading: () => const LoadingIndicator(),
            error: (error, _) => ErrorState(
              message: l10n.somethingWentWrong,
              onRetry: () => ref.invalidate(productsProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileProductCard(ProductModel product) {
    return Semantics(
      label:
          '${product.name}, ${Formatters.currency(product.price)}'
          '${product.isOutOfStock ? ', out of stock' : ''}'
          '${product.isLowStock ? ', low stock' : ''}',
      button: true,
      hint: 'Double tap to add to cart',
      child: Opacity(
        opacity: product.isAvailable ? 1.0 : 0.45,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            onTap: () => ref.read(cartProvider.notifier).addProduct(product),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product image with badges
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: product.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, url, error) => const Center(
                                  child: Icon(Icons.broken_image_outlined, size: 32),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.inventory_2_outlined, size: 32),
                              ),
                      ),
                      // Dietary badge (top-left)
                      if (product.dietaryTag != DietaryTag.none)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: product.dietaryTag == DietaryTag.veg || product.dietaryTag == DietaryTag.jain
                                    ? Colors.green
                                    : (product.dietaryTag == DietaryTag.egg ? Colors.orange : Colors.red),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.white,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.circle,
                                size: 7,
                                color: product.dietaryTag == DietaryTag.veg || product.dietaryTag == DietaryTag.jain
                                    ? Colors.green
                                    : (product.dietaryTag == DietaryTag.egg ? Colors.orange : Colors.red),
                              ),
                            ),
                          ),
                        ),
                      // Special badge (top-right)
                      if (product.isSpecial)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Text('\u2b50', style: TextStyle(fontSize: 14)),
                        ),
                    ],
                  ),
                ),
                // Content - compact with text truncation
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                Formatters.currency(product.price),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.add,
                                color: Theme.of(context).colorScheme.primary,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: l10n.searchProducts,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSpecialsSheet(context),
                  icon: const Icon(Icons.star, size: 18),
                  label: const Text('Specials'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCombosSheet(context),
                  icon: const Icon(Icons.lunch_dining, size: 18),
                  label: const Text('Combos'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSpecialsSheet(BuildContext context) {
    final productsAsync = ref.read(productsProvider);
    final specials = productsAsync.valueOrNull
            ?.where((p) => p.isSpecial && p.isAvailable)
            .toList() ??
        [];

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        if (specials.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No specials available')),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: specials.length,
          itemBuilder: (ctx, index) {
            final product = specials[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  product.dietaryTag.emoji.isNotEmpty
                      ? product.dietaryTag.emoji
                      : '⭐',
                ),
              ),
              title: Text(product.name),
              subtitle: Text('₹${product.price.toStringAsFixed(0)}'),
              trailing: const Icon(Icons.add_circle_outline),
              onTap: () {
                ref.read(cartProvider.notifier).addProduct(product);
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  void _showCombosSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final combosAsync = ref.watch(availableCombosProvider);
            return combosAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SizedBox(
                height: 200,
                child: Center(child: Text('Error: $e')),
              ),
              data: (combos) {
                if (combos.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('No combos available')),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: combos.length,
                  itemBuilder: (context, index) {
                    final combo = combos[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          combo.dietaryTag.emoji.isNotEmpty
                              ? combo.dietaryTag.emoji
                              : '🍽️',
                        ),
                      ),
                      title: Text(combo.name),
                      subtitle: Text(
                        '${combo.items.length} items • ₹${combo.price.toStringAsFixed(0)}',
                      ),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () {
                        final cartItem = CartItem(
                          productId: combo.id,
                          name: combo.name,
                          price: combo.price,
                          quantity: 1,
                          unit: 'combo',
                        );
                        ref.read(cartProvider.notifier).addCartItem(cartItem);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    // Filter out unavailable products first
    final filtered = products.where((p) => p.isAvailable).toList();
    if (_searchQuery.isEmpty) return filtered;
    return filtered.where((p) {
      return p.name.toLowerCase().contains(_searchQuery) ||
          (p.barcode?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }
}

// ============ MOBILE CART BAR ============
class _MobileCartBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onTap;
  final VoidCallback onPay;

  const _MobileCartBar({
    required this.itemCount,
    required this.total,
    required this.onTap,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cart info - tappable to expand
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CART ($itemCount items)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              Formatters.currency(total),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Pay button
            ElevatedButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('PAY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponPickerSheet extends StatelessWidget {
  final List<CouponModel> coupons;
  const _CouponPickerSheet({required this.coupons});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select Coupon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final c = coupons[index];
              final label = c.type == CouponType.percentage
                  ? '${c.value.toStringAsFixed(0)}% off'
                  : '₹${c.value.toStringAsFixed(0)} off';
              return ListTile(
                leading: CircleAvatar(
                  child: Text(c.type == CouponType.percentage ? '%' : '₹'),
                ),
                title: Text(
                  c.code,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$label • Used ${c.usedCount}/${c.maxUses ?? '∞'}',
                ),
                onTap: () => Navigator.pop(context, c),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
