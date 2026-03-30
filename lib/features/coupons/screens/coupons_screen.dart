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
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      coupon.type == CouponType.percentage ? '%' : '₹',
                    ),
                  ),
                  title: Text(coupon.code),
                  subtitle: Text(
                    '${coupon.type == CouponType.percentage ? '${coupon.value}% off' : '₹${coupon.value} off'}'
                    ' • Used ${coupon.usedCount}/${coupon.maxUses ?? '∞'}'
                    '${coupon.isHappyHour ? ' • Happy Hour' : ''}',
                  ),
                  trailing: Switch(
                    value: coupon.isActive,
                    onChanged: (val) =>
                        CouponService.toggleActive(coupon.id, val),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCouponForm(BuildContext context) {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    var type = CouponType.percentage;

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
                  Text('New Coupon',
                      style: Theme.of(context).textTheme.headlineSmall),
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
                      final coupon = CouponModel(
                        id: generateSafeId('coupon'),
                        code: codeCtrl.text.trim().toUpperCase(),
                        type: type,
                        value: double.tryParse(valueCtrl.text) ?? 0,
                        createdAt: DateTime.now(),
                      );
                      CouponService.createCoupon(coupon);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Create Coupon'),
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
