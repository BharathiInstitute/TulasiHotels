/// Reservations management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/reservations/providers/reservation_provider.dart';
import 'package:tulasihotels/features/reservations/services/reservation_service.dart';
import 'package:tulasihotels/models/reservation_model.dart';

class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayReservationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReservationForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Reservation'),
      ),
      body: todayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reservations) {
          if (reservations.isEmpty) {
            return const Center(
              child: Text('No reservations for today'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final res = reservations[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(res.status, theme),
                    child: Text(res.status.emoji),
                  ),
                  title: Text(res.guestName),
                  subtitle: Text(
                    '${res.partySize} guests • ${TimeOfDay.fromDateTime(res.dateTime).format(context)} • ${res.phone}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) =>
                        _handleAction(action, res.id),
                    itemBuilder: (ctx) => [
                      if (res.status == ReservationStatus.pending)
                        const PopupMenuItem(
                          value: 'confirm',
                          child: Text('Confirm'),
                        ),
                      if (res.status == ReservationStatus.confirmed)
                        const PopupMenuItem(
                          value: 'seat',
                          child: Text('Seat Guests'),
                        ),
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text('Cancel'),
                      ),
                      const PopupMenuItem(
                        value: 'noshow',
                        child: Text('No-Show'),
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

  Color _statusColor(ReservationStatus status, ThemeData theme) {
    return switch (status) {
      ReservationStatus.pending => theme.colorScheme.tertiaryContainer,
      ReservationStatus.confirmed => theme.colorScheme.primaryContainer,
      ReservationStatus.seated => theme.colorScheme.secondaryContainer,
      ReservationStatus.cancelled => theme.colorScheme.errorContainer,
      ReservationStatus.noShow => theme.colorScheme.surfaceContainerHighest,
    };
  }

  void _handleAction(String action, String reservationId) {
    switch (action) {
      case 'confirm':
        ReservationService.confirmReservation(reservationId);
        break;
      case 'cancel':
        ReservationService.cancelReservation(reservationId);
        break;
      case 'noshow':
        ReservationService.markNoShow(reservationId);
        break;
    }
  }

  void _showReservationForm(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final partySizeCtrl = TextEditingController(text: '2');
    var selectedDate = DateTime.now();
    var selectedTime = TimeOfDay.now();

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
                  Text('New Reservation',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Guest Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: partySizeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Party Size',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 90)),
                            );
                            if (date != null) {
                              setModalState(() => selectedDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setModalState(() => selectedTime = time);
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                        return;
                      }
                      final dateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      final reservation = ReservationModel(
                        id: generateSafeId('res'),
                        guestName: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        partySize:
                            int.tryParse(partySizeCtrl.text) ?? 2,
                        dateTime: dateTime,
                        createdAt: DateTime.now(),
                      );
                      ReservationService.createReservation(reservation);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Create Reservation'),
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
