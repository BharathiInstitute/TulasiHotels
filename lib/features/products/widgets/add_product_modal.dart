/// Add/Edit product modal
library;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/design/design_system.dart';
import 'package:tulasihotels/core/services/image_service.dart';
import 'package:tulasihotels/core/services/barcode_scanner_service.dart';
import 'package:tulasihotels/core/services/barcode_lookup_service.dart';
import 'package:tulasihotels/core/utils/validators.dart';
import 'package:tulasihotels/core/services/user_metrics_service.dart';
import 'package:tulasihotels/features/products/providers/products_provider.dart';
import 'package:tulasihotels/models/product_model.dart';
import 'package:tulasihotels/shared/widgets/app_button.dart';
import 'package:tulasihotels/shared/widgets/app_text_field.dart';
import 'package:tulasihotels/shared/widgets/upgrade_prompt_modal.dart';

class AddProductModal extends ConsumerStatefulWidget {
  final ProductModel? product;

  const AddProductModal({super.key, this.product});

  @override
  ConsumerState<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends ConsumerState<AddProductModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _lowStockController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descEnController;
  late final TextEditingController _descHiController;
  late final TextEditingController _descTeController;
  late final TextEditingController _priceTakeawayController;
  late final TextEditingController _priceDeliveryController;
  late final TextEditingController _kitchenStationController;
  late final TextEditingController _hsnCodeController;
  late final TextEditingController _gstRateController;
  late ProductUnit _selectedUnit;
  DietaryTag? _dietaryTag;
  SpiceLevel? _spiceLevel;
  List<String> _allergens = [];
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isLookingUp = false;
  bool _isUploadingImage = false;
  BarcodeProduct? _lookedUpProduct;
  String? _imageUrl;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(text: p?.price.toString() ?? '');
    _purchasePriceController = TextEditingController(
      text: p?.purchasePrice?.toString() ?? '',
    );
    _stockController = TextEditingController(text: p?.stock.toString() ?? '0');
    _lowStockController = TextEditingController(
      text: p?.lowStockAlert.toString() ?? '5',
    );
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _descEnController = TextEditingController(text: p?.descriptionEn ?? '');
    _descHiController = TextEditingController(text: p?.descriptionHi ?? '');
    _descTeController = TextEditingController(text: p?.descriptionTe ?? '');
    _priceTakeawayController = TextEditingController(
      text: p?.priceTakeaway?.toString() ?? '',
    );
    _priceDeliveryController = TextEditingController(
      text: p?.priceDelivery?.toString() ?? '',
    );
    _kitchenStationController = TextEditingController(
      text: p?.kitchenStation ?? '',
    );
    _hsnCodeController = TextEditingController(text: p?.hsnCode ?? '');
    _gstRateController = TextEditingController(
      text: p?.gstRate?.toString() ?? '',
    );
    _selectedUnit = p?.unit ?? ProductUnit.piece;
    _dietaryTag = p?.dietaryTag;
    _spiceLevel = p?.spiceLevel;
    _allergens = List<String>.from(p?.allergens ?? []);
    _isAvailable = p?.isAvailable ?? true;
    _imageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _descEnController.dispose();
    _descHiController.dispose();
    _descTeController.dispose();
    _priceTakeawayController.dispose();
    _priceDeliveryController.dispose();
    _kitchenStationController.dispose();
    _hsnCodeController.dispose();
    _gstRateController.dispose();
    super.dispose();
  }

  /// Scan barcode and lookup product info from API
  Future<void> _scanAndLookupBarcode() async {
    final code = await BarcodeScannerService.scanBarcode(context);
    if (code == null || !mounted) return;

    _barcodeController.text = code;
    setState(() => _isLookingUp = true);

    try {
      final product = await BarcodeLookupService.lookupBarcode(code);
      if (product != null && mounted) {
        setState(() {
          _lookedUpProduct = product;
          // Auto-fill name if empty
          if (_nameController.text.isEmpty) {
            _nameController.text = product.displayName;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found: ${product.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product not found in database'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      debugPrint('Barcode lookup error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLookingUp = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final product = ProductModel(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0,
        purchasePrice: _purchasePriceController.text.isEmpty
            ? null
            : double.tryParse(_purchasePriceController.text),
        stock: int.tryParse(_stockController.text) ?? 0,
        lowStockAlert: int.tryParse(_lowStockController.text) ?? 5,
        unit: _selectedUnit,
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        imageUrl: _imageUrl,
        isAvailable: _isAvailable,
        dietaryTag: _dietaryTag ?? DietaryTag.none,
        spiceLevel: _spiceLevel ?? SpiceLevel.na,
        allergens: _allergens,
        descriptionEn: _descEnController.text.trim().isEmpty
            ? null
            : _descEnController.text.trim(),
        descriptionHi: _descHiController.text.trim().isEmpty
            ? null
            : _descHiController.text.trim(),
        descriptionTe: _descTeController.text.trim().isEmpty
            ? null
            : _descTeController.text.trim(),
        priceTakeaway: _priceTakeawayController.text.isEmpty
            ? null
            : double.tryParse(_priceTakeawayController.text),
        priceDelivery: _priceDeliveryController.text.isEmpty
            ? null
            : double.tryParse(_priceDeliveryController.text),
        kitchenStation: _kitchenStationController.text.trim().isEmpty
            ? null
            : _kitchenStationController.text.trim(),
        hsnCode: _hsnCodeController.text.trim().isEmpty
            ? null
            : _hsnCodeController.text.trim(),
        gstRate: _gstRateController.text.isEmpty
            ? null
            : double.tryParse(_gstRateController.text),
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      final service = ref.read(productsServiceProvider);
      if (_isEditing) {
        await service.updateProduct(product);
      } else {
        // Check product limit before adding
        final limits = await UserMetricsService.getUserLimits();
        if (!limits.canAddProduct) {
          if (mounted) {
            setState(() => _isLoading = false);
            unawaited(
              UpgradePromptModal.show(
                context,
                trigger: UpgradeTrigger.productLimit,
              ),
            );
          }
          return;
        }
        await service.addProduct(product);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Product updated' : 'Product added'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final isLimitError =
            errorStr.contains('permission-denied') ||
            errorStr.contains('permission_denied') ||
            errorStr.contains('missing or insufficient permissions');

        if (isLimitError) {
          unawaited(
            UpgradePromptModal.show(
              context,
              trigger: UpgradeTrigger.productLimit,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item?'),
        content: const Text(
          'This menu item may appear in existing bills. '
          'Deleting it won\'t remove it from past bills, but it will '
          'no longer be available for new orders.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final service = ref.read(productsServiceProvider);
    await service.deleteProduct(widget.product!.id);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final fieldSpacing = isMobile ? 10.0 : 16.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isEditing ? Icons.edit : Icons.restaurant_menu,
                  color: AppColors.primary,
                  size: isMobile ? 20 : 24,
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  _isEditing ? 'Edit Menu Item' : 'Add Menu Item',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: isMobile ? 16 : 20,
                  ),
                ),
                const Spacer(),
                if (_isEditing)
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: AppColors.error,
                      size: isMobile ? 20 : 24,
                    ),
                    onPressed: _delete,
                    padding: EdgeInsets.all(isMobile ? 4 : 8),
                    constraints: isMobile ? const BoxConstraints() : null,
                  ),
                IconButton(
                  icon: Icon(Icons.close, size: isMobile ? 20 : 24),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.all(isMobile ? 4 : 8),
                  constraints: isMobile ? const BoxConstraints() : null,
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: ResponsiveHelper.modalPadding(context),
                right: ResponsiveHelper.modalPadding(context),
                top: isMobile ? 12 : ResponsiveHelper.modalPadding(context),
                bottom: MediaQuery.of(context).viewInsets.bottom + 100,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    AppTextField(
                      label: 'Item Name *',
                      hint: 'e.g., Chicken Biryani, Masala Dosa',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.restaurant_menu_outlined),
                      validator: (v) => Validators.name(v, 'Item name'),
                    ),
                    SizedBox(height: fieldSpacing),

                    // Category
                    AppTextField(
                      label: 'Category',
                      hint: 'e.g., Starters, Main Course, Beverages',
                      controller: _categoryController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    SizedBox(height: fieldSpacing),

                    // Availability toggle
                    SwitchListTile(
                      title: const Text('Available'),
                      subtitle: const Text('Show this item on the menu'),
                      value: _isAvailable,
                      onChanged: (v) => setState(() => _isAvailable = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SizedBox(height: fieldSpacing),

                    // Dietary tag & Spice level
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<DietaryTag?>(
                            initialValue: _dietaryTag,
                            decoration: const InputDecoration(
                              labelText: 'Diet Type',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(child: Text('None')),
                              ...DietaryTag.values.map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text('${t.emoji} ${t.displayName}'),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _dietaryTag = v),
                          ),
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: DropdownButtonFormField<SpiceLevel?>(
                            initialValue: _spiceLevel,
                            decoration: const InputDecoration(
                              labelText: 'Spice Level',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(child: Text('None')),
                              ...SpiceLevel.values.map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text('${s.emoji} ${s.displayName}'),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _spiceLevel = v),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: fieldSpacing),

                    // Allergens
                    Text(
                      'Allergens',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: isMobile ? 4 : 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        'Gluten', 'Dairy', 'Nuts', 'Eggs', 'Soy',
                        'Shellfish', 'Fish', 'Sesame',
                      ].map((allergen) {
                        final selected = _allergens.contains(allergen);
                        return FilterChip(
                          label: Text(allergen, style: TextStyle(fontSize: isMobile ? 11 : 13)),
                          selected: selected,
                          visualDensity: VisualDensity.compact,
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _allergens.add(allergen);
                              } else {
                                _allergens.remove(allergen);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: fieldSpacing),

                    // Descriptions (collapsible)
                    ExpansionTile(
                      title: const Text('Descriptions (Multi-language)'),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      children: [
                        AppTextField(
                          label: 'Description (English)',
                          controller: _descEnController,
                          maxLines: 2,
                        ),
                        SizedBox(height: fieldSpacing),
                        AppTextField(
                          label: 'Description (Hindi)',
                          controller: _descHiController,
                          maxLines: 2,
                        ),
                        SizedBox(height: fieldSpacing),
                        AppTextField(
                          label: 'Description (Telugu)',
                          controller: _descTeController,
                          maxLines: 2,
                        ),
                        SizedBox(height: fieldSpacing),
                      ],
                    ),
                    SizedBox(height: fieldSpacing),

                    Row(
                      children: [
                        Expanded(
                          child: CurrencyTextField(
                            label: 'Selling Price *',
                            controller: _priceController,
                          ),
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: CurrencyTextField(
                            label: 'Cost Price',
                            controller: _purchasePriceController,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: fieldSpacing),

                    // Multi-price fields (collapsible)
                    ExpansionTile(
                      title: const Text('Alternate Prices'),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CurrencyTextField(
                                label: 'Takeaway Price',
                                controller: _priceTakeawayController,
                              ),
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Expanded(
                              child: CurrencyTextField(
                                label: 'Delivery Price',
                                controller: _priceDeliveryController,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: fieldSpacing),
                      ],
                    ),
                    SizedBox(height: fieldSpacing),

                    // Kitchen station & GST (collapsible)
                    ExpansionTile(
                      title: const Text('Kitchen & Tax'),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      children: [
                        AppTextField(
                          label: 'Kitchen Station',
                          hint: 'e.g., Main Kitchen, Tandoor, Bar',
                          controller: _kitchenStationController,
                          prefixIcon: const Icon(Icons.kitchen),
                        ),
                        SizedBox(height: fieldSpacing),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'HSN Code',
                                hint: '9963',
                                controller: _hsnCodeController,
                              ),
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Expanded(
                              child: AppTextField(
                                label: 'GST Rate (%)',
                                hint: '5',
                                controller: _gstRateController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: fieldSpacing),
                      ],
                    ),
                    SizedBox(height: fieldSpacing),

                    // Stock & Low stock
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Current Stock *',
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) =>
                                Validators.positiveNumber(v, 'Stock'),
                          ),
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Low Stock Alert',
                            controller: _lowStockController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: fieldSpacing),

                    // Unit selection
                    Text(
                      'Unit',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: isMobile ? 4 : 8),
                    Wrap(
                      spacing: isMobile ? 4 : 8,
                      runSpacing: isMobile ? 4 : 8,
                      children: ProductUnit.values.map((unit) {
                        final isSelected = _selectedUnit == unit;
                        return ChoiceChip(
                          label: Text(
                            unit.displayName,
                            style: TextStyle(fontSize: isMobile ? 11 : 14),
                          ),
                          selected: isSelected,
                          visualDensity: isMobile
                              ? VisualDensity.compact
                              : null,
                          padding: isMobile
                              ? const EdgeInsets.symmetric(horizontal: 4)
                              : null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedUnit = unit);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: fieldSpacing),

                    // Barcode
                    AppTextField(
                      label: 'Barcode (Optional)',
                      hint: 'Scan or enter barcode',
                      controller: _barcodeController,
                      prefixIcon: const Icon(Icons.qr_code),
                      suffixIcon: _isLookingUp
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: _scanAndLookupBarcode,
                            ),
                    ),

                    // Show looked up product info
                    if (_lookedUpProduct != null) ...[
                      SizedBox(height: isMobile ? 6 : 8),
                      Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: isMobile ? 16 : 20,
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Found: ${_lookedUpProduct!.displayName}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 12 : 14,
                                    ),
                                  ),
                                  if (_lookedUpProduct!.brand != null)
                                    Text(
                                      'Brand: ${_lookedUpProduct!.brand}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 10 : 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: fieldSpacing),

                    // Product Image
                    Text(
                      'Product Image',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: _isUploadingImage
                          ? const Center(child: CircularProgressIndicator())
                          : _imageUrl != null && _imageUrl!.isNotEmpty
                          ? Stack(
                              children: [
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: _imageUrl!,
                                      height: 120,
                                      fit: BoxFit.contain,
                                      errorWidget: (_, url, error) =>
                                          const Icon(
                                            Icons.broken_image,
                                            size: 40,
                                          ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton.filled(
                                    onPressed: () {
                                      setState(() => _imageUrl = null);
                                    },
                                    icon: const Icon(Icons.close, size: 16),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(4),
                                      minimumSize: const Size(28, 28),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : InkWell(
                              onTap: () async {
                                setState(() => _isUploadingImage = true);
                                try {
                                  final url =
                                      await ImageService.pickAndUploadProductImage();
                                  if (url != null && context.mounted) {
                                    setState(() => _imageUrl = url);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ Image uploaded'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Image upload failed: $e',
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isUploadingImage = false);
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 32,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to upload image',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    SizedBox(height: isMobile ? 16 : 32),

                    // Submit button
                    AppButton(
                      label: _isEditing ? '✅ UPDATE PRODUCT' : '✅ ADD PRODUCT',
                      onPressed: _submit,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
