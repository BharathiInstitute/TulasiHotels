/// Coupons management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/coupons/providers/coupon_provider.dart';
import 'package:tulasihotels/features/coupons/services/coupon_service.dart';
import 'package:tulasihotels/models/coupon_model.dart';

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(allCouponsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Coupons & Discounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCouponForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Coupon'),
      ),
      body: couponsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (coupons) {
          if (coupons.isEmpty) {
            return const Center(child: Text('No coupons yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Text(
                          coupon.type == CouponType.percentage ? '%' : '₹',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coupon.code,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            Text(
                              '${coupon.type == CouponType.percentage ? '${coupon.value}% off' : '₹${coupon.value} off'}'
                              ' • Used ${coupon.usedCount}/${coupon.maxUses ?? '∞'}'
                              '${coupon.isHappyHour ? ' • Happy Hour' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () =>
                            _showCouponForm(context, existing: coupon),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () => _confirmDelete(context, coupon),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CouponModel coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text(
          'Delete "${coupon.code}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await CouponService.deleteCoupon(coupon.id);
    }
  }

  void _showCouponForm(BuildContext context, {CouponModel? existing}) {
    final codeCtrl =
        TextEditingController(text: existing?.code ?? '');
    final valueCtrl =
        TextEditingController(text: existing?.value.toString() ?? '');
    var type = existing?.type ?? CouponType.percentage;
    final isEditing = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditing ? 'Edit Coupon' : 'New Coupon',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Coupon Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Percentage'),
                        selected: type == CouponType.percentage,
                        onSelected: (_) =>
                            setModalState(() => type = CouponType.percentage),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Flat Amount'),
                        selected: type == CouponType.flat,
                        onSelected: (_) =>
                            setModalState(() => type = CouponType.flat),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == CouponType.percentage
                          ? 'Discount %'
                          : 'Discount Amount (₹)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (codeCtrl.text.isEmpty) return;
                      if (isEditing) {
                        final updated = CouponModel(
                          id: existing.id,
                          code: codeCtrl.text.trim().toUpperCase(),
                          type: type,
                          value: double.tryParse(valueCtrl.text) ?? 0,
                          minOrderAmount: existing.minOrderAmount,
                          maxDiscount: existing.maxDiscount,
                          validFrom: existing.validFrom,
                          validUntil: existing.validUntil,
                          maxUses: existing.maxUses,
                          usedCount: existing.usedCount,
                          isActive: existing.isActive,
                          isHappyHour: existing.isHappyHour,
                          happyHourStart: existing.happyHourStart,
                          happyHourEnd: existing.happyHourEnd,
                          createdAt: existing.createdAt,
                        );
                        CouponService.updateCoupon(updated);
                      } else {
                        final coupon = CouponModel(
                          id: generateSafeId('coupon'),
                          code: codeCtrl.text.trim().toUpperCase(),
                          type: type,
                          value: double.tryParse(valueCtrl.text) ?? 0,
                          createdAt: DateTime.now(),
                        );
                        CouponService.createCoupon(coupon);
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text(isEditing ? 'Save Changes' : 'Create Coupon'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
