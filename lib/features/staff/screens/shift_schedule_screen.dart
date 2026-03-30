/// Shift scheduling screen — weekly calendar view
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/staff/providers/shift_provider.dart';
import 'package:tulasihotels/features/staff/services/shift_service.dart';
import 'package:tulasihotels/models/shift_model.dart';
import 'package:tulasihotels/models/staff_model.dart';

class ShiftScheduleScreen extends ConsumerWidget {
  const ShiftScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(todayShiftsProvider);


    return Scaffold(
      appBar: AppBar(title: const Text('Shift Schedule')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showShiftForm(context),
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

  void _showShiftForm(BuildContext context) {
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
                    onPressed: () {
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
                      ShiftService.createShift(shift);
                      Navigator.of(context).pop();
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
