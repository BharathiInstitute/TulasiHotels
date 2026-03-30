/// Order taking screen — waiter creates/views order for a table
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/orders/services/order_service.dart';
import 'package:tulasihotels/features/products/providers/products_provider.dart';
import 'package:tulasihotels/models/order_model.dart';
import 'package:tulasihotels/models/product_model.dart';

/// Screen for creating a new order at a table
class NewOrderScreen extends ConsumerStatefulWidget {
  final String? tableId;
  final String? tableName;

  const NewOrderScreen({super.key, this.tableId, this.tableName});

  @override
  ConsumerState<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends ConsumerState<NewOrderScreen> {
  final List<OrderItem> _items = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _notes;
  OrderType _orderType = OrderType.dineIn;
  bool _isPlacingOrder = false;
  bool _isRush = false;
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    if (widget.tableId == null) {
      _orderType = OrderType.takeaway;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _orderTotal =>
      _items.fold(0.0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tableName != null
              ? 'New Order — ${widget.tableName}'
              : 'New ${_orderType.displayName} Order',
        ),
        actions: [
          if (widget.tableId == null)
            PopupMenuButton<OrderType>(
              icon: const Icon(Icons.restaurant_menu),
              tooltip: 'Order Type',
              onSelected: (type) => setState(() => _orderType = type),
              itemBuilder: (context) => OrderType.values
                  .map(
                    (type) => PopupMenuItem(
                      value: type,
                      child: Text('${type.emoji} ${type.displayName}'),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      body: Row(
        children: [
          // Left: Menu items
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search menu...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),

                // Category filter
                productsAsync.when(
                  data: (products) {
                    final categories = products
                        .map((p) => p.category)
                        .whereType<String>()
                        .toSet()
                        .toList()
                      ..sort();
                    if (categories.isEmpty) return const SizedBox.shrink();

                    return SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _CategoryChip(
                            label: 'All',
                            isSelected: _selectedCategory == null,
                            onTap: () =>
                                setState(() => _selectedCategory = null),
                          ),
                          ...categories.map(
                            (cat) => _CategoryChip(
                              label: cat,
                              isSelected: _selectedCategory == cat,
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 8),

                // Product grid
                Expanded(
                  child: productsAsync.when(
                    data: (products) {
                      var filtered = products.toList();
                      if (_searchQuery.isNotEmpty) {
                        final q = _searchQuery.toLowerCase();
                        filtered = filtered
                            .where((p) =>
                                p.name.toLowerCase().contains(q) ||
                                (p.category?.toLowerCase().contains(q) ??
                                    false))
                            .toList();
                      }
                      if (_selectedCategory != null) {
                        filtered = filtered
                            .where((p) => p.category == _selectedCategory)
                            .toList();
                      }

                      if (filtered.isEmpty) {
                        return const Center(child: Text('No items found'));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _MenuItemCard(
                          product: filtered[index],
                          onAdd: () => _addItem(filtered[index]),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),

          // Right: Order summary
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                left: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Order (${_items.length} items)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Items list
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Text(
                            'Tap menu items to add',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) => _OrderItemTile(
                            item: _items[index],
                            onIncrement: () => _incrementItem(index),
                            onDecrement: () => _decrementItem(index),
                            onRemove: () => _removeItem(index),
                            onNotesChanged: (notes) =>
                                _updateItemNotes(index, notes),
                          ),
                        ),
                ),

                // Rush & VIP toggles
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilterChip(
                          label: const Text('🔥 Rush'),
                          selected: _isRush,
                          onSelected: (v) => setState(() => _isRush = v),
                          selectedColor: Colors.red[100],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilterChip(
                          label: const Text('👑 VIP'),
                          selected: _isVip,
                          onSelected: (v) => setState(() => _isVip = v),
                          selectedColor: Colors.amber[100],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Notes field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Order notes...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _notes = v,
                  ),
                ),
                const SizedBox(height: 8),

                // Total & Place Order
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.05),
                    border: Border(
                      top: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '?${_orderTotal.toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _items.isEmpty || _isPlacingOrder
                                  ? null
                                  : _placeOrder,
                          icon: _isPlacingOrder
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: const Text('Place Order'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addItem(ProductModel product) {
    setState(() {
      final existingIndex =
          _items.indexWhere((i) => i.productId == product.id);
      if (existingIndex >= 0) {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: _items[existingIndex].quantity + 1,
        );
      } else {
        _items.add(OrderItem(
          productId: product.id,
          name: product.name,
          price: product.price,
          quantity: 1,
          unit: product.unit.shortName,
        ));
      }
    });
  }

  void _incrementItem(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
    });
  }

  void _decrementItem(int index) {
    setState(() {
      if (_items[index].quantity > 1) {
        _items[index] = _items[index].copyWith(
          quantity: _items[index].quantity - 1,
        );
      } else {
        _items.removeAt(index);
      }
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _updateItemNotes(int index, String notes) {
    setState(() {
      _items[index] = _items[index].copyWith(
        itemNotes: notes.isEmpty ? null : notes,
      );
    });
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);
    try {
      await OrderService.createOrder(
        items: _items,
        orderType: _orderType,
        tableId: widget.tableId,
        tableName: widget.tableName,
        notes: _notes,
        isRush: _isRush,
        isVip: _isVip,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order placed for ${widget.tableName ?? _orderType.displayName}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }
}

/// Category filter chip
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Menu item card in the grid
class _MenuItemCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const _MenuItemCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '?${product.price.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (product.category != null)
                    Text(
                      product.category!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                      ),
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

/// Order item tile in the summary panel
class _OrderItemTile extends StatelessWidget {
  final OrderItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final ValueChanged<String> onNotesChanged;

  const _OrderItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: ListTile(
        dense: true,
        title: Text(
          item.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '?${item.price.toStringAsFixed(0)} × ${item.quantity} = ?${item.total.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall,
            ),
            if (item.itemNotes != null)
              Text(
                item.itemNotes!,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: onDecrement,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              '${item.quantity}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: onIncrement,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        onLongPress: () {
          _showNotesDialog(context);
        },
      ),
    );
  }

  void _showNotesDialog(BuildContext context) {
    final controller = TextEditingController(text: item.itemNotes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notes for ${item.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., no onion, extra spicy',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onNotesChanged(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
