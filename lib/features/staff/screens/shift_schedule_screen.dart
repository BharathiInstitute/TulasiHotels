/// Shift scheduling screen — weekly calendar view
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/permissions/permission_center.dart';
import 'package:tulasihotels/features/permissions/providers/route_permission_provider.dart';
import 'package:tulasihotels/features/permissions/services/module_mutation_guard.dart';
import 'package:tulasihotels/features/staff/models/permission_config.dart';
import 'package:tulasihotels/features/staff/providers/shift_provider.dart';
import 'package:tulasihotels/features/staff/services/shift_service.dart';
import 'package:tulasihotels/models/shift_model.dart';
import 'package:tulasihotels/models/staff_model.dart';
import 'package:tulasihotels/router/app_router.dart';

class ShiftScheduleScreen extends ConsumerWidget {
  const ShiftScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(todayShiftsProvider);


    return Scaffold(
      appBar: AppBar(title: const Text('Shift Schedule')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showShiftForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Shift'),
      ),
      body: shiftsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (shifts) {
          if (shifts.isEmpty) {
            return const Center(child: Text('No shifts scheduled for today'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: shifts.length,
            itemBuilder: (context, index) {
              final shift = shifts[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(shift.shiftType.emoji),
                  ),
                  title: Text(shift.staffName),
                  subtitle: Text(
                    '${shift.shiftType.displayName} • ${TimeOfDay.fromDateTime(shift.startTime).format(context)} – ${TimeOfDay.fromDateTime(shift.endTime).format(context)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ShiftService.deleteShift(shift.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showShiftForm(BuildContext context, WidgetRef ref) {
    final permissions = ref.read(routePermissionProvider(AppRoutes.staff));
    if (!permissions.isResolved || !permissions.canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            PermissionCenter.deniedActionMessage(
              AppRoutes.staff,
              PermissionAction.create,
            ),
          ),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    var shiftType = ShiftType.morning;

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
                  Text('New Shift',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Staff Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ShiftType>(
                    initialValue: shiftType,
                    decoration: const InputDecoration(
                      labelText: 'Shift Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ShiftType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text('${t.emoji} ${t.displayName}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => shiftType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty) return;
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final shift = ShiftModel(
                        id: generateSafeId('shift'),
                        staffId: '',
                        staffName: nameCtrl.text.trim(),
                        role: StaffRole.waiter,
                        shiftType: shiftType,
                        date: today,
                        startTime: today.add(const Duration(hours: 9)),
                        endTime: today.add(const Duration(hours: 17)),
                        createdAt: now,
                      );
                      try {
                        await ShiftService.createShift(shift);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } on ModulePermissionDenied catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      } on FirebaseException catch (e) {
                        if (!context.mounted) return;
                        final denied =
                            e.code == 'permission-denied' ||
                            (e.message ?? '').toLowerCase().contains(
                              'missing or insufficient permissions',
                            );
                        final message = denied
                            ? PermissionCenter.deniedActionMessage(
                                AppRoutes.staff,
                                PermissionAction.create,
                              )
                            : 'Unable to create shift. Please try again.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    },
                    child: const Text('Create Shift'),
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
