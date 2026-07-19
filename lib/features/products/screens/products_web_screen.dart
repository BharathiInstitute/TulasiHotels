import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/core/design/design_system.dart';
import 'package:tulasihotels/router/app_router.dart';
import 'package:tulasihotels/core/services/product_csv_service.dart';
import 'package:tulasihotels/core/services/user_metrics_service.dart';
import 'package:tulasihotels/core/utils/formatters.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/products/providers/products_provider.dart';
import 'package:tulasihotels/features/products/widgets/add_product_modal.dart';
import 'package:tulasihotels/l10n/app_localizations.dart';
import 'package:tulasihotels/models/product_model.dart';
import 'package:tulasihotels/shared/widgets/loading_states.dart';
import 'package:tulasihotels/shared/widgets/web_safe_image.dart';
import 'package:tulasihotels/shared/widgets/sync_badge.dart';
import 'package:tulasihotels/shared/widgets/upgrade_prompt_modal.dart';
import 'package:tulasihotels/features/subscription/services/plan_enforcement_service.dart';
import 'package:tulasihotels/features/subscription/providers/usage_limits_provider.dart';
import 'package:tulasihotels/features/subscription/providers/subscription_provider.dart';
import 'package:tulasihotels/features/subscription/widgets/plan_usage_bar.dart';

class ProductsWebScreen extends ConsumerStatefulWidget {
  const ProductsWebScreen({super.key});

  @override
  ConsumerState<ProductsWebScreen> createState() => _ProductsWebScreenState();
}

class _ProductsWebScreenState extends ConsumerState<ProductsWebScreen> {
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final productsAsync = ref.watch(productsProvider);
    final syncStatus = ref.watch(productsSyncStatusProvider).valueOrNull ?? {};
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final limits = ref.watch(currentLimitsProvider);
    final config = ref.watch(planConfigProvider);
    final productPermissions = ref.watch(
      routePermissionProvider(AppRoutes.products),
    );
    final canCreateProducts = productPermissions.canCreate;
    final canUpdateProducts = productPermissions.canUpdate;
    final atProductLimit = (config.maxProducts != null) &&
        (config.maxProducts! < 999999) &&
        limits.productsCount >= config.maxProducts!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Usage bar — only visible when approaching/at limit
          PlanUsageBar(
            label: 'Products',
            getCurrent: (l) => l.productsCount,
            getLimit: (c) => c.productsLimitFirestore,
          ),
          Expanded(
        child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : (isTablet ? 16.0 : 16.0)),
        child: Column(
          children: [
            // Top Bar: Search + Actions
            if (isMobile) ...[
              // Mobile: Stacked layout
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Theme.of(context).cardColor,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() {
                  _searchQuery = value.toLowerCase();
                  _currentPage = 0;
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleExportCsv(),
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Export'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canCreateProducts ? () => _handleImportCsv() : null,
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text('Import'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: atProductLimit || !canCreateProducts
                          ? null
                          : () => _showAddProductModal(),
                      icon: Icon(atProductLimit ? Icons.lock_outline : Icons.add, size: 18),
                      label: Text(atProductLimit
                          ? '${limits.productsCount}/${config.maxProducts ?? "∞"}'
                          : l10n.addProduct),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Desktop: Original single row
              Row(
                children: [
                  // Search Input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by item name, SKU, or category...',
                          prefixIcon: const Icon(Icons.search),
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) => setState(() {
                          _searchQuery = value.toLowerCase();
                          _currentPage = 0;
                        }),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // View toggle
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ViewToggleButton(
                          icon: Icons.table_rows_outlined,
                          isSelected: !_isGridView,
                          onTap: () => setState(() => _isGridView = false),
                        ),
                        _ViewToggleButton(
                          icon: Icons.grid_view_outlined,
                          isSelected: _isGridView,
                          onTap: () => setState(() => _isGridView = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Actions
                  OutlinedButton.icon(
                    onPressed: () => _handleExportCsv(),
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Export CSV'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: canCreateProducts ? () => _handleImportCsv() : null,
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Import CSV'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: atProductLimit || !canCreateProducts
                        ? null
                        : () => _showAddProductModal(),
                    icon: Icon(atProductLimit ? Icons.lock_outline : Icons.add),
                    label: Text(atProductLimit
                        ? 'Limit reached (${limits.productsCount}/${config.maxProducts ?? "∞"})'
                        : l10n.addProduct),
                  ),
                ],
              ),
            ],
            // Quick-action chips for menu sub-features
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 0 : 4,
                vertical: 8,
              ),
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.lunch_dining, size: 18),
                    label: const Text('Combos'),
                    onPressed: () => context.push(AppRoutes.combos),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Daily Specials'),
                    onPressed: () => context.push(AppRoutes.dailySpecials),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.inventory_2, size: 18),
                    label: const Text('Ingredients'),
                    onPressed: () => context.push(AppRoutes.ingredients),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 4 : 8),

            // Main Content: Data Table Card
            Expanded(
              child: Card(
                child: productsAsync.when(
                  data: (products) {
                    final filtered = _filterProducts(products);
                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.restaurant_menu_outlined,
                        title: l10n.noProducts,
                        subtitle: _searchQuery.isEmpty
                            ? l10n.addFirstProduct
                            : l10n.noData,
                        actionLabel: _searchQuery.isEmpty && canCreateProducts
                            ? l10n.addProduct
                            : null,
                        onAction: _searchQuery.isEmpty && canCreateProducts
                            ? () => _showAddProductModal()
                            : null,
                      );
                    }
                    final totalPages = (filtered.length / _pageSize).ceil();
                    if (_currentPage >= totalPages && totalPages > 0) {
                      _currentPage = totalPages - 1;
                    }
                    final startIndex = _currentPage * _pageSize;
                    final endIndex = (startIndex + _pageSize).clamp(
                      0,
                      filtered.length,
                    );
                    final pageItems = filtered.sublist(startIndex, endIndex);
                    final hasPrev = _currentPage > 0;
                    final hasNext = _currentPage < totalPages - 1;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isMobile) ...[
                          // Mobile: Card-based list
                          Expanded(
                            child: ListView.separated(
                              itemCount: pageItems.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final product = pageItems[index];
                                return _MobileProductCard(
                                  product: product,
                                  hasPendingWrites:
                                      syncStatus[product.id] ?? false,
                                  canEdit: canUpdateProducts,
                                  onEdit: canUpdateProducts
                                      ? () =>
                                          _showAddProductModal(product: product)
                                      : null,
                                );
                              },
                            ),
                          ),
                          // Mobile pagination footer
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${startIndex + 1}-$endIndex of ${filtered.length}',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: hasPrev
                                          ? () => setState(() => _currentPage--)
                                          : null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text(
                                        'Prev',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: hasNext
                                          ? () => setState(() => _currentPage++)
                                          : null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text(
                                        'Next',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Desktop: DataTable or GridView
                          Expanded(
                            child: _isGridView
                                ? _buildGridView(
                                    pageItems,
                                    syncStatus,
                                    canUpdateProducts,
                                  )
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.all(0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: DataTable(
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                            ),
                                        headingRowHeight: 44,
                                        dataRowMinHeight: 48,
                                        dataRowMaxHeight: 56,
                                        horizontalMargin: 16,
                                        columnSpacing: 16,
                                        columns: [
                                          DataColumn(
                                            label: Text(
                                              'Item Name',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'SKU',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Category',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Stock Level',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Price',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Actions',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            numeric: true,
                                          ),
                                        ],
                                        rows: pageItems.map((product) {
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(
                                                          context,
                                                        ).scaffoldBackgroundColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: product.imageUrl != null &&
                                                              product.imageUrl!.startsWith('http')
                                                          ? ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                              child: WebSafeImage(
                                                                url: product.imageUrl!,
                                                                width: 32,
                                                                height: 32,
                                                                errorWidget: Icon(
                                                                  Icons.image_not_supported_outlined,
                                                                  color: Theme.of(context)
                                                                      .colorScheme
                                                                      .outline,
                                                                  size: 16,
                                                                ),
                                                              ),
                                                            )
                                                          : Icon(
                                                              Icons.image_not_supported_outlined,
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .outline,
                                                              size: 16,
                                                            ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Flexible(
                                                      child: Text(
                                                        product.name,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    SyncBadge(
                                                      hasPendingWrites:
                                                          syncStatus[product
                                                              .id] ??
                                                          false,
                                                    ),
                                                  ],
                                                ),
                                                onTap: canUpdateProducts
                                                    ? () =>
                                                        _showAddProductModal(
                                                          product: product,
                                                        )
                                                    : null,
                                              ),
                                              DataCell(
                                                Text(
                                                  product.barcode ?? 'N/A',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'monospace',
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  product.category ?? '—',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        product.category != null
                                                        ? Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant
                                                        : Theme.of(
                                                            context,
                                                          ).colorScheme.outline,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: product.isOutOfStock
                                                        ? AppColors.error
                                                              .withValues(
                                                                alpha: 0.1,
                                                              )
                                                        : (product.isLowStock
                                                              ? AppColors
                                                                    .warning
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    )
                                                              : AppColors
                                                                    .success
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    )),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    product.isOutOfStock
                                                        ? 'Out of stock'
                                                        : (product.isLowStock
                                                              ? '${product.stock} (Low)'
                                                              : '${product.stock} in stock'),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          product.isOutOfStock
                                                          ? AppColors.error
                                                          : (product.isLowStock
                                                                ? AppColors
                                                                      .warning
                                                                : AppColors
                                                                      .success),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  product.price.asCurrency,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                  ),
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  onPressed: canUpdateProducts
                                                      ? () =>
                                                          _showAddProductModal(
                                                            product: product,
                                                          )
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                          ),
                          // Desktop pagination footer
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                            decoration: const BoxDecoration(),
                            child: Row(
                              children: [
                                Text(
                                  'Showing ${startIndex + 1} to $endIndex of ${filtered.length} results',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton(
                                  onPressed: hasPrev
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Previous'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: hasNext
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (error, _) => ErrorState(
                    message: l10n.somethingWentWrong,
                    onRetry: () => ref.invalidate(productsProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
    );
  }

  // Logic copied from products_screen.dart
  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var result = products;
    // Simple filter support (only search implemented in UI header for simplicity)
    if (_searchQuery.isNotEmpty) {
      result = result.where((p) {
        return p.name.toLowerCase().contains(_searchQuery) ||
            (p.barcode?.toLowerCase().contains(_searchQuery) ?? false) ||
            (p.category?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
    return result;
  }

  Widget _buildGridView(
    List<ProductModel> pageItems,
    Map<String, bool> syncStatus,
    bool canUpdateProducts,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: pageItems.length,
      itemBuilder: (context, index) {
        final product = pageItems[index];
        final hasPending = syncStatus[product.id] ?? false;
        return _GridProductCard(
          product: product,
          hasPendingWrites: hasPending,
          canEdit: canUpdateProducts,
          onEdit: canUpdateProducts
              ? () => _showAddProductModal(product: product)
              : null,
        );
      },
    );
  }

  Future<void> _showAddProductModal({ProductModel? product}) async {
    final permissions = ref.read(routePermissionProvider(AppRoutes.products));
    final canOpen = product == null
        ? permissions.canCreate
        : permissions.canUpdate;
    if (!canOpen) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              product == null
                  ? 'You do not have permission to add products.'
                  : 'You do not have permission to edit products.',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    // Only enforce limit when adding a new product (not editing)
    if (product == null) {
      final check = await PlanEnforcementService.checkLimit(LimitType.products);
      if (!mounted) return;
      if (!check.allowed) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(check.message ?? 'Upgrade your plan to add more products.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Upgrade',
              textColor: Colors.white,
              onPressed: () => context.push(AppRoutes.subscription),
            ),
          ),
        );
        return;
      }
    }
    unawaited(showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProductModal(product: product),
    ));
  }

  Future<void> _handleExportCsv() async {
    final productsAsync = ref.read(productsProvider);
    final products = productsAsync.valueOrNull;
    if (products == null || products.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No menu items to export'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }
    try {
      final path = await ProductCsvService.exportToDownloads(products);
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Exported ${products.length} menu items to CSV'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleImportCsv() async {
    // Step 1: Pick and parse CSV file
    final CsvImportResult result;
    try {
      result = await ProductCsvService.importProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // User cancelled file picker
    if (result.imported == 0 && result.errors.isEmpty) return;

    // CSV had only errors (missing columns, empty file, etc.)
    if (result.imported == 0 && result.hasErrors) {
      if (mounted) _showImportResultDialog(0, 0, result.skipped, result.errors);
      return;
    }

    // Check product limit before importing
    try {
      final limits = await UserMetricsService.getUserLimits();
      final remaining = limits.productsLimit - limits.productsCount;
      if (result.products.length > remaining) {
        if (mounted) {
          await UpgradePromptModal.show(
            context,
            trigger: UpgradeTrigger.productLimit,
          );
        }
        return;
      }
    } catch (_) {
      // If limits check fails, proceed anyway
    }

    if (!mounted) return;

    // Step 2: Show progress dialog and start batch upload
    final progressNotifier = ValueNotifier<int>(0);
    final total = result.products.length;
    int lastKnownAdded = 0;

    // Start upload immediately (runs in background while dialog is open)
    final service = ref.read(productsServiceProvider);
    final uploadFuture = service.addProductsBatch(
      result.products,
      onProgress: (added, t) {
        lastKnownAdded = added;
        progressNotifier.value = added;
      },
    );

    // Show progress dialog
    if (mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          // Wait for upload to finish, then close dialog
          uploadFuture
              .then((_) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              })
              .catchError((Object _) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              });

          return ValueListenableBuilder<int>(
            valueListenable: progressNotifier,
            builder: (context, addedSoFar, _) {
              final progress = total > 0 ? addedSoFar / total : 0.0;
              return AlertDialog(
                title: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    SizedBox(width: 12),
                    Text('Importing Products...'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 12),
                    Text(
                      '$addedSoFar / $total products uploaded',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (result.skipped > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${result.skipped} rows skipped',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      );
    }

    // Dialog closed — show result
    progressNotifier.dispose();

    try {
      final added = await uploadFuture;
      if (mounted) {
        _showImportResultDialog(added, total, result.skipped, result.errors);
      }
    } catch (e) {
      if (mounted) {
        _showImportResultDialog(lastKnownAdded, total, result.skipped, [
          ...result.errors,
          'Upload failed: $e',
        ]);
      }
    }
  }

  void _showImportResultDialog(
    int added,
    int total,
    int skipped,
    List<String> errors,
  ) {
    final hasErrors = errors.isNotEmpty;
    final allFailed = added == 0 && hasErrors;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          allFailed
              ? Icons.error_outline
              : hasErrors
              ? Icons.warning_amber_rounded
              : Icons.check_circle_outline,
          color: allFailed
              ? AppColors.error
              : hasErrors
              ? AppColors.warning
              : AppColors.success,
          size: 48,
        ),
        title: Text(
          allFailed
              ? 'Import Failed'
              : hasErrors
              ? 'Import Completed with Warnings'
              : 'Import Successful',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (added > 0)
              _resultRow(
                Icons.check,
                '$added products added',
                AppColors.success,
              ),
            if (skipped > 0)
              _resultRow(
                Icons.skip_next,
                '$skipped rows skipped',
                AppColors.warning,
              ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Errors:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final err in errors)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '• $err',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.error),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

/// Mobile-friendly product card for list display
class _MobileProductCard extends StatelessWidget {
  final ProductModel product;
  final bool hasPendingWrites;
  final bool canEdit;
  final VoidCallback? onEdit;

  const _MobileProductCard({
    required this.product,
    this.hasPendingWrites = false,
    required this.canEdit,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: product.isAvailable ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.small,
        ),
        child: InkWell(
          onTap: canEdit ? onEdit : null,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // Dietary badge
              if (product.dietaryTag == DietaryTag.veg ||
                  product.dietaryTag == DietaryTag.nonVeg ||
                  product.dietaryTag == DietaryTag.egg)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.circle,
                    size: 10,
                    color: product.dietaryTag == DietaryTag.veg
                        ? Colors.green
                        : (product.dietaryTag == DietaryTag.egg
                              ? Colors.orange
                              : Colors.red),
                  ),
                ),
              // Product Image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.imageUrl != null &&
                        product.imageUrl!.startsWith('http')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: WebSafeImage(
                          url: product.imageUrl!,
                          width: 48,
                          height: 48,
                          errorWidget: Icon(
                            Icons.image_not_supported_outlined,
                            color: Theme.of(context).colorScheme.outline,
                            size: 20,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported_outlined,
                        color: Theme.of(context).colorScheme.outline,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isSpecial) ...[
                          const SizedBox(width: 4),
                          const Text('⭐', style: TextStyle(fontSize: 12)),
                        ],
                        const SizedBox(width: 4),
                        SyncBadge(hasPendingWrites: hasPendingWrites),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Stock Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: product.isOutOfStock
                                ? AppColors.error.withValues(alpha: 0.1)
                                : (product.isLowStock
                                      ? AppColors.warning.withValues(alpha: 0.1)
                                      : AppColors.success.withValues(
                                          alpha: 0.1,
                                        )),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.isOutOfStock
                                ? 'Out'
                                : (product.isLowStock
                                      ? '${product.stock} low'
                                      : '${product.stock} in stock'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: product.isOutOfStock
                                  ? AppColors.error
                                  : (product.isLowStock
                                        ? AppColors.warning
                                        : AppColors.success),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price and Edit
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.price.asCurrency,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    canEdit ? Icons.edit_outlined : Icons.lock_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle button for switching between table and grid views
class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Grid card for product display
class _GridProductCard extends StatelessWidget {
  final ProductModel product;
  final bool hasPendingWrites;
  final bool canEdit;
  final VoidCallback? onEdit;

  const _GridProductCard({
    required this.product,
    required this.hasPendingWrites,
    required this.canEdit,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: product.isAvailable ? 1.0 : 0.45,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: InkWell(
          onTap: canEdit ? onEdit : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: product.imageUrl != null &&
                              product.imageUrl!.startsWith('http')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: WebSafeImage(
                                url: product.imageUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                errorWidget: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Theme.of(context).colorScheme.outline,
                                  size: 32,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.image_not_supported_outlined,
                              color: Theme.of(context).colorScheme.outline,
                              size: 32,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Name + dietary + special badges
                Row(
                  children: [
                    if (product.dietaryTag == DietaryTag.veg ||
                        product.dietaryTag == DietaryTag.nonVeg ||
                        product.dietaryTag == DietaryTag.egg)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.circle,
                          size: 10,
                          color: product.dietaryTag == DietaryTag.veg
                              ? Colors.green
                              : (product.dietaryTag == DietaryTag.egg
                                    ? Colors.orange
                                    : Colors.red),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.isSpecial)
                      const Text('\u2b50', style: TextStyle(fontSize: 12)),
                    if (hasPendingWrites)
                      SyncBadge(hasPendingWrites: hasPendingWrites),
                  ],
                ),
                const SizedBox(height: 4),
                // Price
                Text(
                  product.price.asCurrency,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                // Stock badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: product.isOutOfStock
                        ? AppColors.error.withValues(alpha: 0.1)
                        : (product.isLowStock
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.isOutOfStock
                        ? 'Out of stock'
                        : (product.isLowStock
                              ? '${product.stock} (Low)'
                              : '${product.stock} in stock'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: product.isOutOfStock
                          ? AppColors.error
                          : (product.isLowStock
                                ? AppColors.warning
                                : AppColors.success),
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
}
