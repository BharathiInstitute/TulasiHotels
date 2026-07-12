/// Add/Edit product modal
library;

import 'dart:async';

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
  late final TextEditingController _descEnController;
  late final TextEditingController _descHiController;
  late final TextEditingController _descTeController;
  late final TextEditingController _gstRateController;
  late final TextEditingController _discountController;
  String? _selectedCategory;
  DietaryTag? _dietaryTag;
  SpiceLevel? _spiceLevel;
  List<String> _allergens = [];
  bool _isAvailable = true;
  bool _isLoading = false;
  // ignore: unused_field
  bool _isLookingUp = false;
  bool _isUploadingImage = false;
  // ignore: unused_field
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
    _selectedCategory = p?.category;
    _descEnController = TextEditingController(text: p?.descriptionEn ?? '');
    _descHiController = TextEditingController(text: p?.descriptionHi ?? '');
    _descTeController = TextEditingController(text: p?.descriptionTe ?? '');
    _gstRateController = TextEditingController(
      text: p?.gstRate?.toString() ?? '',
    );
    _discountController = TextEditingController(
      text: p?.discount?.toString() ?? '',
    );
    _dietaryTag = p?.dietaryTag;
    _spiceLevel = p?.spiceLevel;
    _allergens = List<String>.from(p?.allergens ?? []);
    _isAvailable = p?.isAvailable ?? true;
    // Only use imageUrl if it's a valid HTTPS URL — local paths from mobile don't work on web
    final rawImageUrl = p?.imageUrl;
    _imageUrl = (rawImageUrl != null && rawImageUrl.startsWith('http'))
        ? rawImageUrl
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    _barcodeController.dispose();
    _descEnController.dispose();
    _descHiController.dispose();
    _descTeController.dispose();
    _gstRateController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g., Main Course'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _selectedCategory = result);
    }
  }

  /// Scan barcode and lookup product info from API
  // ignore: unused_element
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
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        category: (_selectedCategory ?? '').trim().isEmpty
            ? null
            : _selectedCategory!.trim(),
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
        gstRate: _gstRateController.text.isEmpty
            ? null
            : double.tryParse(_gstRateController.text),
        discount: _discountController.text.isEmpty
            ? null
            : double.tryParse(_discountController.text),
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      final service = ref.read(productsServiceProvider);
      if (_isEditing) {
        await service.updateProduct(product);
      } else {
        // addProduct() already calls PlanEnforcementService.checkLimit() which
        // handles offline correctly (returns allowed when offline).
        // Do NOT call getUserLimits() here — it uses a plain Firestore get()
        // that hangs indefinitely when offline, leaving the button spinning.
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
            errorStr.contains('limit reached') ||
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

                    // Category dropdown
                    Builder(
                      builder: (context) {
                        final existingCategories =
                            (ref.watch(productsProvider).valueOrNull ?? [])
                                .map((p) => p.category)
                                .whereType<String>()
                                .where((c) => c.isNotEmpty)
                                .toSet()
                                .toList()
                              ..sort();
                        // Ensure current value is in the list
                        final currentCat = _selectedCategory;
                        if (currentCat != null &&
                            currentCat.isNotEmpty &&
                            !existingCategories.contains(currentCat)) {
                          existingCategories.add(currentCat);
                        }
                        return DropdownButtonFormField<String>(
                          initialValue:
                              (currentCat != null && currentCat.isNotEmpty)
                              ? currentCat
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: const Icon(Icons.category_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          hint: const Text('Select category'),
                          isExpanded: true,
                          items: [
                            ...existingCategories.map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            ),
                            const DropdownMenuItem<String>(
                              value: '__add_new__',
                              child: Row(
                                children: [
                                  Icon(Icons.add, size: 18),
                                  SizedBox(width: 8),
                                  Text('Add new category'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == '__add_new__') {
                              _showAddCategoryDialog();
                            } else {
                              setState(() => _selectedCategory = value);
                            }
                          },
                        );
                      },
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
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(child: Text('None')),
                              ...DietaryTag.values.map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text('${t.emoji} ${t.displayName}'),
                                ),
                              ),
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
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(child: Text('None')),
                              ...SpiceLevel.values.map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text('${s.emoji} ${s.displayName}'),
                                ),
                              ),
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
                      children:
                          [
                            'Gluten',
                            'Dairy',
                            'Nuts',
                            'Eggs',
                            'Soy',
                            'Shellfish',
                            'Fish',
                            'Sesame',
                          ].map((allergen) {
                            final selected = _allergens.contains(allergen);
                            return FilterChip(
                              label: Text(
                                allergen,
                                style: TextStyle(fontSize: isMobile ? 11 : 13),
                              ),
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

                    // GST & Discount
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'GST (%)',
                            hint: '5',
                            controller: _gstRateController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Discount (%)',
                            hint: '0',
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
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
                                    child: Image.network(
                                      _imageUrl!,
                                      key: ValueKey(_imageUrl),
                                      height: 120,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (_, child, progress) =>
                                          progress == null
                                              ? child
                                              : const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                      errorBuilder: (_, __, ___) => Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.broken_image,
                                            size: 32,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Image unavailable',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            icon: const Icon(
                                              Icons.upload,
                                              size: 14,
                                            ),
                                            label: const Text(
                                              'Re-upload',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            onPressed: () async {
                                              setState(() {
                                                _imageUrl = null;
                                                _isUploadingImage = true;
                                              });
                                              try {
                                                final url = await ImageService
                                                    .pickAndUploadProductImage();
                                                if (url != null &&
                                                    context.mounted) {
                                                  setState(() => _imageUrl = url);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            '✅ Image uploaded',
                                                          ),
                                                          backgroundColor:
                                                              AppColors.success,
                                                        ),
                                                      );
                                                } else {
                                                  setState(
                                                    () => _imageUrl = null,
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Upload failed: ${e.toString().replaceAll('Exception: ', '')}',
                                                          ),
                                                          backgroundColor:
                                                              AppColors.error,
                                                          duration:
                                                              const Duration(
                                                                seconds: 5,
                                                              ),
                                                        ),
                                                      );
                                                }
                                                setState(() => _imageUrl = null);
                                              } finally {
                                                if (mounted) {
                                                  setState(
                                                    () => _isUploadingImage =
                                                        false,
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
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
                                  // url == null means user cancelled — no message needed
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Upload failed: ${e.toString().replaceAll('Exception: ', '')}',
                                        ),
                                        backgroundColor: AppColors.error,
                                        duration: const Duration(seconds: 5),
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
